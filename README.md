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

## Delete Formula

Run the `delete formula` workflow manually from GitHub Actions when a formula
should be removed from this tap.

Inputs:

| Input | Required | Default |
| --- | --- | --- |
| `formula` | Yes | |
| `dry-run` | No | `false` |

The workflow deletes `Formula/<formula>.rb`, commits the deletion, and pushes it
to `main`. Existing local installs remain on users' machines, but new installs
and upgrades from this tap stop after users run `brew update`.

## Release Automation

The reusable workflow checks out publishing tools at its own immutable workflow
revision and checks out the Formula destination at current `main`. Callers can
pin the workflow to a commit without freezing the Formula history. Source `ref`
continues to select the package source, independently of these two checkouts.

Projects can update this tap by calling the reusable workflow. The publishing
repository provides a Formula spec, and this tap generates the Formula with the
source archive metadata, audits it, installs it from source, tests it, and pushes
the formula commit.

> [!IMPORTANT]
> For non-dry-run publishing, provide exactly one publish credential: `token`
> or `deploy_key`.

### Credential Options

| Method | Best for | Pros | Cons |
| --- | --- | --- | --- |
| Deploy key | One trusted source repository publishing to this tap | Repository-scoped, no personal account token, easy to rotate per source repository | Write access covers the whole tap repository |
| Fine-grained PAT | One credential publishing many formulas | One secret can publish from multiple source repositories | Tied to a user or bot account, broader blast radius |

### Deploy Key

Use a deploy key when a trusted source repository should publish to this tap.
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
deploy keys are repository-scoped to the tap, not formula-scoped. A workflow
holding this secret can push any formula in this tap, so only install it in
source repositories trusted to publish here.

Rotate an existing deploy key and secret with:

```sh
curl -fsSL https://raw.githubusercontent.com/jinyongp/homebrew-tap/main/scripts/setup-deploy-key.sh | bash -s -- --force
```

When using a custom key title, keep the environment override on the `bash`
process:

```sh
curl -fsSL https://raw.githubusercontent.com/jinyongp/homebrew-tap/main/scripts/setup-deploy-key.sh | KEY_TITLE=formula/<formula> bash -s -- --force
```

Workflow usage:

```yaml
jobs:
  homebrew:
    uses: jinyongp/homebrew-tap/.github/workflows/publish-formula.yml@<homebrew-tap-sha>
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
    uses: jinyongp/homebrew-tap/.github/workflows/publish-formula.yml@<homebrew-tap-sha>
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

The tap owns Formula structure, source or release-asset URLs, version, SHA-256,
platform selection, class name, escaping, and field order. The source repository
owns only metadata, release asset names, dependencies, install/test behavior,
and optional Homebrew stanzas.
The tap does not infer package-specific toolchain or build settings from those
values.

Supported spec fields:

| Field | Required | Value |
| --- | --- | --- |
| `desc` | Yes | Formula description |
| `homepage` | No | Defaults to `https://github.com/<repository>` |
| `license` | Yes | SPDX string, `cannot_represent`, or `any_of`/`all_of` mapping |
| `distribution` | No | Source archive by default, or a GitHub Release asset mapping |
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

#### GitHub Release binaries

Use `distribution.type: github-release` when the publishing repository uploads
prebuilt binaries. The release tag and every asset name may contain the
`{version}` placeholder. The workflow normalizes the Formula version first,
downloads every declared asset from the publishing repository, calculates its
SHA-256 checksum, and renders the selected operating-system branches.

```yaml
desc: Example tool
homepage: https://github.com/<owner>/<repo>
license: MIT
distribution:
  type: github-release
  tag: "v{version}"
  assets:
    macos-arm64: example_{version}_darwin_arm64.tar.gz
    macos-x86_64: example_{version}_darwin_amd64.tar.gz
    linux-arm64: example_{version}_linux_arm64.tar.gz
    linux-x86_64: example_{version}_linux_amd64.tar.gz
install: |
  bin.install "example"
  generate_completions_from_executable(bin/"example", "completion")
test: |
  assert_match version.to_s, shell_output("#{bin}/example --version")
```

The expanded release tag and asset names are simple, URL-safe path segments.
Declare at least one operating system. Each selected operating system requires
both its `arm64` and `x86_64` assets; the other operating system may be omitted.
A single-OS Formula receives `depends_on :macos` or `depends_on :linux`
automatically. Upload the assets to the GitHub Release before calling the
publishing workflow. Source distributions are validated on macOS as before;
GitHub Release distributions are validated on each declared operating system
before the Formula is committed.

Call the reusable workflow after the release job uploads those assets. Pass the
tag name as `version`; `ref` can remain the immutable source commit:

```yaml
jobs:
  homebrew:
    needs: release
    uses: jinyongp/homebrew-tap/.github/workflows/publish-formula.yml@<homebrew-tap-sha>
    with:
      formula: example
      ref: ${{ github.sha }}
      version: ${{ github.ref_name }}
    secrets:
      deploy_key: ${{ secrets.HOMEBREW_TAP_DEPLOY_KEY }}
```

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
GitHub Release distributions should pass the release tag as `version` when
`ref` is an immutable commit SHA.

### Dry Run Check

Add this to the publishing repository's regular check workflow so Formula
spec, audit, install, and test failures are caught before release/tag
publishing:

```yaml
jobs:
  homebrew:
    uses: jinyongp/homebrew-tap/.github/workflows/publish-formula.yml@<homebrew-tap-sha>
    with:
      formula: <formula>
      dry-run: true
```

Dry runs do not require `token` or `deploy_key`, and they skip the formula commit
and push steps. A GitHub Release dry run requires the declared release and all
declared assets to exist already, so run it after uploading the release assets.

### Workflow Updates

Publishing repositories should pin this tap's reusable workflows to the same
full commit SHA. Dependabot then proposes updates to the latest commit on
`homebrew-tap` `main`, while releases continue to use an immutable revision.

Add this dedicated group to `.github/dependabot.yml` in the publishing
repository. Keep other GitHub Actions in a separate group so unrelated updates
cannot enter the automatically merged pull request.

```yaml
version: 2
updates:
  - package-ecosystem: github-actions
    directory: "/"
    schedule:
      interval: weekly
    groups:
      homebrew-tap:
        patterns:
          - jinyongp/homebrew-tap/.github/workflows/publish-formula.yml
          - jinyongp/homebrew-tap/.github/workflows/auto-merge-homebrew-tap.yml
      github-actions:
        patterns:
          - "*"
        exclude-patterns:
          - jinyongp/homebrew-tap/.github/workflows/publish-formula.yml
          - jinyongp/homebrew-tap/.github/workflows/auto-merge-homebrew-tap.yml
```

Add `.github/workflows/auto-merge-homebrew-tap.yml` to the publishing
repository, using the same SHA as the publishing workflow:

```yaml
name: auto-merge homebrew-tap updates

on:
  pull_request_target:

permissions:
  contents: write
  pull-requests: write
  statuses: write

jobs:
  auto-merge:
    uses: jinyongp/homebrew-tap/.github/workflows/auto-merge-homebrew-tap.yml@<homebrew-tap-sha>
```

Enable **Allow auto-merge** and **Allow squash merging** in the publishing
repository. The reusable workflow writes the stable `homebrew-tap/policy`
commit status directly to every pull request head. For an approved Dependabot
update it enables auto-merge for that exact head SHA. For other pull requests
it leaves merging manual, and it disables auto-merge if a Dependabot update no
longer satisfies the policy.

Configure the publishing repository's `main` ruleset to require these checks:

- `homebrew-tap/policy`, from the workflow above.
- The stable `homebrew-check` from a regular `pull_request` dry run of
  `publish-formula.yml` (the full context is normally
  `<caller job> / homebrew-check`).
- Any repository-specific CI checks that must pass before a release workflow
  pin is merged.

Run each workflow once before selecting its check in the ruleset UI. GitHub
only offers recently observed checks. Require the stable `homebrew-check`, not
its platform-specific `validate (...)` matrix jobs, so changing the supported
OS set does not cause ruleset drift. The `pull_request_target` policy workflow
and the regular `pull_request` dry-run workflow must both run for every pull
request targeting the protected branch; a workflow that is skipped entirely
cannot satisfy its required check.

When adopting this setup in an existing publishing repository, manually merge
the first trusted workflow-pin update if it still runs an older revision that
does not emit `homebrew-tap/policy`. Require the two stable checks after the new
revision has run once.

The reusable workflow automatically merges only verified Dependabot pull
requests whose complete dependency list contains only one or both
`homebrew-tap` workflows above. It does not check out or run pull-request code.
Other dependency updates and PRs with maintainer changes remain manual.

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
