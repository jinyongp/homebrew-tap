# Release / Homebrew Automation Inventory

## Inventory metadata

- Inventory date: 2026-09-19
- Target repository: `jinyongp/homebrew-tap`
- Authoritative plan: `docs/release-homebrew-automation-rearchitecture.md`
- Workstream: `release-homebrew-automation-inventory-4a74ccda46`
- Phase 0 rule: read-only investigation except inventory/plan/validation/task artifacts.

## P0-01 — Repository and consumer inventory

### Search methods

The consumer scan used both local and GitHub evidence:

1. Loki workspace regex search across the available workspace for:
   - `jinyongp/homebrew-tap/.github/workflows/publish-formula.yml`
   - `jinyongp/homebrew-tap/.github/workflows/auto-merge-homebrew-tap.yml`
   - `jinyongp/homebrew-tap/actions/publish/formula`
2. Authenticated `gh search code` for the same exact references across
   `user:jinyongp`.
3. Repository-scoped GitHub code search with `textMatches` for `jinyongp/gate`,
   which is not present as a local checkout in this workspace.

The scan is repeated before final cleanup because GitHub code search can lag indexing
and the available local workspace is not a complete copy of every repository.

### Live external consumers

| Repository | Path | Kind / purpose | Current dependency |
| --- | --- | --- | --- |
| `jinyongp/devtools` | `.github/workflows/release.yml` | reusable workflow; release-time Homebrew publish | `publish-formula.yml@5e298c2d25af8f85e1d95b403cbe59c98b9a0b2d`; no adjacent version comment |
| `jinyongp/devtools` | `.github/workflows/auto-merge-homebrew-tap.yml` | reusable workflow; dependency-update auto-merge policy | `auto-merge-homebrew-tap.yml@5e298c2d25af8f85e1d95b403cbe59c98b9a0b2d`; no adjacent version comment |
| `jinyongp/devtools` | `.github/dependabot.yml` | Dependabot patterns/exclusions for the two reusable workflows | names both reusable workflows |
| `jinyongp/openapi-sdkgen` | `.github/workflows/homebrew.yml` | reusable workflow; PR Homebrew check | `publish-formula.yml@5d4694353a9ed933fe0be9055ca64b7eef53e4f0 # automation-v1.5.0` |
| `jinyongp/openapi-sdkgen` | `.github/workflows/release.yml` | reusable workflow; release-time Homebrew publish | `publish-formula.yml@5d4694353a9ed933fe0be9055ca64b7eef53e4f0 # automation-v1.5.0` |
| `jinyongp/openapi-sdkgen` | `.github/workflows/auto-merge-homebrew-tap.yml` | reusable workflow; dependency-update auto-merge policy | `auto-merge-homebrew-tap.yml@5d4694353a9ed933fe0be9055ca64b7eef53e4f0 # automation-v1.5.0` |
| `jinyongp/openapi-sdkgen` | `.github/dependabot.yml` | Dependabot patterns/exclusions for the two reusable workflows | names both reusable workflows |
| `jinyongp/gate` | `.github/workflows/ci.yml` | reusable workflow; PR Homebrew check | `publish-formula.yml@5d4694353a9ed933fe0be9055ca64b7eef53e4f0 # automation-v1.5.0` |
| `jinyongp/gate` | `.github/workflows/release.yml` | reusable workflow; release-time Homebrew publish | `publish-formula.yml@5d4694353a9ed933fe0be9055ca64b7eef53e4f0 # automation-v1.5.0` |

No live external direct use of
`jinyongp/homebrew-tap/actions/publish/formula` was found.

No `auto-merge-homebrew-tap.yml` reference was found in the current
`jinyongp/gate` code search.

### Additional migration surfaces

These references do not execute `homebrew-tap` automation directly, but they encode
or assert the current dependency and therefore must be migrated with their owning
consumer.

| Repository | Path | Classification | Reason |
| --- | --- | --- | --- |
| `jinyongp/gate` | `internal/devtool/devcmd/scripts.go` | live workflow-generation source | emits the current `publish-formula.yml@5d469...` reference into generated workflows |
| `jinyongp/gate` | `internal/devtool/cirelease/workflow_test.go` | test | asserts generated CI/release workflow references |
| `jinyongp/gate` | `internal/devtool/devcmd/service_test.go` | test | asserts generated workflow text |
| `jinyongp/gate` | `docs/cli-only-distribution-plan.md` | documentation | documents the current Homebrew publish reference |

### Internal, documentation, and temporary references

The following search hits are not external consumers:

| Location | Classification | Notes |
| --- | --- | --- |
| `homebrew-tap/README.md` | documentation | current consumer setup documentation and examples |
| `homebrew-tap/test/publishing-base.py` | internal test | policy/generator regression evidence |
| `homebrew-tap/.github/workflows/scripts/authorize-homebrew-tap-update.py` | internal implementation | allowlist for the existing consumer update policy |
| `homebrew-tap/docs/release-homebrew-automation-rearchitecture.md` | architecture documentation | target-state plan |
| `.tmp/homebrew-tap-inspect/**` | temporary clone | stale inspection copy; not a live repository consumer |

### P0-01 conclusions

- Confirmed live consumer repositories: `devtools`, `openapi-sdkgen`, `gate`.
- `devtools` is pinned to `5e298c2...` without adjacent automation version comments.
- `openapi-sdkgen` and `gate` use `5d469435...` with
  `# automation-v1.5.0` comments on executable workflow references.
- `openapi-sdkgen` and `devtools` have explicit Dependabot grouping for the current
  reusable workflows.
- `gate` additionally owns workflow-generation code/tests that must migrate even
  though those files are not themselves GitHub Actions consumers.
- No external direct consumer of the lower-level composite action was found.
- All search hits from the Phase 0 reference scan are classified above.
