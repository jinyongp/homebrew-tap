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
```

The workflow generates `Formula/<name>.rb`, audits it, installs it from source,
tests it, and pushes the formula commit.

The lower-level composite action is also available for custom workflows:

```sh
jinyongp/homebrew-tap/actions/publish/formula@v1
```
