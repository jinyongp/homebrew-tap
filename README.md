# homebrew-tap

Homebrew tap containing Formula state and tap-local maintenance for jinyongp packages.

## Install

Install a Formula directly from the tap:

```sh
brew install jinyongp/tap/<formula>
```

The tap currently contains:

- `devtools`
- `gate`
- `openapi-sdkgen`

## Update

Refresh Homebrew metadata and upgrade an installed Formula:

```sh
brew update
brew upgrade <formula>
```

## Repository Scope

This repository owns the checked-in `Formula/*.rb` files and the maintenance
automation required to keep that tap state valid.

CI validates:

- the tap-maintenance regression suite;
- shell syntax for the remaining maintenance scripts;
- Ruby syntax for every checked-in Formula;
- `brew audit --strict` for every checked-in Formula.

Reusable Formula generation, publishing, consumer checks, and dependency-update policy
are maintained separately from this tap repository.

## Delete a Formula

Use the `delete formula` workflow in GitHub Actions when a Formula should be removed
from the tap.

| Input | Required | Default | Description |
| --- | --- | --- | --- |
| `formula` | Yes | | Formula name to delete |
| `dry-run` | No | `false` | Show the planned deletion without committing |

A normal run removes `Formula/<formula>.rb`, commits the deletion, and pushes the
updated tap state to `main`. The maintenance push uses bounded retry with
fetch/rebase when the remote branch advances concurrently.

Existing local installations remain on users' machines. New installs and upgrades from
this tap stop resolving the removed Formula after users refresh Homebrew metadata.
