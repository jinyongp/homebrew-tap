# homebrew-tap

Homebrew tap for jinyongp projects.

## Install

```sh
brew install jinyongp/tap/<formula>
```

## Update

```sh
brew update
brew upgrade <formula>
```

## Release Automation

Projects can update this tap by calling the reusable workflow:

```yaml
jobs:
  homebrew:
    uses: jinyongp/homebrew-tap/.github/workflows/publish-formula.yml@v1
    with:
      formula: <formula>
      source-repository: <owner>/<repo>
      tag: ${{ needs.release_tag.outputs.tag }}
      description: <short description>
      license: <SPDX license>
    secrets:
      token: ${{ secrets.HOMEBREW_TAP_TOKEN }}
      deploy_key: ${{ secrets.HOMEBREW_TAP_DEPLOY_KEY }}
```

The workflow generates `Formula/<name>.rb`, audits it, installs it from source,
tests it, and pushes the formula commit.

Provide exactly one publish credential:

- `token`: fine-grained PAT with `jinyongp/homebrew-tap` Contents read/write.
- `deploy_key`: write deploy key registered on `jinyongp/homebrew-tap`.

Deploy key setup can be done from the CLI for each source repository:

```sh
source_repo=jinyongp/gate
key_path="$(mktemp -u /tmp/homebrew-tap-deploy-key.XXXXXX)"

ssh-keygen -t ed25519 -C "${source_repo} homebrew-tap publisher" -f "$key_path" -N ""

gh repo deploy-key add "${key_path}.pub" \
  --repo jinyongp/homebrew-tap \
  --title "${source_repo} publisher" \
  --allow-write

gh secret set HOMEBREW_TAP_DEPLOY_KEY \
  --repo "$source_repo" \
  < "$key_path"

rm -f "$key_path" "${key_path}.pub"
```

Repeat that setup for each source repository that publishes to this tap. GitHub
deploy keys are repository-scoped, so the same public key cannot be attached to
multiple source repositories.

The lower-level composite action is also available for custom workflows:

```sh
jinyongp/homebrew-tap/actions/publish/formula@v1
```
