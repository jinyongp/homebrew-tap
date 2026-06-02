#!/usr/bin/env bash
set -euo pipefail

: "${TAP_PATH:?}"
: "${SOURCE_PATH:?}"
: "${FORMULA:?}"
: "${REPOSITORY:?}"
: "${REF:?}"
: "${SPEC_PATH:?}"
: "${GITHUB_OUTPUT:?}"

reject_multiline() {
  case "$2" in
    *$'\n'* | *$'\r'*)
      echo "$1 must be a single-line value" >&2
      exit 1
      ;;
  esac
}

reject_multiline "repository" "$REPOSITORY"
reject_multiline "ref" "$REF"
reject_multiline "version" "${VERSION:-}"
reject_multiline "spec-path" "$SPEC_PATH"

case "$FORMULA" in
  "" | *[!A-Za-z0-9._+@-]*)
    echo "formula may contain only letters, numbers, dot, underscore, plus, at sign, and dash: $FORMULA" >&2
    exit 1
    ;;
esac

case "$REPOSITORY" in
  */*) ;;
  *)
    echo "repository must be owner/name, got: $REPOSITORY" >&2
    exit 1
    ;;
esac

case "$SPEC_PATH" in
  /* | *"/../"* | ../* | */.. | "..")
    echo "spec-path must stay inside the source repository: $SPEC_PATH" >&2
    exit 1
    ;;
esac

spec="${SOURCE_PATH%/}/${SPEC_PATH}"
if [ ! -f "$spec" ]; then
  echo "formula spec not found: $SPEC_PATH" >&2
  exit 1
fi

resolved_ref="$(git -C "$SOURCE_PATH" rev-parse HEAD)"
if [[ ! "$resolved_ref" =~ ^[0-9a-fA-F]{40}$ ]]; then
  echo "could not resolve source checkout to a commit SHA: $resolved_ref" >&2
  exit 1
fi

version="${VERSION:-}"
if [ -z "$version" ]; then
  if [[ "$REF" =~ ^[0-9a-fA-F]{40}$ ]]; then
    version="${REF:0:12}"
  else
    version="$REF"
  fi
fi

archive_url="https://github.com/${REPOSITORY}/archive/${resolved_ref}.tar.gz"
formula_dir="${TAP_PATH%/}/Formula"
formula_path="${formula_dir}/${FORMULA}.rb"

mkdir -p "$formula_dir"

archive="$(mktemp)"
trap 'rm -f "$archive"' EXIT
curl -fsSL "$archive_url" -o "$archive"

if command -v sha256sum >/dev/null 2>&1; then
  checksum="$(sha256sum "$archive" | awk '{print $1}')"
else
  checksum="$(shasum -a 256 "$archive" | awk '{print $1}')"
fi

FORMULA_PATH="$formula_path" \
FORMULA="$FORMULA" \
REPOSITORY="$REPOSITORY" \
VERSION="$version" \
ARCHIVE_URL="$archive_url" \
SHA256="$checksum" \
SOURCE_PATH="$SOURCE_PATH" \
SPEC="$spec" \
ruby <<'RUBY'
require "yaml"

def fail_with(message)
  warn message
  exit 1
end

def formula_class(name)
  name.gsub("+", "x").gsub("@", " AT ").split(/[^A-Za-z0-9]+/).reject(&:empty?).map { |part| part[0].upcase + part[1..] }.join
end

def required_string(spec, key)
  value = spec[key]
  fail_with("#{key} is required") unless value.is_a?(String) && !value.empty?
  value
end

def optional_string(spec, key)
  value = spec[key]
  return nil if value.nil?
  fail_with("#{key} must be a string") unless value.is_a?(String)
  value
end

def indent_snippet(value, spaces)
  value.lines.map { |line| line == "\n" ? line : (" " * spaces) + line }.join
end

def render_license(value)
  case value
  when String
    return ":cannot_represent" if value == "cannot_represent"
    value.dump
  when Hash
    fail_with("license may contain exactly one key") unless value.length == 1
    key, licenses = value.first
    fail_with("license key must be any_of or all_of") unless %w[any_of all_of].include?(key)
    fail_with("license #{key} must be a non-empty string list") unless licenses.is_a?(Array) && licenses.all? { |license| license.is_a?(String) } && !licenses.empty?
    "#{key}: #{licenses.map(&:dump).join(", ").then { |items| "[#{items}]" }}"
  else
    fail_with("license must be a string or any_of/all_of mapping")
  end
end

def string_list(value, path)
  fail_with("#{path} must be a list of strings") unless value.is_a?(Array) && value.all? { |entry| entry.is_a?(String) }
  value
end

def dependency_lines(value)
  return [] if value.nil?
  fail_with("dependencies must be a mapping") unless value.is_a?(Hash)

  allowed = %w[runtime build test recommended optional]
  unknown = value.keys - allowed
  fail_with("unsupported dependency groups: #{unknown.join(", ")}") unless unknown.empty?

  lines = []
  string_list(value["runtime"] || [], "dependencies.runtime").each do |name|
    lines << "  depends_on #{name.dump}"
  end

  {
    "build" => ":build",
    "test" => ":test",
    "recommended" => ":recommended",
    "optional" => ":optional",
  }.each do |group, qualifier|
    string_list(value[group] || [], "dependencies.#{group}").each do |name|
      lines << "  depends_on #{name.dump} => #{qualifier}"
    end
  end
  lines
end

def ensure_known_keys(spec)
  allowed = %w[desc homepage license dependencies install test]
  unknown = spec.keys - allowed
  fail_with("unsupported formula spec keys: #{unknown.join(", ")}") unless unknown.empty?
end

source_root = File.realpath(ENV.fetch("SOURCE_PATH"))
spec_path = File.realpath(ENV.fetch("SPEC"))
unless spec_path.start_with?(source_root + File::SEPARATOR)
  fail_with("spec-path must stay inside the source repository")
end

spec = YAML.safe_load(File.read(spec_path), permitted_classes: [], aliases: false)
fail_with("formula spec must be a mapping") unless spec.is_a?(Hash)
ensure_known_keys(spec)

formula = ENV.fetch("FORMULA")
class_name = formula_class(formula)
desc = required_string(spec, "desc")
homepage = optional_string(spec, "homepage") || "https://github.com/#{ENV.fetch("REPOSITORY")}"
license = spec.fetch("license") { fail_with("license is required") }
install = required_string(spec, "install")
test = required_string(spec, "test")
dependencies = dependency_lines(spec["dependencies"])

content = +"class #{class_name} < Formula\n"
content << "  desc #{desc.dump}\n"
content << "  homepage #{homepage.dump}\n"
content << "  url #{ENV.fetch("ARCHIVE_URL").dump}\n"
content << "  version #{ENV.fetch("VERSION").dump}\n"
content << "  sha256 #{ENV.fetch("SHA256").dump}\n"
content << "  license #{render_license(license)}\n"
content << "\n"

unless dependencies.empty?
  content << dependencies.join("\n")
  content << "\n\n"
end

content << "  def install\n"
content << indent_snippet(install, 4)
content << "\n" unless content.end_with?("\n")
content << "  end\n"
content << "\n"
content << "  test do\n"
content << indent_snippet(test, 4)
content << "\n" unless content.end_with?("\n")
content << "  end\n"
content << "end\n"

File.write(ENV.fetch("FORMULA_PATH"), content)
RUBY

ruby -c "$formula_path" >/dev/null

relative_path="Formula/${FORMULA}.rb"
{
  echo "formula-path=${relative_path}"
  echo "archive-url=${archive_url}"
  echo "sha256=${checksum}"
  echo "resolved-ref=${resolved_ref}"
  echo "version=${version}"
} >> "$GITHUB_OUTPUT"

echo "updated ${relative_path} for ${REPOSITORY}@${resolved_ref}"
