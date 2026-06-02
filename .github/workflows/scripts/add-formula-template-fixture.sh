#!/usr/bin/env bash
set -euo pipefail

source_path="${SOURCE_PATH:-source}"
fixture_template="test/fixtures/source/.github/homebrew/formula.rb.erb"
target_dir="${source_path%/}/.github/homebrew"

mkdir -p "$target_dir"
cp "$fixture_template" "${target_dir}/formula.rb.erb"
