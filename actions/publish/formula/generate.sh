#!/usr/bin/env bash
set -euo pipefail

: "${TAP_PATH:?}"
: "${SOURCE_PATH:?}"
: "${FORMULA:?}"
: "${REPOSITORY:?}"
: "${REF:?}"
: "${TEMPLATE_PATH:?}"
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
reject_multiline "template-path" "$TEMPLATE_PATH"

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

case "$TEMPLATE_PATH" in
  /* | *"/../"* | ../* | */.. | "..")
    echo "template-path must stay inside the source repository: $TEMPLATE_PATH" >&2
    exit 1
    ;;
esac

template="${SOURCE_PATH%/}/${TEMPLATE_PATH}"
if [ ! -f "$template" ]; then
  echo "formula template not found: $TEMPLATE_PATH" >&2
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
REF="$REF" \
RESOLVED_REF="$resolved_ref" \
VERSION="$version" \
ARCHIVE_URL="$archive_url" \
SHA256="$checksum" \
SOURCE_PATH="$SOURCE_PATH" \
TEMPLATE="$template" \
ruby <<'RUBY'
require "erb"

def formula_class(name)
  name.gsub("+", "x").gsub("@", " AT ").split(/[^A-Za-z0-9]+/).reject(&:empty?).map { |part| part[0].upcase + part[1..] }.join
end

formula = ENV.fetch("FORMULA")
class_name = formula_class(formula)
repository = ENV.fetch("REPOSITORY")
ref = ENV.fetch("REF")
resolved_ref = ENV.fetch("RESOLVED_REF")
version = ENV.fetch("VERSION")
archive_url = ENV.fetch("ARCHIVE_URL")
sha256 = ENV.fetch("SHA256")
template = ENV.fetch("TEMPLATE")
source_root = File.realpath(ENV.fetch("SOURCE_PATH"))
template = File.realpath(template)
unless template.start_with?(source_root + File::SEPARATOR)
  warn "template-path must stay inside the source repository"
  exit 1
end

content = ERB.new(File.read(template), trim_mode: "-").result(binding)
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
