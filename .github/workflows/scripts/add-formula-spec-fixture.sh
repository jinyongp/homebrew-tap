#!/usr/bin/env bash
set -euo pipefail

source_path="${SOURCE_PATH:-source}"
fixture_spec="test/fixtures/source/.github/homebrew/formula.yml"
target_dir="${source_path%/}/.github/homebrew"

mkdir -p "$target_dir"
cp "$fixture_spec" "${target_dir}/formula.yml"
