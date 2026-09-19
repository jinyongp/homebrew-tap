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

## P0-04 — Consumer Homebrew contracts

### Contract matrix

| Consumer | Formula / distribution | PR validation | Release-time Homebrew path | Credential / updater | Migration-specific prerequisite |
| --- | --- | --- | --- | --- | --- |
| `devtools` | `formula: devtools`; no `distribution` key, therefore source distribution; Go build from source in Formula | no dedicated Homebrew PR check found | tag-triggered `release.yml`; Homebrew job has `needs: release`, skips prereleases, passes `ref: github.sha` and `version: github.ref_name`; current automation `5e298c2...` without version comment | `HOMEBREW_TAP_DEPLOY_KEY`; Dependabot group for both Homebrew workflows; `pull_request_target` auto-merge wrapper at same old SHA | source distribution does not require GitHub Release assets, so the current `needs: release` edge is orchestration coupling rather than data necessity; migration also needs a new read-only PR check and version-commented new pins |
| `openapi-sdkgen` | `formula: openapi-sdkgen`; no `distribution` key, therefore source distribution; Go build from source in Formula | dedicated `pull_request` workflow; `dry-run: true`, `validation-mode: spec`, `contents: read` | `publish-homebrew` depends only on `validate-release`; passes current repository explicitly, immutable validated commit and tag; GitHub Release and npm publish are separate sibling jobs after the same validation; automation `5d469435... # automation-v1.5.0` | `HOMEBREW_TAP_DEPLOY_KEY`; Dependabot group/exclusion for both workflows; `pull_request_target` auto-merge wrapper with contents/pull-requests/statuses write | remove redundant arbitrary `repository` input under the new caller-is-source contract; preserve existing independent PR check and release-validation outputs; replace update policy |
| `gate` | `formula: gate`; `distribution.type: github-release`; tag template `v{version}`; assets for macOS arm64/x86_64 and Linux arm64/x86_64 | current `.github/workflows/ci.yml` calls `publish-formula.yml@5d469435...` with `dry-run: true` and `validation-mode: spec` | current release workflow calls the same automation SHA with `ref: needs.release_tag.outputs.target`, `version: needs.release_tag.outputs.tag`, and deploy key after its release/build prerequisites | `HOMEBREW_TAP_DEPLOY_KEY`; no current `auto-merge-homebrew-tap.yml` reference found; workflow generator/tests also embed the Homebrew pin | unlike the source consumers, Homebrew publish must remain ordered after the immutable GitHub Release assets it consumes are available; migrate generated workflow source/tests/docs together with executable workflows |

### Current successful paths

#### `devtools`

```text
SemVer tag push
  -> validate tag/main ancestry
  -> macOS + Linux CI
  -> build/package product release artifacts
  -> GitHub Release job
  -> Homebrew reusable workflow (stable versions only)
  -> source Formula generation/validation
  -> homebrew-tap Formula/devtools.rb update
```

The current ordering makes GitHub Release completion a prerequisite even though the
Formula itself uses the source archive/build path.

#### `openapi-sdkgen`

```text
tag push or explicit resume
  -> validate annotated SemVer tag and resolve immutable commit
  -> parallel downstream channels:
       - npm publish
       - Homebrew source Formula publish
       - GitHub Release publish
```

Homebrew and GitHub Release are already separate distribution channels here.

#### `gate`

```text
release tag/build pipeline
  -> publish immutable GitHub Release assets required by Formula distribution
  -> Homebrew workflow with immutable release target + version
  -> resolve four release assets/checksums
  -> native Homebrew validation
  -> homebrew-tap Formula/gate.rb update
```

Gate's generated CI/release workflow source is itself part of the migration surface,
so changing only `.github/workflows/*.yml` would drift the repository's generated
workflow contract.

### Consumer differences that matter to migration

- `devtools` lacks the dedicated read-only Homebrew PR check that the target
  `homebrew-actions/check.yml` contract expects consumers to adopt.
- `openapi-sdkgen` is the closest current model to the target separation: Homebrew
  and GitHub Release are sibling channels after one immutable release validation step.
- `gate` is the only confirmed consumer whose Formula is backed by GitHub Release
  assets, so it is the canary for preserving release-asset provenance/digest/native
  matrix behavior.
- `devtools` uses an older automation SHA and no adjacent automation version comment;
  `openapi-sdkgen` and `gate` are on `automation-v1.5.0`-commented pins.
- Only `devtools` and `openapi-sdkgen` currently have explicit Dependabot grouping
  for the Homebrew workflow dependencies in the evidence collected by P0-01.

### P0-04 conclusions

Every live consumer now has a migration record with Formula type, PR/release usage,
immutable ref/version inputs, tap credential mode, dependency-update behavior, and
consumer-specific migration constraints.


## P0-05 — GitHub Release lifecycle implementations

### Current implementation comparison

| Concern | `devtools` | `openapi-sdkgen` | `gate` | Extraction classification |
| --- | --- | --- | --- | --- |
| Release trigger / orchestration | tag push `v*`; release waits for macOS/Linux CI | tag push or `workflow_dispatch` resume; one validation job fans out to npm/Homebrew/GitHub Release | `repository_dispatch: release`; release tag identity supplied as tag, target SHA, and tag-object SHA | product orchestration; keep local |
| Version/tag validation | SemVer including prerelease; target must be ancestor of `main` | strict SemVer/prerelease validation; tag must be annotated and target merged into `main` | strict stable `vX.Y.Z`; verifies local/remote tag object and target identity, highest stable tag, event/dispatch identity, and `main` ancestry | common provenance primitives are shareable; exact version/prerelease/highest-tag policy remains caller/product policy |
| Artifact build | product-specific `just release` matrix plus skill/install/LICENSE/version files | GoReleaser plus npm packaging in separate channel | `gate-dev ci build-release-artifacts` creates four native binaries | product build/package logic; remain local |
| Release creation | `gh release create "$TAG" dist/* --verify-tag --generate-notes`; prerelease flag when needed | GoReleaser creates release when validated existing complete release is not reusable | `gate-dev ci publish-release` runs `gh release create` with caller-built assets, explicit notes, `--verify-tag` | generic create/upload/publish primitive is a `release-actions` candidate |
| Existing-release handling | no explicit resume/no-op path; duplicate creation relies on command failure | queries existing release; recognizes a complete required asset set; otherwise follows creation path | if release exists, requires published/non-draft/non-prerelease/immutable state and then verifies exact asset set/content; matching release is a no-op | inspect/verify/idempotent no-op is shared `release-actions` responsibility; product-specific required asset list is caller input |
| Asset integrity | packaging-specific local checks before release | verifies required asset list and compares `checksums.txt` values with GitHub asset SHA-256 digests for a reusable existing release | downloads each existing release asset and byte-compares it with the caller-built local file; rejects missing or unexpected assets | shared exact-asset/digest/content verification primitive; artifact naming remains caller data |
| Immutable release verification | no explicit post-create immutable check in workflow | current visible workflow validates existing release completeness/digests; immutable-state enforcement is not centralized in the workflow code inspected | existing release must be immutable; newly created release state is read back and must be published, stable, immutable | immutable postcondition belongs in `release-actions` |
| Release notes | GitHub-generated notes | GoReleaser-managed | annotated tag body when available, otherwise commit bullets since latest published release | caller-supplied/generated-note strategy is product policy; shared action may accept notes or a generic generation mode but must not embed one product's changelog policy |
| Rerun model | no explicit release-resume input; rerunning an already-created release is not intentionally idempotent | explicit `workflow_dispatch` resume exists and attempts to reuse a complete existing release | matching existing immutable release is intentionally verified/no-op | reusable idempotent lifecycle behavior is a `release-actions` target; workflow-level resume trigger stays local |
| GitHub permissions | release job `contents: write` | GitHub Release job `contents: write` | build/publish job `contents: write`; initial detection/preflight remain read-only | caller declares permissions; action must not widen them |

### Gate lifecycle evidence

A read-only depth-1 clone of current `jinyongp/gate` was inspected under the
workspace temporary directory after GitHub code-search rate limiting prevented further
search API reads. The clone is investigation-only and is not a migration target.

At the inspected Gate revision:

- `internal/devtool/cirelease/publish.go` validates the strict release tag and exact
  expected target/tag-object identity before release mutation.
- If a release already exists, it must be published, non-prerelease, and immutable.
  The implementation then requires the exact expected asset set and downloads every
  asset to byte-compare against the newly built local artifact.
- If the release does not exist, the implementation creates it with caller-built assets
  and then reads the release state back to require the immutable published postcondition.
- `internal/devtool/cirelease/git.go` rejects moved tag object/target identity and
  older stable tags, and records whether the target is merged into `main`.
- `.github/workflows/release.yml` keeps preflight/build orchestration and artifact
  construction inside Gate, then calls the release primitive before the Homebrew job.
  The Homebrew job depends on the build job, which includes release publication.

### Initial `release-actions` extraction boundary

The evidence supports a narrow shared product centered on GitHub Release lifecycle
state, not product release orchestration.

Shared candidates:

1. validate caller-provided tag/commit provenance against the remote tag;
2. inspect current GitHub Release state;
3. create/upload/publish from caller-produced artifact paths when no valid release
   exists;
4. verify the final published/immutable postcondition;
5. verify the expected asset set and asset integrity;
6. treat an already-published matching immutable release as an idempotent no-op;
7. reject mismatched published state rather than replacing tagged artifacts.

Remain product-owned:

- deciding when a release should run;
- version bump and tag creation;
- SemVer/prerelease/stable-only policy beyond generic input validation;
- determining whether the tag must be annotated or be the newest stable tag;
- build/test matrices and product packaging;
- artifact names and required artifact list;
- GoReleaser configuration, npm publication, skill packaging, installers, checksums file
  format, and other package-channel logic;
- release-note/changelog policy;
- Homebrew ordering based on the product's selected Formula distribution.

### P0-05 conclusions

- There is enough real duplicated lifecycle behavior to justify a root
  `release-actions` action, but the shared API must stay narrower than any one
  product's release workflow.
- Gate provides the strongest existing idempotency and immutable-artifact behavior and
  should be treated as preservation evidence, not copied wholesale as the shared API.
- `devtools` currently lacks intentional existing-release idempotency; migrating it to
  the shared action will strengthen rerun behavior.
- `openapi-sdkgen` already has a resume path and existing-release verification, but
  product-specific GoReleaser/checksum behavior must remain outside the shared action.
- No product build command is a `release-actions` responsibility.


## P0-06 — Permissions, credentials, and trust boundaries

This inventory records credential names and authority only. No secret value was read,
printed, or copied.

### Current write-authority map

| Operation | Current code / caller | Credential or token name | Declared permission / authority | Repository target | Target-state owner |
| --- | --- | --- | --- | --- | --- |
| Homebrew PR/spec check | consumer `pull_request` -> `publish-formula.yml` dry-run/spec | caller `GITHUB_TOKEN`; no tap secret | `contents: read` in observed PR-check consumers; called workflow also restricts contents to read | caller source + public automation/tap reads | `homebrew-actions/check.yml`; read-only |
| Formula publish with deploy key | `publish-formula.yml` publish job | reusable secret `deploy_key`; live consumers pass `HOMEBREW_TAP_DEPLOY_KEY` | SSH deploy key has write access to `jinyongp/homebrew-tap`; caller token remains read-only for source/automation reads | `homebrew-tap` | `homebrew-actions/publish.yml` |
| Formula publish with token alternative | `publish-formula.yml` public contract | reusable secret `token`; docs name `HOMEBREW_TAP_TOKEN` | token/PAT must provide tap contents write | `homebrew-tap` | `homebrew-actions/publish.yml`; supported alternative, not observed in current live consumers |
| Tap Formula deletion | `delete-formula.yml` | repository `GITHUB_TOKEN` | job `contents: write` | `homebrew-tap` | `homebrew-tap` |
| Automation release creation | `publish-automation-release.yml` | `github.token` as `GH_TOKEN` | workflow `contents: write` | `homebrew-tap` GitHub Releases | replaced by new automation product release process; no longer tap responsibility |
| Dependency policy pending/final status | `auto-merge-homebrew-tap.yml` policy-start/report | caller `github.token` | `statuses: write` | consumer repository PR head SHA | `homebrew-actions/update-policy.yml` via trusted follow-up |
| Dependency-update evidence read | `auto-merge-homebrew-tap.yml` authorize | caller `github.token` plus Dependabot metadata action | `contents: read`, `pull-requests: read` | consumer repository; public `homebrew-tap` release metadata | `homebrew-actions/update-policy.yml` |
| Enable/disable consumer auto-merge | `auto-merge-homebrew-tap.yml` reconcile | caller `github.token` | `contents: write`, `pull-requests: write` | consumer repository PR | `homebrew-actions/update-policy.yml` via trusted `workflow_run` wrapper |
| Product GitHub Release | product-specific release job | repository `GITHUB_TOKEN` / `github.token` | release jobs use `contents: write` | each product repository | product repository invoking `release-actions` |
| Deploy-key provisioning | `scripts/setup-deploy-key.sh` operator command | user's authenticated `gh` session; generated private deploy key is passed directly to `gh secret set` | authenticated operator must administer source and tap; creates write deploy key in tap and Actions secret in source | tap deploy keys + source repo Actions secret | operator tooling moved to `homebrew-actions` |

### Live consumer permission differences

#### `devtools`

- top-level release workflow permission is `contents: read`; only its GitHub Release job
  elevates to `contents: write`.
- Homebrew publish receives `HOMEBREW_TAP_DEPLOY_KEY`; no Homebrew-specific caller
  token write permission is declared.
- current `pull_request_target` auto-merge wrapper declares
  `contents: write` and `pull-requests: write`; it is pinned to the older automation
  revision and does not declare the later stable policy status permission.

#### `openapi-sdkgen`

- PR Homebrew check declares `contents: read`.
- release validation and Homebrew publish declare `contents: read`; the tap write is
  delegated solely through `HOMEBREW_TAP_DEPLOY_KEY`.
- the independent GitHub Release job declares `contents: write` and uses its own
  repository `GITHUB_TOKEN`.
- current `pull_request_target` wrapper declares `contents: write`,
  `pull-requests: write`, and `statuses: write`.

#### `gate`

- CI is a normal `pull_request` workflow with `contents: read`; its Homebrew spec
  check has no tap write credential.
- release workflow defaults to `contents: read`; only the product build/release job
  uses `contents: write`.
- Homebrew publish receives `HOMEBREW_TAP_DEPLOY_KEY` after the release-producing
  build job succeeds.
- no current Homebrew auto-merge wrapper was found in P0-01.

### Reusable-workflow credential behavior

The existing Homebrew reusable workflow has two distinct identities:

1. **caller/source identity** — the reusable workflow executes in the consumer's event
   context and receives the caller's `github.token` permissions;
2. **tap write identity** — actual Formula pushes use the explicit `token` or
   `deploy_key` secret selected by the publish job.

The workflow also checks out its implementation from
`job.workflow_repository@job.workflow_sha`. This avoids executing a newer
`homebrew-tap/main` implementation than the caller's pinned reusable-workflow SHA.

The target `homebrew-actions` contracts preserve this separation:

- `check.yml`: caller source read + pinned automation read only; no tap secret;
- `publish.yml`: caller source read plus exactly one explicit tap-write credential;
- `update-policy.yml`: consumer-repository metadata/merge authority only; no tap
  credential and no source-build execution.

### Current untrusted-PR boundary

The existing consumer wrappers use `pull_request_target`, which gives the workflow a
trusted base-repository execution context and write-capable token according to caller
permissions.

The current reusable policy reduces risk in several ways:

- it checks out only the pinned policy automation revision from
  `job.workflow_repository@job.workflow_sha`;
- it does not checkout the pull-request head;
- it retrieves PR commits/files/workflow contents through the GitHub API and treats them
  as evidence;
- it authorizes only Dependabot-authored, verified, dependency-only workflow-ref
  updates;
- reconcile enables/disables auto-merge only after authorization.

Even with those guards, the write-capable decision is attached directly to
`pull_request_target`. The target design moves privilege separation to:

```text
pull_request
  -> read-only Homebrew/dependency validation
  -> workflow_run on trusted base workflow
  -> pinned update-policy.yml
  -> API-only revalidation of PR evidence
  -> enable/disable auto-merge
```

The privileged `workflow_run` path must not checkout the PR head, run PR-provided
scripts, restore PR-produced caches, or execute PR-produced artifacts.

### Credential migration destinations

| Current name / authority | Migration |
| --- | --- |
| `HOMEBREW_TAP_DEPLOY_KEY` | remains consumer-owned secret and is passed as `tap_deploy_key` to `homebrew-actions/publish.yml` |
| `HOMEBREW_TAP_TOKEN` / reusable `token` alternative | remains optional tap-write alternative, renamed/exposed as the new publish contract's tap token input if retained |
| consumer `GITHUB_TOKEN` for read-only check | remains caller token with explicit `contents: read` |
| consumer `GITHUB_TOKEN` for auto-merge/status | moves from `pull_request_target` wrapper to trusted `workflow_run` wrapper with only the permissions needed by update policy |
| product release `GITHUB_TOKEN` | remains product-owned; `release-actions` uses caller-declared `contents: write` rather than a Homebrew credential |
| operator `gh` login used by deploy-key setup | remains an operator prerequisite; no credential value is stored in the automation repository |

### P0-06 conclusions

- Every current repository-write operation has an identified credential and target.
- Homebrew source validation and tap mutation already use separable authorities; the
  extraction should preserve that property rather than introduce a broad shared token.
- All live consumers currently use the deploy-key path for tap writes.
- The only privileged untrusted-PR boundary that must be structurally redesigned is the
  consumer dependency-update auto-merge path.
- No new privilege is required for the planned `workflow_run` split: it reuses the
  consumer repository's pull-request/status write authority while keeping tap
  credentials out of that path.


## P0-07 — Release/tag and dependency-updater baseline

### Current `homebrew-tap` tag families

| Tag | Commit |
| --- | --- |
| `automation-v1.1.0` | `115c331a731f71ac0269bb21ab222f1de425aa17` |
| `automation-v1.2.0` | `7f734abd81f23640d9a25c07206057c560e9301e` |
| `automation-v1.3.0` | `daea2d83b5b032f449a4998807d4949f9d9b480d` |
| `automation-v1.4.0` | `dfe0050e6e8a3f6848c556ac9790ce34976cc64f` |
| `automation-v1.5.0` | `5d4694353a9ed933fe0be9055ca64b7eef53e4f0` |
| `formula-fixture-v1.0.0` | `a19bd5ad89bad940c642c0e9183c00c35f65e611` |

A Git version sort places `formula-fixture-v1.0.0` ahead of the
`automation-v*` family:

```text
formula-fixture-v1.0.0
automation-v1.5.0
automation-v1.4.0
automation-v1.3.0
automation-v1.2.0
automation-v1.1.0
```

The fixture tag points at a parentless test commit whose tree contains no
`.github/workflows` files.

### Bad candidate path evidence

Candidate selected in the reproduced updater failure:

```text
formula-fixture-v1.0.0
a19bd5ad89bad940c642c0e9183c00c35f65e611
```

At that commit:

```text
.github/workflows/auto-merge-homebrew-tap.yml  -> absent
.github/workflows/publish-formula.yml          -> absent
```

The commit itself is an orphan fixture commit:

```text
a19bd5ad89bad940c642c0e9183c00c35f65e611
parents: none
subject: test: add immutable formula release fixture
```

### Valid control revisions

Both workflow paths exist at the historical consumer revision:

```text
5e298c2d25af8f85e1d95b403cbe59c98b9a0b2d
  .github/workflows/auto-merge-homebrew-tap.yml
  .github/workflows/publish-formula.yml
```

and at the latest automation release revision:

```text
5d4694353a9ed933fe0be9055ca64b7eef53e4f0  # automation-v1.5.0
  .github/workflows/auto-merge-homebrew-tap.yml
  .github/workflows/publish-formula.yml
```

This proves the breakage is not a missing-path condition in the intended automation
family; it is selection of an unrelated repository tag family.

### `actions-up` reproduction

Observed tool:

```text
actions-up/1.20.0
```

On the current `devtools` checkout, which pins `5e298c2...` without adjacent
automation version comments:

```text
actions-up --dry-run --json
```

returns two updates:

| Consumer path | Dependency | Detected latest version | Target SHA |
| --- | --- | --- | --- |
| `.github/workflows/auto-merge-homebrew-tap.yml` | `jinyongp/homebrew-tap/.github/workflows/auto-merge-homebrew-tap.yml` | `formula-fixture-v1.0.0` | `a19bd5ad89bad940c642c0e9183c00c35f65e611` |
| `.github/workflows/release.yml` | `jinyongp/homebrew-tap/.github/workflows/publish-formula.yml` | `formula-fixture-v1.0.0` | `a19bd5ad89bad940c642c0e9183c00c35f65e611` |

The command reports `status: updates-available` and `totalUpdates: 2`.

On `openapi-sdkgen`, whose executable Homebrew workflow references include the
adjacent `# automation-v1.5.0` family comment, the same
`actions-up --dry-run --json` reports:

```text
status: up-to-date
totalUpdates: 0
```

This is the control case showing that current `actions-up` can preserve the intended
tag family when the SHA pin carries family metadata, while an unannotated SHA pin
remains vulnerable to the mixed repository tag namespace.

Both commands were dry-run/report-only. Existing unrelated worktree changes in the
consumer repositories were not touched or staged.

### Current dependency-updater configuration

- `devtools` and `openapi-sdkgen` explicitly group the two
  `homebrew-tap` reusable workflows in Dependabot and exclude them from the generic
  GitHub Actions group.
- `devtools` executable refs lack adjacent automation-family comments.
- `openapi-sdkgen` executable refs use `# automation-v1.5.0`.
- Gate's current executable refs also use `# automation-v1.5.0`; P0-01 found no
  current Homebrew auto-merge wrapper in Gate.

### Post-migration regression target

The final regression is structural rather than updater-specific:

1. `homebrew-actions` exposes exactly its own `vX.Y.Z` release family;
2. consumer executable refs use full commit SHAs with adjacent release comments;
3. any updater-selected candidate SHA must contain the referenced
   `.github/workflows/<contract>.yml` path;
4. `release-actions` has its own independent single-product `vX.Y.Z` namespace;
5. `homebrew-tap` is no longer an external Actions dependency provider, so its
   historical tags cannot participate in Homebrew automation dependency resolution.

### P0-07 conclusions

- The original issue is reproduced with the currently installed `actions-up 1.20.0`.
- The exact bad SHA and missing workflow paths are independently proven from Git.
- A correct automation release SHA contains both reusable workflow paths.
- Version-family comments mitigate the current updater behavior but are not the
  architectural fix; moving reusable workflows to a single-product automation
  repository removes the mixed tag namespace from dependency resolution.


## P0-08 — Operational failure, retry, and rollback behavior

### Recovery matrix

| Operation / failure | Current behavior | Classification | Recovery / rollback contract to preserve |
| --- | --- | --- | --- |
| Formula generation or spec validation fails | generating job exits non-zero; stable `homebrew-check` fails unless both generate and validate succeeded; publish cannot proceed | safe failure; retryable after source/spec fix | no tap mutation occurs before successful generation/validation |
| Native Homebrew audit/install/test fails | validation matrix job fails and stable `homebrew-check` fails | safe failure; retryable | Formula must never be committed when any required validation target fails |
| Formula output is unchanged | `commit-formula.sh` emits `changed=false` and exits without commit; publish workflow skips push | idempotent no-op | same product revision/version may be retried without creating an empty commit |
| Tap push races another update | `push-formula.sh` attempts push, then fetches and rebases `origin/<branch>` before retry; default bound is three attempts | retryable optimistic concurrency | preserve unrelated remote Formula commits; fail after bounded retries instead of force-pushing or overwriting |
| Rebase conflicts during tap push | shell exits due `set -e`; workflow fails | safe failure requiring intervention/retry | no force push; regenerated/retried publish must start from current tap state |
| Tap credential is missing/ambiguous | publish job rejects no credential and rejects both token + deploy key | safe configuration failure | caller fixes secret configuration; no repository mutation |
| Existing automation release tag/release matches exact SHA and is immutable | `publish-automation-release.yml` exits successfully without recreating release | idempotent no-op | new automation products must preserve exact-revision no-op behavior |
| Existing automation release name points elsewhere or is not immutable | automation release workflow fails | safe failure | do not retarget or replace published version identity |
| Product release already exists and matches | behavior differs by product: Gate verifies exact immutable state/assets then no-ops; openapi-sdkgen has resume/reuse path; devtools lacks explicit no-op | partially idempotent today | `release-actions` must standardize matching-published-release no-op and mismatch rejection |
| Existing product release differs | Gate rejects mismatched immutable assets/state; openapi verifies required existing asset checksums; devtools command failure is the current guard | destructive replacement is prohibited | shared action must refuse replacement of a published immutable release |
| Dependency-update authorization fails | authorize step outcome becomes failure; reconcile disables existing auto-merge and records manual-review description | safe fail-closed behavior | target `workflow_run` policy must remain fail-closed and remove stale auto-merge |
| Authorized auto-merge command fails | reconcile attempts to disable auto-merge, then exits non-zero | safe failure | do not leave an unverified automatic merge armed after reconciliation failure |
| Policy initialization/reporting fails | final status reports policy failure when possible | observable failure | target policy must produce a stable required-check result or equivalent merge gate |
| Formula delete input is invalid/missing | deletion script exits before Git mutation | safe failure | preserve strict name validation and existing-Formula requirement |
| Formula deletion dry-run | reports target and `changed=true` but does not remove/commit | non-destructive preview | preserve operator preview path |
| Formula deletion succeeds locally but push races | deletion currently reuses bounded `push-formula.sh` behavior | retryable with shared implementation today | after extraction, tap-local deletion needs equivalent non-force convergence behavior |
| Consumer automation migration is bad | consumer references are full SHAs; old automation releases remain available | reversible per consumer | revert the consumer workflow pin to the last known-good SHA; do not rewrite product tags/releases |
| New automation extraction fails before consumer cutover | current `homebrew-tap` workflows/releases stay intact through Phases 1–4 | additive/reversible migration | do not remove old tap-hosted automation until all consumers pass acceptance |
| Historical product GitHub Release exists | Phase 0/architecture does not rewrite product tags or releases | immutable historical state | migration must adapt automation around existing release history, not rewrite it |

### Concurrency and idempotency guarantees

The migration must preserve these concrete guarantees:

1. **validation before mutation** — Formula rendering/audit/install/test completes before
   tap commit/push;
2. **no-force tap convergence** — concurrent source repositories cannot solve races by
   overwriting tap history;
3. **bounded retries** — network/non-fast-forward retries terminate with an explicit
   failure instead of looping indefinitely;
4. **same-input no-op** — an unchanged Formula produces no commit/push;
5. **immutable release identity** — an existing published release is reused only when it
   represents the requested tag/commit/assets; mismatch fails rather than mutating it;
6. **fail-closed dependency updates** — failed authorization or reconciliation never
   leaves a newly authorized automatic merge;
7. **per-consumer rollback** — a consumer can return to its prior full automation SHA
   while old contracts are retained during migration.

### Known operational gaps to close later

- Existing tests do not deterministically force the first `git push` to fail and then
  prove the retry/rebase branch succeeds. Phase 2 needs this regression.
- Existing tests do not exercise a complete no-change remote publish rerun. Phase 2
  needs a non-production tap fixture acceptance case.
- `devtools` release publication does not currently provide an intentional matching
  existing-release no-op; Phase 1 should improve this via `release-actions`.
- The current consumer auto-merge policy is fail-closed but attached to
  `pull_request_target`; Phase 2 must preserve the behavior while moving privilege to
  the trusted `workflow_run` path.

### Destructive actions blocked until later phases

Phase 0 confirms the following remain blocked until replacement contracts are accepted:

- deleting or rewriting existing `automation-v*` releases/tags;
- deleting the fixture release/tag solely to hide the updater symptom;
- removing tap-hosted reusable workflows/actions/scripts;
- rotating/removing consumer tap credentials;
- changing repository rulesets or merge settings;
- force-pushing tap history;
- rewriting published product tags or GitHub Releases.

### P0-08 conclusions

- Every migration-critical failure mode has a current recovery path or an explicit
  coverage gap.
- Tap writes are recoverable through retry/rebase and consumer pin rollback without
  rewriting product release history.
- Immutable release mismatch and dependency-policy failure are intentionally
  fail-closed and must remain so.
- The migration can remain additive through consumer cutover; irreversible cleanup is
  not required to prove the new architecture.


## P0-09 — Responsibility and migration matrix

The following matrix is the canonical Phase 0 ownership map. Each primary
responsibility has one target owner or an explicit retirement outcome.

| Primary responsibility | Current owner / path | Target owner | Target contract | Migration phase | Baseline / permission impact | Consumer impact | Removal prerequisite |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Product release trigger, version/tag policy, build/test/package orchestration | each product repository release workflow and tooling | product repository | local workflow/tooling | Phase 3/4 consumer migration | preserve each product's existing release validation/build evidence; product release jobs retain caller-declared permissions | local workflow refactor only | shared lifecycle action proven against that product |
| Shared GitHub Release state/provenance/create/verify/idempotency primitives | duplicated in devtools workflow, openapi workflow, Gate `internal/devtool/cirelease` | `release-actions` | root `jinyongp/release-actions@<full-sha>` | Phase 1 | caller release job grants `contents: write`; matching release no-op / mismatch reject | consumers replace shared inline lifecycle logic, not product builds | Phase 1 external fixture acceptance + immutable release |
| Product-specific GitHub Release notes, artifact list, GoReleaser/package-channel behavior | product repositories | product repository | inputs/local orchestration around `release-actions` | Phase 3/4 | preserve current product-specific tests | none beyond local migration | never removed from product unless separately generalized |
| Homebrew Formula metadata and product install/test intent | each consumer `.github/homebrew/formula.yml` | product repository | declarative Formula spec | unchanged / Phase 3/4 contract migration | existing spec/generator baseline | source repo continues to own package intent | none |
| PR/spec Homebrew orchestration | `homebrew-tap/.github/workflows/publish-formula.yml` dry-run/spec mode | `homebrew-actions` | `.github/workflows/check.yml@<full-sha>` | Phase 2 then 3/4 | caller `contents: read`; no tap secret | devtools adds missing dedicated check; openapi/Gate migrate existing checks | new check workflow passes without write credential |
| Release-time Homebrew orchestration | same reusable `publish-formula.yml` | `homebrew-actions` | `.github/workflows/publish.yml@<full-sha>` | Phase 2 then 3/4 | full generator/native validation baseline; exactly one tap-write credential | all consumers change reusable-workflow dependency | non-production tap fixture publish + rerun acceptance |
| Formula parser/renderer and output matrix | `actions/publish/formula/action.yml`, `generate.sh` | `homebrew-actions` | internal action/implementation called by check/publish workflows; optional low-level public action only if retained deliberately | Phase 2 | `formula-generator.py`, remote generator CI, native E2E | no direct live external action consumer found | equivalent regression coverage passes |
| Caller source/ref/version resolution | `resolve-source-inputs.sh` + reusable workflow inputs | `homebrew-actions` | caller-is-source contract; check uses event revision, publish requires full source SHA + explicit version | Phase 2 | current invalid-input tests inform narrowed contract | openapi drops redundant repository input; others align | new public inputs validated in contract tests |
| Source archive / GitHub Release distribution resolution, checksums and provenance | `generate.sh` | `homebrew-actions` | Formula distribution resolver | Phase 2 | source and release generator tests; four-target Gate/fixture behavior | only Gate requires release-assets ordering | source + release fixture acceptance |
| Formula audit/install/test implementation | `validate-formula.sh` and reusable validation matrix | `homebrew-actions` | internal validation jobs behind check/publish | Phase 2 | strict audit + native runner baseline; caller read permissions | stable check name/contract must be migrated in rulesets later without gap | check/publish integration green |
| Stable Homebrew check aggregation | `require-formula-validation.sh`, `homebrew-check` job | `homebrew-actions` | stable check result from `check.yml` / `publish.yml` | Phase 2/3/4 | preserve fail-closed generate+validate result | consumer required-check context may change and must be observed before ruleset edits | new check run observed in each consumer |
| Formula commit for publisher | `commit-formula.sh` | `homebrew-actions` | internal publish step | Phase 2 | preserve `changed=false` no-op and bot commit identity | none | isolated + fixture publish tests |
| Publisher tap push/rebase/retry | shared `push-formula.sh` | `homebrew-actions` | internal publish convergence | Phase 2 | tap deploy key/token; add deterministic first-push failure retry test | none | separate tap-local deletion push path exists |
| Tap-local deletion push/retry | same shared `push-formula.sh` called by `delete-formula.yml` | `homebrew-tap` | tap-local maintenance implementation | Phase 5 preparation | repository `GITHUB_TOKEN contents: write`; preserve no-force bounded convergence | none | must exist before old shared publisher script removal |
| Deploy-key provisioning | `scripts/setup-deploy-key.sh` | `homebrew-actions` | operator setup tooling | Phase 2 | authenticated `gh` operator; secret value never stored in repo | consumer setup docs move | new tooling tested and documented |
| Dependency-update authorization and auto-merge reconciliation | `auto-merge-homebrew-tap.yml`, authorize/reconcile scripts | `homebrew-actions` | `update-policy.yml@<sha>` called by consumer-owned trusted `workflow_run` wrapper | Phase 2 then 3/4 | consumer PR/status/merge permissions; no tap secret; API-only PR evidence | devtools/openapi replace `pull_request_target`; Gate adopts only if needed | malicious/unrelated-update tests + trusted wrapper acceptance |
| Homebrew automation product versioning/release | `publish-automation-release.yml`, `automation-v*` in tap | `homebrew-actions` | single `vX.Y.Z` immutable release family | Phase 2 | automation release contents-write permission in new repo | consumers update dependency namespace | first `homebrew-actions` release passes external fixture acceptance |
| Generic release automation product versioning | not yet centralized | `release-actions` | single `vX.Y.Z` immutable release family | Phase 1 | release repo own release permission | consumers pin root action SHA | first release-actions release accepted |
| Published Formula state | `homebrew-tap/Formula/**` | `homebrew-tap` | Homebrew tap repository state | unchanged | tap Formula CI | no conceptual change | never extracted |
| Formula deletion behavior | `delete-formula.yml`, `delete-formula.sh` | `homebrew-tap` | tap-local manual workflow | Phase 5 cleanup only | existing dry-run/invalid-input baseline | none | retained tap-local push implementation |
| Tap-specific GitHub Actions dependency maintenance | `homebrew-tap/.github/dependabot.yml` | `homebrew-tap` | tap-local Dependabot config | Phase 5 cleanup | current config | none | publisher workflow dependencies removed |
| Publisher unit/regression tests | `test/formula-generator.py`, publisher portions of `test/publishing-base.py`, publisher portions of `test.yml` | `homebrew-actions` | repository-local test suite | Phase 2 | P0-03 baseline + explicit gaps | none | equivalent/new checks green |
| Tap-local tests | Formula deletion/tap-only portions of `test.yml` | `homebrew-tap` | tap-local CI | Phase 5 | deletion/tap validation baseline | none | test workflow split completed |
| Real GitHub Release integration fixture | `formula-fixture-v1.0.0` in `homebrew-tap` | external source/release fixture | test-only repository/release, outside automation tag namespaces | Phase 1/2 setup | deterministic immutable assets; no production tap write | none | external replacement passes before old fixture becomes unused |
| Real tap-write integration fixture | no dedicated repository today | external non-production tap fixture | test-only tap target | Phase 2 | dedicated write credential isolated from production tap | none | required before claiming real publish/no-op/retry acceptance |
| Publisher documentation / Formula contract / setup guide | publisher sections of `homebrew-tap/README.md` | `homebrew-actions` | automation product docs | Phase 2/5 | examples must match new SHA-pinned contracts | consumer setup docs update | consumers migrated before old docs removed |
| Tap installation/maintenance documentation | tap-specific portions of `homebrew-tap/README.md` | `homebrew-tap` | tap docs | Phase 5 | tap behavior only | none | documentation split |
| Publisher-specific actionlint exceptions | `homebrew-tap/.github/actionlint.yaml` entries for reusable workflow contexts | `homebrew-actions` if still needed | automation repo lint config | Phase 2/5 | actionlint | none | publisher workflows removed from tap |
| Gate workflow generator/tests encoding Homebrew pins | Gate `internal/devtool/devcmd/scripts.go` and workflow tests/docs | `gate` | product-owned generated workflow contract using new `homebrew-actions` SHA | Phase 4 Gate migration | Gate tests must stay generator/source-of-truth consistent | Gate migration includes generated and generator files together | new generated workflows/tests green |

### Dependency order derived from the matrix

Phase 1 and Phase 2 are independent after Phase 0:

```text
Phase 1 release-actions
  -> may migrate shared product GitHub Release lifecycle when ready

Phase 2 homebrew-actions
  -> may migrate Homebrew check/publish/update policy when ready
```

Neither automation repository needs the other to implement its core contract.

Consumer migration dependencies are narrower:

- source-distribution consumers can migrate Homebrew as soon as `homebrew-actions` is
  released, regardless of `release-actions` adoption;
- Gate Homebrew migration also requires preserving the existing ordering after Gate's
  release assets are published, but it does not require Gate to use `release-actions`
  first;
- product GitHub Release lifecycle migration can happen independently when
  `release-actions` is accepted.

### Ownership consistency check

The matrix contains no responsibility whose primary target owner is both
`release-actions` and `homebrew-actions`.

The intentional interface between them is indirect:

- `release-actions` may help a product produce a GitHub Release;
- `homebrew-actions` may later read that already-existing GitHub Release when the
  product Formula declares a GitHub Release distribution.

No Homebrew contract calls `release-actions` to create a product release.

### P0-09 conclusions

- Every current automation responsibility identified in P0-02 through P0-08 has a
  single target owner or a defined external-fixture/retirement outcome.
- The mixed `push-formula.sh` and `test.yml` boundaries have explicit split
  prerequisites, preventing Phase 5 from deleting tap-local dependencies.
- Phase 1 and Phase 2 can start independently after the Phase 0 gate.
- Consumer migration can be incremental and channel-specific rather than requiring a
  coordinated all-repository cutover.
