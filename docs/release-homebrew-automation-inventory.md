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


## P0-02 — Current `homebrew-tap` automation surface

### Public and orchestration surface

| Responsibility | Current path(s) | Current contract / side effects | Current evidence | Target owner |
| --- | --- | --- | --- | --- |
| Full Homebrew publish orchestration | `.github/workflows/publish-formula.yml` | `workflow_call`; inputs `formula`, optional `repository`, `ref`, `version`, `spec-path`, `dry-run`, `validation-mode`; optional `token` / `deploy_key`; checks out pinned automation and current tap, generates Formula, uploads/downloads workflow artifact, runs native validation matrix, commits and pushes tap | `test/publishing-base.py`; `.github/workflows/test.yml` jobs `github-release-e2e` and `publish-dry-run` | `homebrew-actions`; split into `check.yml` and `publish.yml` |
| Low-level Formula action | `actions/publish/formula/action.yml`, `actions/publish/formula/generate.sh` | composite action; consumes checked-out source/tap paths, repository/ref/version/spec/mode; writes `Formula/<name>.rb`; resolves source archive or GitHub Release metadata/checksums; outputs formula path, resolved ref/version/distribution/release tag/runner matrix | `test/formula-generator.py`; `.github/workflows/test.yml`; `test/publishing-base.py` | `homebrew-actions` |
| Source input resolution | `.github/workflows/scripts/resolve-source-inputs.sh` | defaults repository/ref to caller context, validates owner/name and requires ref for a different repository; emits repository/ref outputs | negative source-input test in `test.yml`; structural assertions in `publishing-base.py` | `homebrew-actions`; arbitrary source-repository behavior is narrowed by the target public API |
| Formula validation | `.github/workflows/scripts/validate-formula.sh` | copies tap to an isolated temporary Git repo, trusts/taps it, runs `brew audit --strict`; release mode additionally installs from source and runs `brew test`; cleans temporary tap | `publishing-base.py`; reusable workflow matrix/E2E | `homebrew-actions` |
| Validation aggregation | `.github/workflows/scripts/require-formula-validation.sh` | fails stable `homebrew-check` unless generate and validate jobs both succeeded | `publishing-base.py` | `homebrew-actions` |
| Formula commit | `.github/workflows/scripts/commit-formula.sh` | detects Formula path change, commits with GitHub Actions bot identity, emits `changed` | shell syntax coverage; exercised by publish workflow | `homebrew-actions` |
| Tap push convergence | `.github/workflows/scripts/push-formula.sh` | pushes HEAD to tap branch; on failure fetches/rebases and retries a bounded number of times | shell syntax coverage; publishing path uses it | **split required**: `homebrew-actions` owns publisher convergence; `homebrew-tap` keeps a tap-local maintenance push implementation |
| Consumer dependency-update policy | `.github/workflows/auto-merge-homebrew-tap.yml`, `.github/workflows/scripts/authorize-homebrew-tap-update.py`, `.github/workflows/scripts/reconcile-homebrew-tap-policy.sh` | current `pull_request_target` reusable workflow marks policy status, validates Dependabot metadata/commits/files and approved automation SHA, then enables/disables squash auto-merge | `test/publishing-base.py` policy regression cases | `homebrew-actions`; redesigned as read-only PR validation plus trusted `workflow_run` / `update-policy.yml`, not copied verbatim |
| Automation release publishing | `.github/workflows/publish-automation-release.yml` | on automation-path changes to `main`, creates immutable `automation-v1.<run_number>.0` GitHub Release targeting exact workflow commit and re-verifies SHA/immutable flag | `publishing-base.py`; existing `automation-v*` releases | `homebrew-actions` owns its release orchestration; generic release lifecycle may consume `release-actions` once available |
| Deploy-key provisioning | `scripts/setup-deploy-key.sh` | creates write deploy key in tap, stores private key as `HOMEBREW_TAP_DEPLOY_KEY` (or configured name) in source repository, supports safe replacement/cleanup | argument rejection in `test.yml`; shell syntax coverage | `homebrew-actions` operator tooling |

### Tap-local maintenance that must remain

| Responsibility | Current path(s) | Current contract / side effects | Current evidence | Target owner |
| --- | --- | --- | --- | --- |
| Formula deletion workflow | `.github/workflows/delete-formula.yml` | manual dispatch; validates requested Formula, commits deletion, pushes tap unless dry-run | deletion success/invalid-name tests in `test.yml` | `homebrew-tap` |
| Formula deletion implementation | `.github/workflows/scripts/delete-formula.sh` | validates Formula name and dry-run flag, requires existing Formula, performs `git rm` + commit or reports dry-run | `test.yml` | `homebrew-tap` |
| Tap dependency updates | `.github/dependabot.yml` | weekly GitHub Actions dependency updates for workflows remaining in the tap | repository config | `homebrew-tap`; contents may shrink after extraction |
| Tap Formula state | `Formula/**` | published Homebrew Formula state | tap CI / Homebrew usage | `homebrew-tap` |

The Formula deletion workflow currently calls the same `push-formula.sh` used by
publisher writes. That shared file is a concrete extraction dependency: Phase 5 cannot
remove it until tap-local deletion has its own retained push implementation.

### Tests and fixture surface

| Current path | What it covers now | Migration result |
| --- | --- | --- |
| `.github/workflows/test.yml` | mixed publisher + tap-local test workflow: GitHub Release E2E, shell syntax, generator regression, source validation, deploy-key option validation, Formula rendering/audit, delete Formula behavior, publish dry-run | split: publisher checks move to `homebrew-actions`; delete/tap-only checks stay or are rebuilt in `homebrew-tap` |
| `.github/workflows/scripts/add-formula-spec-fixture.sh` | copies source Formula fixture into checked-out source for tests | `homebrew-actions` test support or retire if replaced by external fixture layout |
| `test/formula-generator.py` | local generator unit/regression tests with fake GitHub API/download behavior, source and GitHub Release distributions, invalid release/spec cases | `homebrew-actions` |
| `test/publishing-base.py` | workflow structure, pinned action refs, validation wiring, update-policy authorization/reconciliation, automation release invariants | `homebrew-actions`; tap-local assertions removed/split |
| `test/fixtures/source/.github/homebrew/formula.yml` | rich source-distribution Formula fixture | `homebrew-actions` unit/integration fixture |
| `test/fixtures/e2e/formula.yml` | simple end-to-end Formula fixture used by dry-run workflow | `homebrew-actions` local fixture or external source fixture |
| `formula-fixture-v1.0.0` release/tag and orphan source commit | real immutable GitHub Release assets used by `github-release-e2e` | retire from `homebrew-tap`; replacement E2E lives outside automation tag namespaces |

### Configuration and documentation split

| Current path | Current coupling | Target |
| --- | --- | --- |
| `.github/actionlint.yaml` | suppresses `job.workflow_repository` / `job.workflow_sha` typing warnings specifically for the two reusable workflows | corresponding config moves to `homebrew-actions`; remove from tap if no remaining exception requires it |
| `README.md` | combines tap usage/maintenance, deploy-key setup, Formula spec contract, reusable publishing workflows, update policy, and low-level action docs | tap installation/maintenance remains; publisher/spec/workflow/operator docs move to `homebrew-actions` |
| `.github/dependabot.yml` | updates all GitHub Actions in this repository | remains tap-local and naturally stops tracking removed publisher workflow dependencies |

### P0-02 ownership conclusions

- The reusable publish pipeline, Formula renderer/resolver, validation, tap publish
  convergence, deploy-key provisioning, and dependency-update policy belong to
  `homebrew-actions`.
- Generic GitHub Release lifecycle logic does not become a Homebrew responsibility;
  `homebrew-actions` may later consume `release-actions` for its own product release.
- Formula deletion and tap-state maintenance remain in `homebrew-tap`.
- `push-formula.sh` and `test.yml` are the two explicit mixed-responsibility
  boundaries that must be split before publisher removal.
- Current GitHub Release fixture infrastructure is test-only and must leave the
  `homebrew-tap` tag/release namespace when replacement integration coverage exists.


## P0-03 — Homebrew behavioral baseline

### Baseline revision and environment

Runtime code baseline:

- remote `main`: `472cd536a53c5e3486eef9c1ea592ac23ab4f168`
- local Phase 0 commits before this check modify documentation only, so automation code
  under test is unchanged from that runtime baseline.
- latest observed GitHub Actions `test.yml` run on that revision:
  run `35344003624`, conclusion `success`, created 2026-09-18T12:18:55Z.

Local Loki environment differences:

- `python3 test/publishing-base.py` is runnable locally.
- `python3 test/formula-generator.py` reaches `generate.sh` but the local execution
  environment has no `ruby`; this is an environment/tooling failure, not a product
  assertion failure.
- direct local `bash -n` execution is blocked by the current Loki executable
  allowlist. The same shell-syntax step passed in the referenced GitHub Actions run.

### Baseline checks

| Behavior | Check / evidence | Result | Baseline interpretation |
| --- | --- | --- | --- |
| Publisher structure and policy regression | local `python3 test/publishing-base.py` | pass; output: `Pinned-base conflict reproduced; current-main successive publishing passed` | workflow wiring, policy cases, commit/push scripts, and current-main successive Formula updates are covered by the existing regression |
| Source and GitHub Release Formula generator regression | local `python3 test/formula-generator.py` | blocked locally: `ruby: command not found` | environment gap only; same test step passed in GitHub Actions run 35344003624 |
| Shell syntax for generator, deploy-key tooling, and workflow scripts | local direct run | blocked by Loki executable policy | GitHub Actions run 35344003624 step `Shell syntax` passed |
| Source-distribution Formula generation | `test.yml` fixture generation + `publish-dry-run / generate` | pass in run 35344003624 | current source Formula contract is green |
| GitHub Release distribution generation | `test/formula-generator.py` and `github-release-e2e / generate` | pass in run 35344003624 | release metadata/digest/provenance generation path is green |
| Ref/version normalization | `Generate tag ref version fixture`, `Generate explicit version fixture` and corresponding validation steps | pass in run 35344003624 | tag-style and explicit versions normalize as expected |
| Invalid Formula/spec/source input rejection | invalid spec block plus invalid repository test | pass in run 35344003624 | representative malformed contract cases are rejected |
| Deploy-key option validation | `Reject unknown deploy-key setup options` | pass in run 35344003624 | CLI rejects misspelled/unknown options before any credential mutation |
| Formula syntax/stanza rendering | Ruby syntax and stanza grep checks | pass in run 35344003624 | representative rendered Formula is syntactically valid and includes expected stanzas |
| Strict Homebrew audit | `Audit generated formula` and reusable validation | pass in run 35344003624 | generated Formula passes `brew audit --strict` |
| PR/spec validation mode | `publish-dry-run` reusable workflow | pass; generate, macOS validation, and stable `homebrew-check` succeeded; publish job skipped | read-only check path is green and does not mutate tap |
| Real GitHub Release native install/test | `github-release-e2e` | pass on `macos-arm64`, `macos-x86_64`, `linux-arm64`, `linux-x86_64`; stable `homebrew-check` succeeded | current release-asset Formula installs/tests on every declared native target |
| Formula deletion validation | dry-run deletion + invalid-name rejection in `test` job | pass in run 35344003624 | tap-local deletion validation behavior is green without mutating remote tap |
| Dependency-update authorization | policy cases inside local `publishing-base.py` | pass | approved SHA, full-SHA refs, metadata/files/commits and unrelated mutations are regression-tested |
| Current-main successive Formula writes | temporary bare remote in `publishing-base.py` runs `commit-formula.sh` + `push-formula.sh` for versions 0.2.0 and 0.3.0 | pass locally | write scripts work against an isolated Git remote and preserve successive Formula state |

### Current validation gaps

These are existing coverage gaps, not Phase 0 failures:

1. **Production tap mutation is not run by `test.yml`.**
   Both reusable integration jobs use `dry-run: true`, so the remote
   `homebrew-tap` publish job is intentionally skipped. Phase 0 does not introduce a
   production write merely to close this gap.
2. **Bounded push retry is not deterministically forced by the regression.**
   `publishing-base.py` demonstrates why publishing from a stale pinned base conflicts
   and proves successive writes from current `main`, but it does not inject a
   non-fast-forward between `commit-formula.sh` and the first `git push` so that
   `push-formula.sh` itself must execute its fetch/rebase retry branch.
3. **No-change full publish is not an end-to-end regression.**
   `commit-formula.sh` has an explicit `changed=false` path when the Formula has no
   diff, but the current suite does not exercise a complete reusable publish rerun and
   assert that the remote tap remains untouched.
4. **Local Phase 0 environment cannot reproduce every CI check.**
   Ruby/Homebrew-native checks are established from the successful GitHub Actions
   baseline rather than the local Loki container.

These gaps become explicit Phase 2 validation requirements rather than being treated as
implicitly covered.

### P0-03 conclusions

- The current automation has a green remote CI baseline at runtime revision
  `472cd536...`.
- The real GitHub Release path has native install/test evidence on all four supported
  OS/architecture targets.
- The existing local regression provides deterministic policy and isolated Git write
  evidence.
- Phase 2 must add deterministic coverage for first-push non-fast-forward retry and
  full no-change publish idempotency, and must use a non-production tap fixture for real
  write acceptance.
