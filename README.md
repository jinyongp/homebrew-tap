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
repository provides a Formula spec, and this tap generates the Formula with the
source archive metadata, audits it, installs it from source, tests it, and pushes
the formula commit.

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

### Formula Spec

Add `.github/homebrew/formula.yml` to the publishing repository. The workflow
generates `Formula/<formula>.rb` from that spec.

```yaml
desc: Example tool
homepage: https://github.com/<owner>/<repo>
license: MIT
install: |
  bin.install "bin/example"
test: |
  system "#{bin}/example", "--version"
```

The tap owns Formula structure, source URL, version, SHA-256, class name,
escaping, and field order. The source repository owns only metadata,
dependencies, install/test behavior, and optional Homebrew stanzas.

Supported spec fields:

| Field | Required | Value |
| --- | --- |
| `desc` | Yes | Formula description |
| `homepage` | No | Defaults to `https://github.com/<repository>` |
| `license` | Yes | SPDX string, `cannot_represent`, or `any_of`/`all_of` mapping |
| `options` | No | Option declarations |
| `dependencies.runtime` | No | Runtime dependency names |
| `dependencies.build` | No | Build dependency names |
| `dependencies.test` | No | Test dependency names |
| `dependencies.recommended` | No | Recommended dependency names |
| `dependencies.optional` | No | Optional dependency names |
| `uses_from_macos` | No | macOS-provided dependencies |
| `keg_only` | No | Keg-only reason |
| `conflicts_with` | No | Conflicting formulae |
| `link_overwrite` | No | Link overwrite paths |
| `deprecate` | No | `deprecate!` date/reason mapping |
| `disable` | No | `disable!` date/reason mapping |
| `install` | Yes | Ruby snippet inserted inside `def install` |
| `post_install` | No | Ruby snippet inserted inside `def post_install` |
| `caveats` | No | Ruby snippet inserted inside `def caveats` |
| `service` | No | Ruby snippet inserted inside `service do` |
| `livecheck` | No | Ruby snippet inserted inside `livecheck do` |
| `test` | Yes | Ruby snippet inserted inside `test do` |

Dependency example:

```yaml
dependencies:
  runtime:
    - openssl@3
  build:
    - go
```

Optional stanza example:

```yaml
caveats: |
  "Run `#{bin}/example init` before first use."
service: |
  run opt_bin/"example"
conflicts_with:
  - formula: old-example
    because: both install `example`
uses_from_macos:
  - zlib
```

License mapping example:

```yaml
license:
  any_of:
    - MIT
    - Apache-2.0
```

Workflow inputs:

| Input | Required | Default |
| --- | --- | --- |
| `formula` | Yes | |
| `repository` | No | Caller repository |
| `ref` | No | Caller SHA |
| `version` | No | Short SHA for 40-character refs, otherwise `ref` |
| `spec-path` | No | `.github/homebrew/formula.yml` |
| `dry-run` | No | `false` |

When `repository` is different from the caller repository, `ref` is required.
Tag-style versions are normalized for Homebrew: `refs/tags/v1.2.3`,
`tags/v1.2.3`, `ref: v1.2.3`, and `version: v1.2.3` render as
`version "1.2.3"`.

### Dry Run Check

Add this to the publishing repository's regular check workflow so Formula
spec, audit, install, and test failures are caught before release/tag
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
