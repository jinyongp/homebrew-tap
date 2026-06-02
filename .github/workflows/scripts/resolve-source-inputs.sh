#!/usr/bin/env bash
set -euo pipefail

: "${GITHUB_OUTPUT:?}"
: "${GITHUB_REPOSITORY:?}"
: "${GITHUB_SHA:?}"

repository="${INPUT_REPOSITORY:-$GITHUB_REPOSITORY}"
ref="${INPUT_REF:-$GITHUB_SHA}"

if [ -n "${INPUT_REPOSITORY:-}" ] && [ "$INPUT_REPOSITORY" != "$GITHUB_REPOSITORY" ] && [ -z "${INPUT_REF:-}" ]; then
  echo "::error::ref is required when repository differs from the caller repository."
  exit 1
fi

case "${repository}${ref}" in
  *$'\n'* | *$'\r'*)
    echo "::error::repository and ref must be single-line values."
    exit 1
    ;;
esac

{
  echo "repository=${repository}"
  echo "ref=${ref}"
} >> "$GITHUB_OUTPUT"
