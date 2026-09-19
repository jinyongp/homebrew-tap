# Release / Homebrew Automation Re-architecture Plan

## Status

This document records the agreed target architecture and migration plan for separating
GitHub Release automation, Homebrew publishing automation, and the Homebrew tap.

The migration does not preserve the current repository layout for compatibility.
Existing consumers will be migrated to the new contracts before the old automation is
removed.

## Goals

- Give each repository one primary responsibility and one independent release lifecycle.
- Remove reusable GitHub Actions automation from `homebrew-tap`.
- Keep GitHub Release automation independent from Homebrew.
- Keep Homebrew publishing independent from product-specific release implementation.
- Make every externally consumed automation dependency unambiguous and SHA-pinnable.
- Eliminate unrelated tag families from the repository that provides reusable workflows.
- Preserve or improve the existing Formula generation, audit, install, test, and tap
  publishing guarantees.
- Remove the current `pull_request_target` dependency from automation-update policy.
- Migrate existing consumers without an interval where the tap cannot be published.

## Non-goals

- Preserving the current `homebrew-tap` reusable-workflow paths.
- Keeping the existing `automation-v*` release namespace in `homebrew-tap`.
- Combining GitHub Release publishing and Homebrew publishing into one automation
  product.
- Moving product build logic into shared release automation.
- Moving product-specific Formula metadata into the tap.
- Introducing a GitHub App solely for this migration.
- Supporting mutable branch references for externally consumed automation.

## Target ownership model

### Product repositories

A product repository owns the product and its release policy.

It owns:

- source code and product tests;
- build and packaging logic;
- product Git tags and version selection;
- product-specific release artifacts;
- product-specific GitHub Release orchestration;
- `.github/homebrew/formula.yml`, when the product is distributed through Homebrew.

It does not own shared Formula rendering, Homebrew validation, tap mutation logic, or
shared GitHub Release lifecycle primitives.

### `jinyongp/release-actions`

`release-actions` is a standalone GitHub Action product for reusable GitHub Release
lifecycle primitives. It has no Homebrew-prefixed naming or Homebrew-specific behavior.

Its public entry point is a root action:

```yaml
- uses: jinyongp/release-actions@<full-commit-sha>
```

The repository root therefore contains `action.yml`.

It owns reusable operations such as:

- validating the requested release tag and source commit;
- inspecting an existing GitHub Release;
- creating a draft release from caller-produced artifacts;
- completing an existing matching draft by uploading the requested missing assets and
  publishing it;
- validating uploaded assets and digests;
- enforcing the agreed immutable-release lifecycle;
- treating an already-published, fully matching release as an idempotent no-op;
- failing rather than mutating an already-published release when its commit, assets, or
  digests do not match the requested release state.

Unexpected assets or provenance mismatches in an existing draft are rejected rather
than silently rewritten.

It does not own:

- product build commands;
- product artifact selection rules that cannot be expressed as inputs;
- Formula generation;
- Homebrew validation;
- tap writes.

The action runs as a step in a caller-owned job. Product repositories remain responsible
for runner selection, build matrices, and orchestration around that step.

### `jinyongp/homebrew-actions`

`homebrew-actions` is the standalone Homebrew publishing automation product.

Its high-level public contracts are reusable workflows because the current Homebrew
pipeline requires multiple jobs and native runner matrices:

```yaml
jobs:
  homebrew:
    uses: jinyongp/homebrew-actions/.github/workflows/publish.yml@<full-commit-sha>
```

and, for pull-request validation:

```yaml
jobs:
  homebrew:
    uses: jinyongp/homebrew-actions/.github/workflows/check.yml@<full-commit-sha>
```

A third reusable workflow provides the trusted dependency-update policy invoked by a
consumer's local `workflow_run` wrapper:

```yaml
jobs:
  policy:
    uses: jinyongp/homebrew-actions/.github/workflows/update-policy.yml@<full-commit-sha>
```

The caller repository is the source repository. The public workflows do not accept an
arbitrary source-repository input. This keeps checkout, GitHub API access, and
`GITHUB_TOKEN` authority inside one repository boundary.

The public contracts are explicit.

`check.yml` inputs:

- `formula`: required;
- `tap-repository`: defaults to `jinyongp/homebrew-tap`;
- `tap-branch`: defaults to `main`;
- `spec-path`: defaults to `.github/homebrew/formula.yml`.

The check reads the caller source at the caller event revision. It has no arbitrary
source-repository or source-ref override.

`publish.yml` inputs:

- `formula`: required;
- `ref`: required full 40-character source commit SHA;
- `version`: required product version/release identifier used by Formula rendering;
- `tap-repository`: defaults to `jinyongp/homebrew-tap`;
- `tap-branch`: defaults to `main`;
- `spec-path`: defaults to `.github/homebrew/formula.yml`.

`publish.yml` accepts exactly one tap-write secret: `tap_token` or
`tap_deploy_key`. Requiring an immutable source SHA and explicit version makes manual
retries target the same product release even when the caller's default branch has
advanced.

`update-policy.yml` does not accept source overrides or tap credentials. It uses the
trusted caller's `workflow_run` event and explicitly granted repository permissions
to inspect and reconcile only approved automation-update pull requests.

A consumer that needs to publish a different source repository invokes the workflow
from that source repository rather than delegating arbitrary cross-repository source
access to `homebrew-actions`.

It owns:

- Formula spec parsing;
- Formula rendering;
- source archive and GitHub Release distribution resolution;
- release/source provenance checks required to construct a Formula;
- checksum and asset metadata resolution;
- Formula syntax/audit validation;
- native install/test validation;
- tap checkout, Formula commit, rebase/retry, and push behavior;
- the stable Homebrew check contract;
- automation-update policy for its own reusable workflow dependencies;
- tests for the above behavior.

It does not create product GitHub Releases. A GitHub Release is only an optional
distribution input when a Formula spec declares `distribution.type: github-release`.

### `jinyongp/homebrew-tap`

`homebrew-tap` becomes a tap-state repository.

It owns:

- `Formula/*.rb`;
- tap-specific CI;
- tap-specific maintenance operations such as intentional Formula deletion;
- repository rules needed to protect tap state.

It does not own:

- reusable publishing workflows;
- reusable actions;
- Formula generation implementation;
- generic GitHub Release lifecycle logic;
- automation release versioning;
- dependency-update policy for shared automation consumers;
- automation integration fixtures.

After migration, external product repositories should not use
`jinyongp/homebrew-tap/.github/workflows/*` as dependencies.

## Dependency direction

The intended dependency graph is:

```text
product repository
  |
  +---- uses release-actions ----> GitHub Release
  |
  +---- uses homebrew-actions ---> homebrew-tap
             |
             +---- optionally reads an existing GitHub Release
                   when the Formula distribution requires release assets
```

`release-actions` and `homebrew-actions` are independent products.
`homebrew-actions` must not call `release-actions` as part of its normal publishing
contract.

A product may order its own jobs when its Homebrew distribution requires an artifact
that is produced by its GitHub Release:

```yaml
jobs:
  release:
    # caller-owned build/release orchestration

  homebrew:
    needs: release
    uses: jinyongp/homebrew-actions/.github/workflows/publish.yml@<sha>
```

That ordering is a product-level artifact dependency, not ownership coupling between the
two shared automation repositories.

## Public API rules

### Dependency pinning

All cross-repository automation references use full commit SHAs.

Human-readable release tags may be retained in adjacent comments for update tooling and
reviewability:

```yaml
- uses: jinyongp/release-actions@<full-sha> # v1.0.0
```

```yaml
jobs:
  homebrew:
    uses: jinyongp/homebrew-actions/.github/workflows/publish.yml@<full-sha> # v1.0.0
```

Tags are release metadata. The full SHA is the executable dependency identity.

### Version namespaces

Each reusable automation repository has one product version namespace.

`release-actions`:

```text
v1.0.0
v1.1.0
...
```

`homebrew-actions`:

```text
v1.0.0
v1.1.0
...
```

Test fixtures and unrelated release families must not be published into either
automation repository's tag namespace.

Neither automation product publishes movable major/minor aliases such as `v1` or
`v1.2`. Consumers execute full SHAs and use immutable `vX.Y.Z` releases only as
human- and tooling-readable version metadata.

`homebrew-tap` does not need an automation version namespace after migration.

### Homebrew Formula contract

Product repositories continue to own declarative package metadata under
`.github/homebrew/formula.yml`.

The division remains:

```text
product repository  -> package intent and product-specific install/test metadata
homebrew-actions    -> Formula structure, resolution, rendering, validation, publishing
homebrew-tap        -> resulting Formula state
```

A source distribution does not require a GitHub Release.

A `github-release` distribution consumes an already-existing release and its assets.
Homebrew automation validates the release only to establish that the Formula points at
the intended immutable artifacts.

## GitHub Actions design constraints

The architecture follows the GitHub Actions execution model:

- A root custom/composite/JavaScript action can be referenced as
  `owner/repository@ref`, which is why `release-actions` can expose the concise root
  action API.
- A reusable workflow is referenced by an explicit file under
  `.github/workflows/<file>@ref`, which is required for the multi-job Homebrew
  pipeline.
- Reusable workflows are used for Homebrew orchestration because they can own multiple
  jobs and runner matrices. A composite action cannot replace that orchestration
  without pushing job topology back into every consumer.
- Externally consumed refs are full SHAs even when semantic-version tags are published.

## Security and credential boundaries

### Product release

`release-actions` receives only the permissions required by the caller to manage the
product repository's GitHub Release.

The caller remains responsible for declaring job permissions.

### Homebrew reusable-workflow permissions

Reusable workflows execute with the caller's `github` context. Their
`GITHUB_TOKEN` permissions are supplied by the caller and can only be preserved or
reduced by the called workflow, not elevated.

The public caller examples therefore declare the minimum permissions needed for each
contract rather than relying on repository defaults.

### Homebrew check

The pull-request check path is read-only and must not receive tap write credentials.

It may:

- check out the caller source;
- render a Formula;
- run spec/audit validation;
- run any safe validation that does not mutate the tap.

### Homebrew publish

Only the publishing path receives tap write authority.

The credential is scoped to writing `homebrew-tap`; it is not reused as a general
source-repository or GitHub Release credential.

The migration retains the existing deploy-key model as the default tap-write
credential, while keeping the existing token alternative for callers that already use
it. Introducing a GitHub App is outside this migration.

### Untrusted pull requests

The new dependency-update policy must not depend on `pull_request_target`.

Validation of an untrusted dependency-update pull request runs without write authority.
Any privileged follow-up runs from trusted base-repository code and treats pull-request
content as data rather than executing it.

## Homebrew automation-update policy

The current consumer-side policy is redesigned around the new
`homebrew-actions` dependency.

The policy must prove all of the following before enabling automatic merge:

1. the pull request was created by the expected dependency-update actor;
2. changed dependencies are restricted to the approved `homebrew-actions` public
   contracts;
3. workflow references remain full commit SHAs;
4. all Homebrew automation references resolve to one approved release revision when the
   contracts are intentionally version-locked together;
5. the target revision is a published approved `homebrew-actions` release;
6. the referenced reusable workflow files exist at the candidate revision;
7. no unrelated workflow content or repository file was changed;
8. required Homebrew validation completed successfully for the pull-request head.

The privileged merge step must not check out or execute pull-request code, restore
pull-request-produced caches, or consume executable artifacts produced by the
untrusted run.

The consumer-side trust split is:

1. a `pull_request` workflow calls the read-only `homebrew-actions/check.yml`;
2. a local base-branch workflow is triggered by completion of that validation through
   `workflow_run`;
3. the trusted workflow calls the version-pinned
   `homebrew-actions/.github/workflows/update-policy.yml` contract;
4. the policy re-fetches pull-request metadata and changed workflow content through the
   GitHub API and treats them strictly as data;
5. only after authorization and successful validation may it enable auto-merge.

The current `pull_request_target` implementation is removed during migration rather
than copied into the new repository.

## Reusable workflow self-resolution

A called `homebrew-actions` workflow executes in the caller's GitHub context. Its
implementation files must therefore be resolved independently from the caller source
and the destination tap.

Each called workflow keeps three repository identities explicit:

```text
automation code -> job.workflow_repository at job.workflow_sha
source code     -> caller repository at the requested caller/source ref
tap state       -> tap-repository at tap-branch
```

Internal scripts and local actions are loaded from a checkout of
`job.workflow_repository` at `job.workflow_sha`. They must never be taken from
`main` merely because a newer automation revision exists.

This preserves the security and reproducibility property of a full-SHA reusable
workflow pin: all implementation code executed on behalf of that pin comes from the
same pinned automation revision.

## Concurrent tap updates

Multiple products may update the same tap concurrently. Reusable-workflow
`concurrency` cannot be relied on as a global lock across caller repositories.

`homebrew-actions` therefore retains optimistic push convergence:

1. generate and validate against a known tap state;
2. commit the Formula update;
3. push to the configured tap branch;
4. on a non-fast-forward failure, fetch and rebase;
5. retry a bounded number of times;
6. fail explicitly if convergence cannot be achieved.

The implementation must preserve the property that a retry does not silently discard
another Formula update.

## Repository extraction map

### Move from `homebrew-tap` to `homebrew-actions`

The following current responsibilities move out of the tap, with paths allowed to change
to fit the new repository:

- `.github/workflows/publish-formula.yml`;
- `.github/workflows/auto-merge-homebrew-tap.yml`, redesigned rather than copied;
- `.github/workflows/publish-automation-release.yml`, replaced by
  `homebrew-actions`' own release process;
- `actions/publish/formula/**`;
- Formula generation and source/release resolution scripts;
- Formula validation scripts;
- Formula commit/push scripts used by the reusable publisher;
- dependency-update authorization/reconciliation logic;
- publisher-specific tests and fixtures;
- `scripts/setup-deploy-key.sh`.

### Keep in `homebrew-tap`

- `Formula/**`;
- Formula deletion behavior that directly maintains tap state;
- the tap-local commit/push implementation required by Formula deletion;
- tap-state validation;
- tap-specific repository configuration and documentation.

The current publisher and deletion paths share push behavior. Extraction must split
that dependency before publisher scripts are removed: `homebrew-actions` owns its
remote tap convergence logic, while `homebrew-tap` retains only the minimal
tap-maintenance implementation needed by tap-local operations.

### Extract from product repositories to `release-actions`

Only genuinely shared GitHub Release lifecycle behavior is extracted.
Product-specific build and packaging commands remain in the product repository.

Migration must compare the release implementations in existing consumers before moving
logic so that product-specific assumptions are not accidentally promoted into the
shared action API.

## Testing strategy

### External integration fixtures

Real cross-repository acceptance must not create fixture release families inside either
automation repository.

Maintain test-only infrastructure outside the automation products:

- a neutral source/release fixture repository that can build and publish deterministic
  immutable release assets and invoke candidate `release-actions` /
  `homebrew-actions` revisions as a real caller;
- a non-production tap fixture target for exercising Formula commit, rebase/retry, and
  push behavior without mutating the production tap.

Exact fixture repository names are not part of the public automation API.

Pull-request CI inside the automation repositories uses local/unit/contract tests and
does not require destructive cross-repository writes. Before an automation release is
declared ready for consumer migration, its pushed candidate SHA is exercised through
the external fixture path.

### `release-actions`

Required coverage:

- action input validation;
- tag/commit provenance;
- create-new-draft, asset upload, and publish success path;
- matching-draft completion and publish;
- existing-complete-published-release idempotent rerun;
- inconsistent draft rejection;
- published release mismatch rejection without mutation;
- asset presence and digest validation;
- immutable-release verification;
- permission/error reporting without leaking credentials.

The published root action must be exercised through
`uses: jinyongp/release-actions@<sha>` before consumer migration is considered
complete.

### `homebrew-actions`

Required coverage:

- Formula renderer unit/regression tests currently held by `homebrew-tap`;
- source distribution generation;
- GitHub Release distribution generation;
- version/ref normalization;
- invalid Formula spec rejection;
- provenance and checksum validation;
- Formula syntax and strict audit;
- native install/test matrix for supported systems/architectures;
- dry/read-only pull-request check path;
- write-enabled publish path;
- idempotent/no-change publishing;
- concurrent tap push/rebase behavior;
- automation-update authorization, including malicious/unrelated PR changes;
- candidate workflow-path existence at the selected SHA.

Integration fixtures must not introduce unrelated tag families into
`homebrew-actions`.

### `homebrew-tap`

Required coverage after extraction:

- Formula files remain valid;
- tap-specific CI remains green;
- intentional Formula deletion still works;
- publisher removal leaves no dangling script/workflow references.

## Migration phases

Phases 1 and 2 create independent automation products. They may proceed in parallel
after Phase 0; neither product is an implementation dependency of the other. Consumer
migration waits only for the specific replacement contracts that the consumer needs.

### Phase 0 — Baseline and inventory

Phase 0 is a read-only architecture inventory except for inventory/plan documentation.
It must not create the new automation repositories, migrate consumers, change workflow
refs, delete tags/releases, rotate credentials, or alter repository settings.

The inventory evidence is recorded in a dedicated companion document:

`docs/release-homebrew-automation-inventory.md`

That document is the source of truth for Phase 0 evidence. The architecture plan remains
the source of truth for the target state.

#### P0-01 — Establish the repository and consumer inventory

Scope:

- search GitHub and the available local workspace for every reference to:
  - `jinyongp/homebrew-tap/.github/workflows/publish-formula.yml`;
  - `jinyongp/homebrew-tap/.github/workflows/auto-merge-homebrew-tap.yml`;
  - `jinyongp/homebrew-tap/actions/publish/formula`;
- start from the already identified `devtools`, `openapi-sdkgen`, and `gate`, but
  treat the fresh search results as authoritative;
- distinguish live workflow/config references from documentation, tests, generated
  files, temporary clones, and historical-only references.

Record for each live consumer:

- repository;
- reference path;
- dependency kind: reusable workflow, action, Dependabot pattern, or documentation;
- pinned SHA and adjacent version comment, when present;
- whether the reference is used for PR checks, release publishing, dependency update
  policy, or another purpose.

Completion criteria:

- every live external consumer is listed;
- every search hit is classified as live, historical, generated/temp, or documentation;
- no unclassified `homebrew-tap` automation reference remains;
- the inventory records the exact search date and search methods so the scan can be
  repeated before final cleanup.

Dependencies:

- none.

#### P0-02 — Map the current `homebrew-tap` automation surface

Scope:

- inventory all current files and workflows involved in:
  - Formula generation;
  - source/ref/version resolution;
  - GitHub Release distribution resolution;
  - Formula validation;
  - Formula commit and push;
  - reusable PR check/publish orchestration;
  - dependency-update authorization and auto-merge;
  - automation release creation;
  - deploy-key setup;
  - integration/unit fixtures and tests;
- identify shared scripts currently used by both publisher behavior and tap-local
  maintenance, especially Formula deletion and push/rebase logic.

For every responsibility, record:

- current file/workflow;
- caller or entry point;
- inputs/outputs;
- side effects;
- current tests;
- proposed owner: `release-actions`, `homebrew-actions`, `homebrew-tap`, product
  repository, external fixture, or retire.

Completion criteria:

- every file removed or moved by Phases 1, 2, and 5 has a recorded destination or
  retirement decision;
- no script is marked removable while a tap-local workflow still depends on it;
- the current publisher/tap-maintenance sharing boundary is explicitly identified;
- every proposed destination owner is consistent with the ownership model in this
  plan.

Dependencies:

- P0-01 only for understanding external entry points; the local surface scan can begin
  in parallel.

#### P0-03 — Capture the Homebrew behavioral baseline

Scope:

- identify the current commands/tests that prove:
  - source-distribution Formula generation;
  - GitHub-Release-distribution Formula generation;
  - ref/version normalization;
  - invalid spec rejection;
  - release provenance and digest validation;
  - strict Formula audit;
  - native install/test coverage;
  - read-only dry/spec validation;
  - write-enabled Formula publishing;
  - no-change/idempotent publishing;
  - concurrent push/rebase retry behavior;
  - Formula deletion;
  - dependency-update authorization;
- run only the existing non-destructive checks that materially establish the baseline;
- capture representative generated Formula output or normalized assertions where that
  is necessary to compare the extracted implementation later.

Record:

- exact command or workflow;
- expected result;
- actual result at the current baseline revision;
- environment/runner assumptions;
- coverage gaps that are currently untested.

Completion criteria:

- every behavior that Phase 2 must preserve has at least one baseline check or an
  explicitly recorded validation gap;
- baseline failures are distinguished from environment/tooling failures;
- Phase 2 can compare the new implementation against recorded behavior without relying
  on memory or old chat history.

Dependencies:

- P0-02.

#### P0-04 — Inventory consumer Homebrew contracts

Scope:

For every live consumer from P0-01, inspect:

- `.github/homebrew/formula.yml`;
- PR Homebrew validation workflow, if present;
- release-time Homebrew publishing path;
- Formula name;
- source distribution type;
- source ref/version inputs;
- tap credential mode;
- dependency-update grouping/policy;
- current Homebrew automation SHA;
- whether Homebrew publishing is coupled to the product GitHub Release job or only
  ordered after it.

Record the current successful path from product revision to resulting Formula update.

Completion criteria:

- every live consumer has a complete Homebrew contract row;
- each consumer's distribution is classified as source or GitHub Release based;
- each consumer's migration prerequisites are known;
- differences between consumers that require product-specific migration handling are
  called out explicitly.

Dependencies:

- P0-01.

#### P0-05 — Inventory GitHub Release lifecycle implementations

Scope:

For each product repository that publishes GitHub Releases, map:

- version/tag derivation;
- tag/commit validation;
- artifact build ownership;
- artifact upload;
- draft/publish behavior;
- existing-release handling;
- rerun/idempotency behavior;
- checksum/digest validation;
- immutable-release verification;
- release permissions;
- product-specific behavior that must remain local.

Classify each observed behavior as:

- shared `release-actions` candidate;
- product-specific orchestration;
- product-specific build/package logic;
- obsolete/duplicated logic that can disappear after extraction.

Completion criteria:

- the initial `release-actions` API can be derived from actual duplicated behavior
  rather than speculative abstraction;
- no product-specific build command is classified as shared release infrastructure;
- behavioral differences that prevent one common primitive are documented before
  Phase 1 starts.

Dependencies:

- P0-01.
- Can run in parallel with P0-03 and P0-04.

#### P0-06 — Map permissions, credentials, and trust boundaries

Scope:

Without reading or printing secret values, inventory:

- job/workflow `permissions`;
- `GITHUB_TOKEN` usage;
- tap deploy-key usage;
- tap token/PAT usage;
- secret names passed into reusable workflows;
- repository-write operations;
- release-write operations;
- `pull_request`, `pull_request_target`, and `workflow_run` trust boundaries;
- locations where untrusted PR content, artifacts, caches, or checked-out code could
  cross into a privileged job.

Record each credential/permission by purpose and owner rather than by secret value.

Completion criteria:

- every write-capable operation has an identified credential and repository target;
- every secret passed to existing reusable workflows has a migration destination or
  retirement plan;
- the current `pull_request_target` path and its privileged operations are mapped;
- the future `workflow_run` policy can be designed without discovering a new
  privilege requirement mid-implementation;
- no secret value appears in the inventory artifact.

Dependencies:

- P0-02 and P0-04.

#### P0-07 — Capture release/tag and dependency-updater baseline

Scope:

Inventory:

- current `homebrew-tap` tags and GitHub Releases;
- automation release family;
- fixture release/tag family;
- which commits contain the reusable workflow paths;
- Dependabot configuration in every live consumer;
- `actions-up` behavior for representative consumers.

Reproduce and record the original failure mode:

- the updater can select the unrelated fixture release/tag;
- the selected SHA does not contain the referenced reusable workflow path.

Also record the control case where a correct automation release SHA does contain the
required workflow paths.

Completion criteria:

- the original bug has a reproducible baseline with exact refs and path-existence
  evidence;
- the expected post-migration dependency namespace is stated for comparison;
- each consumer's current update mechanism and version-comment usage is known;
- Phase 7 has a concrete before/after regression check.

Dependencies:

- P0-01 and P0-02.

#### P0-08 — Map operational failure, retry, and rollback behavior

Scope:

Inventory the current operational behavior for:

- failed Formula validation;
- failed tap push;
- concurrent tap updates;
- no-change Formula publish;
- failed or repeated GitHub Release publication;
- failed dependency-update authorization;
- failed auto-merge reconciliation;
- Formula deletion;
- reverting a consumer to an older pinned automation SHA.

Record which operations are naturally retryable, idempotent, destructive, or
irreversible.

Completion criteria:

- every migration-critical failure mode has a known current recovery path;
- the Phase 1/2 designs know which idempotency guarantees must be preserved;
- destructive actions that must remain blocked until Phase 6 are explicitly listed;
- the migration rollback strategy can be executed per consumer without rewriting
  product tags or releases.

Dependencies:

- P0-02 through P0-07 as evidence becomes available.

#### P0-09 — Produce the responsibility and migration matrix

Using P0-02 through P0-08, produce one canonical matrix that maps each current
responsibility to:

- current owner/repository/path;
- target owner;
- target public contract, when externally consumed;
- required migration phase;
- required baseline validation;
- credential/permission impact;
- consumer impact;
- removal prerequisite.

Completion criteria:

- every current automation responsibility appears exactly once as a primary ownership
  row;
- each row has one target owner or an explicit retirement decision;
- no responsibility is assigned simultaneously to both `release-actions` and
  `homebrew-actions`;
- no responsibility required by `homebrew-tap` maintenance is scheduled for removal
  before a tap-local replacement exists;
- Phase 1 and Phase 2 can start independently from this matrix.

Dependencies:

- P0-02 through P0-08.

#### P0-10 — Run the Phase 0 gate

Perform a final inventory review before implementation starts.

Verify:

- GitHub/local consumer search is complete and repeatable;
- current automation surface is fully classified;
- Homebrew behavior baseline is captured;
- consumer Homebrew contracts are captured;
- GitHub Release lifecycle duplication is classified;
- credential/permission boundaries are captured without secret values;
- updater/tag baseline reproduces the original issue;
- operational retry/rollback behavior is mapped;
- responsibility/migration matrix has no unowned responsibility or conflicting owner.

Phase 0 completion criteria:

- `docs/release-homebrew-automation-inventory.md` contains evidence for P0-01 through
  P0-09;
- every current automation responsibility has exactly one target owner or retirement
  decision;
- every known live consumer has a migration record;
- every migration-critical behavior has a baseline validation or an explicit known gap;
- current validation commands, credentials, permissions, and repository targets are
  mapped;
- no implementation-blocking architecture question remains hidden in the inventory;
- destructive cleanup remains blocked;
- the worktree contains no implementation change made as part of Phase 0.

Only after P0-10 passes may Phase 1 and Phase 2 begin.

### Phase 1 — Create `release-actions`

- Create the standalone repository.
- Define the root `action.yml` contract.
- Extract only shared GitHub Release lifecycle primitives.
- Add tests for new release creation, matching draft completion, inconsistent draft
  rejection, published-release no-op, published-release mismatch rejection, and rerun
  states.
- Add an independent semantic-version release process.
- Exercise the pushed candidate SHA from the external release fixture.
- Publish the first immutable action release only after that acceptance passes.
- Verify the release commit through the root-action SHA API.

Exit criteria:

- a consumer test can call `jinyongp/release-actions@<full-sha>`;
- product build logic is not present in the repository;
- no Homebrew-specific input or implementation exists.

### Phase 2 — Create `homebrew-actions`

- Create the standalone repository.
- Port Formula generation and validation behavior from `homebrew-tap`.
- Separate the public workflows into:
  - `check.yml` for read-only PR validation;
  - `publish.yml` for full validation plus tap mutation;
  - `update-policy.yml` for the trusted, non-executing dependency-update decision
    reached from a consumer-owned `workflow_run` wrapper.
- Make the tap repository an explicit destination contract rather than assuming the
  automation repository is also the tap.
- Preserve bounded rebase/retry publishing.
- Redesign dependency-update policy without `pull_request_target`.
- Establish one `vX.Y.Z` release family.
- Add unit, contract, security, and native integration coverage.
- Exercise the pushed candidate SHA from the external source fixture against the
  non-production tap fixture.
- Publish the first immutable Homebrew automation release only after that acceptance
  passes.

Exit criteria:

- `check.yml` passes without tap write credentials;
- `publish.yml` can update a test Formula in the non-production tap fixture and
  safely no-op on rerun;
- `update-policy.yml` can authorize an approved dependency-only update without
  checking out or executing pull-request code;
- multi-platform validation is preserved;
- candidate automation revisions are rejected when the referenced workflow path is
  absent;
- no unrelated tag family exists in the repository.

### Phase 3 — Canary consumer migration

Migrate one source repository first.

For the canary:

- replace shared GitHub Release lifecycle code with `release-actions` where the code
  actually matches the shared contract;
- replace `homebrew-tap` workflow dependencies with `homebrew-actions`;
- use full SHA pins plus adjacent release-version comments;
- run PR Formula validation;
- run an actual release path;
- publish the corresponding Formula;
- rerun Homebrew publishing for the same version and verify idempotency;
- exercise dependency-update tooling against the new SHA-pinned dependencies.

Exit criteria:

- product GitHub Release behavior is unchanged from the consumer's perspective;
- Homebrew Formula output is semantically equivalent or intentionally improved;
- Homebrew publishing can be retried independently;
- dependency updater selects only valid automation revisions.

### Phase 4 — Remaining consumer migration

Migrate every remaining consumer one repository at a time.

For each repository:

- preserve its product-specific build/release behavior;
- migrate common GitHub Release lifecycle behavior only when covered by the
  `release-actions` contract;
- migrate Homebrew checks and publishing to `homebrew-actions`;
- update dependency-update configuration;
- replace old auto-merge policy;
- validate an actual or equivalent release/publish path before moving on.

Exit criteria:

- no active consumer references
  `jinyongp/homebrew-tap/.github/workflows/*`;
- no active consumer references `jinyongp/homebrew-tap/actions/publish/formula`.

### Phase 5 — Simplify `homebrew-tap`

After all consumers are migrated:

- remove reusable publishing workflows;
- remove publisher-only action code and scripts;
- remove publisher-only tests and fixtures;
- remove automation-release workflow;
- remove shared-automation update policy;
- reduce README content to tap ownership, installation, maintenance, and any tap-local
  operator procedures;
- run tap-only validation.

Exit criteria:

- `homebrew-tap` contains only tap-state and tap-maintenance responsibilities;
- no public documentation instructs consumers to depend on tap-hosted automation;
- tap CI is green.

### Phase 6 — Retire the old automation release path

Only after consumer migration and tap simplification are accepted:

- stop creating new `automation-v*` releases in `homebrew-tap`;
- remove obsolete fixture infrastructure from active workflows and documentation;
- verify that no dependency updater or live consumer still treats `homebrew-tap` as
  an automation provider.

Historical immutable automation releases/tags are retained by default for provenance
and rollback auditability. Deleting historical releases or tags is not required for
the architecture to be complete because no live consumer depends on `homebrew-tap`
as an Actions provider. A fixture tag/release may be deleted separately when it has no
remaining test or audit value.

Retirement is deliberately last so rollback remains possible throughout the migration.

### Phase 7 — Final acceptance

Run cross-repository acceptance checks:

- GitHub code search finds no live old `homebrew-tap` automation consumers.
- Every `release-actions` consumer uses a full SHA.
- Every `homebrew-actions` consumer uses a full SHA.
- Dependency-update dry runs select the intended release family and an existing action
  or workflow path.
- Homebrew PR validation is read-only.
- Homebrew publish is independently retryable.
- Concurrent Formula updates do not overwrite each other.
- A source-distribution Formula does not require a GitHub Release.
- A GitHub-Release distribution rejects missing, mutable, inconsistent, or incomplete
  release artifacts according to the publisher contract.
- `homebrew-tap` no longer provides reusable publishing automation.
- The old `pull_request_target` Homebrew automation-update path is gone.

## Rollback strategy

Repository extraction is additive until all consumers migrate.

During Phases 1–4:

- existing `homebrew-tap` automation remains available;
- old releases/tags remain intact;
- each consumer can be reverted independently to its previous pinned SHA.

During Phase 5:

- removal begins only after all known consumers have migrated and passed acceptance.

During Phase 6:

- the old release-producing workflow is disabled only after the code migration has been
  accepted;
- historical immutable releases/tags remain available unless a separate cleanup
  decision explicitly removes them.

No migration phase should require rewriting product Git tags or published product
GitHub Releases.

## Validation gates by work unit

Each implementation unit is complete only after its local contract passes.

1. `release-actions`
   - action metadata validation;
   - unit/contract tests;
   - end-to-end root-action invocation by full SHA.

2. `homebrew-actions`
   - syntax/static validation;
   - generator regression suite;
   - workflow/action lint;
   - read-only check integration;
   - native Formula validation;
   - tap publish/retry integration;
   - dependency-update policy security tests.

3. Each consumer
   - existing product tests;
   - release workflow validation;
   - Homebrew PR check;
   - Homebrew publishing path;
   - dependency updater dry run.

4. `homebrew-tap`
   - tap CI;
   - Formula validation;
   - repository search for removed automation dependencies.

## Completion criteria

The re-architecture is complete when:

- GitHub Release automation is provided by `release-actions` and contains no Homebrew
  responsibility.
- Homebrew automation is provided by `homebrew-actions` and does not create product
  GitHub Releases.
- `homebrew-tap` is no longer an Actions dependency provider.
- Existing consumers have moved to full-SHA references of the new automation products.
- Product build logic remains product-owned.
- Formula metadata remains product-owned while Formula rendering/validation remains
  Homebrew-automation-owned.
- Automation update policy no longer relies on `pull_request_target`.
- The original unrelated-tag-family failure mode cannot occur because reusable
  automation repositories expose only their own product release family.
- Cross-repository acceptance and rollback gates have been exercised before old
  automation cleanup.
