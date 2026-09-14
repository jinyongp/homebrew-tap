#!/usr/bin/env bash
set -euo pipefail

: "${AUTHORIZATION_OUTCOME:?AUTHORIZATION_OUTCOME is required}"
: "${GITHUB_OUTPUT:?GITHUB_OUTPUT is required}"
: "${PR_AUTHOR:?PR_AUTHOR is required}"
: "${PR_HEAD_SHA:?PR_HEAD_SHA is required}"
: "${PR_URL:?PR_URL is required}"

if [ "$PR_AUTHOR" != "dependabot[bot]" ]; then
  echo "description=Manual pull request; auto-merge policy not applied" >> "$GITHUB_OUTPUT"
  exit 0
fi

if [ "$AUTHORIZATION_OUTCOME" = "success" ]; then
  gh pr merge --auto --squash --match-head-commit "$PR_HEAD_SHA" "$PR_URL"
  echo "description=Authorized managed homebrew-tap workflow update" >> "$GITHUB_OUTPUT"
  exit 0
fi

auto_merge_enabled="$(
  gh pr view "$PR_URL" --json autoMergeRequest --jq '.autoMergeRequest != null'
)"
if [ "$auto_merge_enabled" = "true" ]; then
  gh pr merge --disable-auto "$PR_URL"
fi
echo "description=Manual review required; auto-merge disabled" >> "$GITHUB_OUTPUT"
