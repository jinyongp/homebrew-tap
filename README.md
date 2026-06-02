# homebrew-tap

Homebrew tap for [gate](https://github.com/jinyongp/gate).

## Install

```sh
brew install jinyongp/tap/gate
```

## Update

```sh
brew update
brew upgrade gate
```

## Maintain Formula

The current formula is pinned to a pre-1.0 gate commit because the latest
published tag still uses the old project layout. Update `Formula/gate.rb` when
the `v1.0.0` gate release is published:

1. Change `url` to the `v1.0.0` source archive:

   ```ruby
   url "https://github.com/jinyongp/gate/archive/refs/tags/v1.0.0.tar.gz"
   ```

2. Replace `sha256` with the archive checksum.
3. Remove `version "1.0.0-pre"` from the formula.
4. Run:

   ```sh
   brew audit --strict jinyongp/tap/gate
   brew install --build-from-source jinyongp/tap/gate
   brew test jinyongp/tap/gate
   ```

Before `v1.0.0`, add a root license file to the gate repository and replace
`license :cannot_represent` in the formula with the SPDX license identifier.
