#!/usr/bin/env bash
set -euo pipefail

: "${GITHUB_OUTPUT:?}"
: "${GITHUB_REPOSITORY:?}"
: "${GITHUB_SHA:?}"

repository="${INPUT_REPOSITORY:-$GITHUB_REPOSITORY}"
ref="${INPUT_REF:-$GITHUB_SHA}"

validate_repo() {
  case "$1" in
    */*/* | /* | */ | *".."* | *[!A-Za-z0-9._/-]* | "")
      echo "::error::repository must be owner/name, got: $1"
      exit 1
      ;;
    */*) ;;
    *)
      echo "::error::repository must be owner/name, got: $1"
      exit 1
      ;;
  esac
}

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

validate_repo "$repository"

{
  echo "repository=${repository}"
  echo "ref=${ref}"
} >> "$GITHUB_OUTPUT"
