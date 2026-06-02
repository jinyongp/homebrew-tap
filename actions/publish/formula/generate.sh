#!/usr/bin/env bash
set -euo pipefail

: "${TAP_PATH:?}"
: "${FORMULA:?}"
: "${SOURCE_REPOSITORY:?}"
: "${TAG:?}"
: "${DESCRIPTION:?}"
: "${LICENSE:?}"
: "${GITHUB_OUTPUT:?}"

case "$SOURCE_REPOSITORY" in
  */*) ;;
  *)
    echo "source-repository must be owner/name, got: $SOURCE_REPOSITORY" >&2
    exit 1
    ;;
esac

binary="${BINARY:-$FORMULA}"
main="${MAIN:-./cmd/${FORMULA}}"
homepage="${HOMEPAGE:-https://github.com/${SOURCE_REPOSITORY}}"
archive_url="https://github.com/${SOURCE_REPOSITORY}/archive/refs/tags/${TAG}.tar.gz"
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
DESCRIPTION="$DESCRIPTION" \
HOMEPAGE="$homepage" \
ARCHIVE_URL="$archive_url" \
SHA256="$checksum" \
LICENSE="$LICENSE" \
MAIN="$main" \
BINARY="$binary" \
LDFLAGS="$LDFLAGS" \
TEST_ARGS="$TEST_ARGS" \
TEST_EXPECTED="$TEST_EXPECTED" \
ruby <<'RUBY'
def formula_class(name)
  name.split(/[^A-Za-z0-9]+/).reject(&:empty?).map { |part| part[0].upcase + part[1..] }.join
end

def ruby_string(value)
  '"' + value.to_s.gsub('\\', '\\\\\\').gsub('"', '\"') + '"'
end

formula = ENV.fetch("FORMULA")
binary = ENV.fetch("BINARY")
test_args = ENV.fetch("TEST_ARGS")
test_command = test_args.empty? ? %(\#{bin}/#{binary}) : %(\#{bin}/#{binary} #{test_args})

content = <<~FORMULA
  class #{formula_class(formula)} < Formula
    desc #{ruby_string(ENV.fetch("DESCRIPTION"))}
    homepage #{ruby_string(ENV.fetch("HOMEPAGE"))}
    url #{ruby_string(ENV.fetch("ARCHIVE_URL"))}
    sha256 #{ruby_string(ENV.fetch("SHA256"))}
    license #{ruby_string(ENV.fetch("LICENSE"))}

    depends_on "go" => :build

    def install
      system "go", "build", *std_go_args(
        ldflags: #{ruby_string(ENV.fetch("LDFLAGS"))},
        output:  bin/#{ruby_string(binary)},
      ), #{ruby_string(ENV.fetch("MAIN"))}
    end

    test do
      assert_match #{ruby_string(ENV.fetch("TEST_EXPECTED"))}, shell_output(#{ruby_string(test_command)})
    end
  end
FORMULA

File.write(ENV.fetch("FORMULA_PATH"), content)
RUBY

ruby -c "$formula_path" >/dev/null

relative_path="Formula/${FORMULA}.rb"
{
  echo "formula-path=${relative_path}"
  echo "archive-url=${archive_url}"
  echo "sha256=${checksum}"
} >> "$GITHUB_OUTPUT"

echo "updated ${relative_path} for ${SOURCE_REPOSITORY}@${TAG}"
