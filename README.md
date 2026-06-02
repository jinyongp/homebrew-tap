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

Projects can update this tap by calling the reusable workflow. The publishing
repository provides the Formula template, and this tap renders it with the source
archive metadata, audits it, installs it from source, tests it, and pushes the
formula commit.

> [!IMPORTANT]
> Provide exactly one publish credential: `token` or `deploy_key`.

### Credential Options

| Method | Best for | Pros | Cons |
| --- | --- | --- | --- |
| Deploy key | One source repository publishing one formula | Repository-scoped, no personal account token, easy to rotate per formula | One deploy key per source repository/formula pair |
| Fine-grained PAT | One credential publishing many formulas | One secret can publish from multiple source repositories | Tied to a user or bot account, broader blast radius |

### Deploy Key

Use a deploy key when a source repository should publish only its own formula.
Run this from the source repository that publishes the formula:

```sh
curl -fsSL https://raw.githubusercontent.com/jinyongp/homebrew-tap/main/scripts/setup-deploy-key.sh | bash
```

The script detects the current GitHub repository, creates a `formula/<repo>`
write deploy key on `jinyongp/homebrew-tap`, and stores the private key as
`HOMEBREW_TAP_DEPLOY_KEY` in the source repository's Actions secrets.

If the formula name differs from the source repository name, override the deploy
key title:

```sh
curl -fsSL https://raw.githubusercontent.com/jinyongp/homebrew-tap/main/scripts/setup-deploy-key.sh | KEY_TITLE=formula/<formula> bash
```

Repeat that setup for each source repository that publishes to this tap. GitHub
deploy keys are repository-scoped, so generate one key per formula/source
repository pair.

Rerun the setup script with `--force` to rotate an existing deploy key and
secret.

Workflow usage:

```yaml
jobs:
  homebrew:
    uses: jinyongp/homebrew-tap/.github/workflows/publish-formula.yml@main
    with:
      formula: <formula>
      ref: ${{ github.sha }}
    secrets:
      deploy_key: ${{ secrets.HOMEBREW_TAP_DEPLOY_KEY }}
```

### Fine-Grained PAT

Use a fine-grained personal access token when one credential should publish
multiple formulas.

Token requirements:

| Setting | Value |
| --- | --- |
| Repository access | `jinyongp/homebrew-tap` |
| Repository permissions | Contents: read/write |

Store the token in the source repository:

```sh
gh secret set HOMEBREW_TAP_TOKEN --repo <owner>/<repo>
```

Workflow usage:

```yaml
jobs:
  homebrew:
    uses: jinyongp/homebrew-tap/.github/workflows/publish-formula.yml@main
    with:
      formula: <formula>
      ref: ${{ github.sha }}
    secrets:
      token: ${{ secrets.HOMEBREW_TAP_TOKEN }}
```

### Formula Template

Add `.github/homebrew/formula.rb.erb` to the publishing repository. The workflow
renders that template into `Formula/<formula>.rb` in this tap.

```ruby
class <%= class_name %> < Formula
  desc "Example CLI"
  homepage <%= "https://github.com/#{repository}".dump %>
  url <%= archive_url.dump %>
  version <%= version.dump %>
  sha256 <%= sha256.dump %>
  license "MIT"

  def install
    bin.install "example"
  end

  test do
    system "#{bin}/example", "--version"
  end
end
```

Template variables:

| Variable | Value |
| --- | --- |
| `formula` | Formula name from workflow input |
| `class_name` | Homebrew Formula class name derived from `formula` |
| `repository` | GitHub repository, defaulting to the caller repository |
| `ref` | Requested Git ref, tag, branch, or commit SHA, defaulting to the caller SHA |
| `resolved_ref` | Checked-out source commit SHA used for the source archive |
| `archive_url` | GitHub source archive URL for `repository` and `resolved_ref` |
| `sha256` | SHA-256 checksum of the source archive |
| `version` | Explicit version input, short SHA for 40-character refs, or `ref` |

Workflow inputs:

| Input | Required | Default |
| --- | --- | --- |
| `formula` | Yes | |
| `repository` | No | Caller repository |
| `ref` | No | Caller SHA |
| `version` | No | Short SHA for 40-character refs, otherwise `ref` |
| `template-path` | No | `.github/homebrew/formula.rb.erb` |
| `dry-run` | No | `false` |

When `repository` is different from the caller repository, `ref` is required.

### Dry Run Check

Add this to the publishing repository's regular check workflow so Formula
template, audit, install, and test failures are caught before release/tag
publishing:

```yaml
jobs:
  homebrew:
    uses: jinyongp/homebrew-tap/.github/workflows/publish-formula.yml@main
    with:
      formula: <formula>
      dry-run: true
```

Dry runs do not require `token` or `deploy_key`, and they skip the formula commit
and push steps.

The lower-level composite action is also available for custom workflows:

```yaml
- uses: jinyongp/homebrew-tap/actions/publish/formula@main
  with:
    tap-path: tap
    source-path: source
    formula: <formula>
    repository: <owner>/<repo>
    ref: <ref>
```
