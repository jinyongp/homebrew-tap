# homebrew-tap Simplification Execution Plan

## Status

This plan covers only `jinyongp/homebrew-tap`.

The following repositories are explicitly out of scope for modification in this
workstream:

- `jinyongp/release-actions`
- `jinyongp/homebrew-actions`
- `jinyongp/release-fixture`
- `jinyongp/homebrew-tap-fixture`
- product/consumer repositories such as `devtools`, `openapi-sdkgen`, and `gate`

Those repositories may be inspected read-only when compatibility or migration state
needs current evidence. Their migration is owned by those repositories and is not a
prerequisite for simplifying `homebrew-tap`. No workflow, branch, release, tag,
repository setting, or source file outside `homebrew-tap` is modified by this plan.

## Goal

Reduce `homebrew-tap` to a tap-state and tap-maintenance repository.

The final repository owns:

- `Formula/*.rb`;
- tap-specific validation;
- intentional Formula deletion;
- the minimal Git retry/push behavior required by tap-local maintenance;
- tap-local GitHub configuration and documentation.

The final repository does not own:

- reusable Formula check/publish workflows;
- shared Formula generation;
- shared Homebrew validation/install/test orchestration;
- shared dependency-update auto-merge policy;
- automation product releases;
- deploy-key provisioning for consumer repositories;
- shared automation integration fixtures.

## Safety rules

1. Do not rewrite or delete historical commits/tags used by SHA-pinned consumers.
   Current `main` may remove the old reusable workflow surface once live executable
   consumers are verified to use immutable full commit SHAs. Consumer-side migration is
   handled separately in the consumer repository.
2. Do not remove `push-formula.sh` until Formula deletion has an independent tap-local
   push implementation.
3. Do not force-push tap history.
4. Do not delete historical `automation-v*` or `formula-fixture-v*` tags/releases as
   part of normal cleanup. Historical cleanup is a separate destructive decision.
5. Do not change consumer repositories in order to make this plan pass.
6. Every work unit is validated and committed separately.
7. Existing Phase 0 documentation commits remain intact; implementation commits are
   added after them.
8. Do not push `homebrew-tap` implementation commits until the local final gate passes,
   unless explicitly requested earlier.

## Target repository shape

Expected active surface after completion:

```text
homebrew-tap/
├── Formula/
│   ├── devtools.rb
│   ├── gate.rb
│   └── openapi-sdkgen.rb
├── .github/
│   ├── dependabot.yml
│   └── workflows/
│       ├── delete-formula.yml
│       ├── test.yml
│       └── scripts/
│           ├── delete-formula.sh
│           └── push-tap-maintenance.sh
├── docs/
│   ├── release-homebrew-automation-inventory.md
│   ├── release-homebrew-automation-rearchitecture.md
│   └── homebrew-tap-simplification-plan.md
├── README.md
└── .gitignore
```

Exact naming may change if validation shows a better tap-local name, but no publisher or
shared automation implementation remains active.

## Gates

### G0 — Baseline gate

Before implementation:

- worktree has no unrelated unstaged/staged changes;
- current Formula files are recorded;
- current delete workflow and retry behavior are understood;
- Phase 0 inventory remains the baseline reference.

Passing G0 authorizes only non-breaking tap-local preparation.

### G1 — Tap-maintenance independence gate

Formula deletion must no longer depend on publisher-owned code.

Required state:

- `delete-formula.yml` calls a tap-local push script;
- the tap-local push script performs bounded push -> fetch/rebase -> retry;
- no force push is used;
- delete dry-run and invalid-input behavior still pass;
- a deterministic regression forces a first push failure and proves retry convergence.

Passing G1 allows publisher-owned push code to be removed later.

### G2 — Pinned-consumer compatibility gate

This is a read-only gate. No external repository is modified.

Repeat GitHub/local searches for live references to:

- `jinyongp/homebrew-tap/.github/workflows/publish-formula.yml`;
- `jinyongp/homebrew-tap/.github/workflows/auto-merge-homebrew-tap.yml`;
- `jinyongp/homebrew-tap/actions/publish/formula`.

Classify every hit.

G2 passes when every live executable consumer reference is pinned to an immutable full
commit SHA and no live executable consumer uses a mutable branch or tag reference.

Existing full-SHA consumers are not blockers: GitHub resolves their reusable workflow
and supporting automation from the pinned historical commit. Their migration to the new
automation ownership model is independent follow-up work in those repositories.

If a mutable live executable reference remains, destructive removal stops here until
that reference is pinned or migrated.

### G3 — Automation removal gate

After G2 passes, remove the tap-hosted automation product and its tests/docs/config.

G3 passes when the repository has no active publisher or automation-release
implementation.

### G4 — Final tap acceptance gate

The final repository must pass tap-only tests, Formula validation, actionlint, reference
searches, and worktree review.

Only after G4 passes is the simplification complete.

## Work units

### HT-01 — Freeze baseline and implementation scope

Actions:

- verify `homebrew-tap` worktree/index state;
- capture exact active automation/tap-maintenance files;
- confirm only `homebrew-tap` will be mutated;
- record current validation commands.

No runtime file change is required.

Completion criteria:

- no unclassified active file remains;
- no external repository is part of the mutation scope.

Commit:

- no commit unless the execution plan itself needs updating.

### HT-02 — Isolate tap-local push behavior

Problem:

`.github/workflows/scripts/push-formula.sh` is currently shared by both
`publish-formula.yml` and `delete-formula.yml`.

Actions:

1. add a tap-local script such as
   `.github/workflows/scripts/push-tap-maintenance.sh`;
2. preserve the existing bounded retry semantics:
   - attempt normal push;
   - fetch the destination branch after rejection;
   - rebase without discarding remote changes;
   - retry a bounded number of times;
   - fail without force push when convergence is impossible;
3. update `delete-formula.yml` to use only the new tap-local script;
4. add/adjust regression coverage for:
   - delete dry-run;
   - invalid Formula names;
   - successful local deletion;
   - injected first-push non-fast-forward followed by successful rebase/retry;
   - preservation of the concurrent remote change.

Files expected to change:

- `.github/workflows/delete-formula.yml`;
- `.github/workflows/scripts/push-tap-maintenance.sh`;
- tap-maintenance regression test(s);
- `.github/workflows/test.yml` only as needed to invoke the new regression.

Files explicitly not removed yet:

- `publish-formula.yml`;
- `push-formula.sh`;
- publisher tests/actions/scripts.

Completion criteria:

- Formula deletion has no runtime dependency on `push-formula.sh`;
- retry regression passes;
- existing publisher behavior remains untouched.

Commit unit:

```text
refactor: isolate tap maintenance push
```

### HT-03 — Establish explicit tap-only validation coverage

Actions:

- identify the validation that belongs permanently to the tap:
  - shell syntax for delete/push maintenance scripts;
  - Formula deletion dry-run;
  - invalid delete input rejection;
  - existing Formula syntax/audit checks that validate tap state;
- add these checks without removing active publisher checks yet;
- make the permanent tap checks separable from publisher tests so the publisher block
  can later be deleted cleanly.

Preferred outcome:

- tap-maintenance assertions live in their own small regression file or clearly isolated
  test job;
- `.github/workflows/test.yml` can later be simplified by deleting publisher jobs
  instead of rewriting tap behavior again.

Completion criteria:

- tap-local behavior has complete independent regression coverage;
- publisher regression failures are no longer required to establish tap-maintenance
  correctness.

Commit unit:

```text
test: isolate tap maintenance coverage
```

### HT-04 — Verify external consumer pins

Read-only actions:

- GitHub code search for all three old public dependency forms;
- local workspace search as a secondary check;
- classify documentation/historical/temp hits separately from executable consumers.

No external mutation is allowed.

Completion criteria:

- every live executable consumer uses an immutable full commit SHA;
- no mutable branch/tag reference remains;
- documentation, Dependabot configuration, historical, and temporary hits are
  classified separately from executable consumers.

If the gate fails:

- stop destructive cleanup only for mutable executable consumers;
- report the exact mutable repositories/paths;
- do not remove public automation from `homebrew-tap`.

Commit unit:

- normally none; update inventory documentation only if the evidence materially changes.

### HT-05 — Remove tap-hosted automation product

Runs only after G2 passes.

Remove:

- `.github/workflows/publish-formula.yml`;
- `.github/workflows/auto-merge-homebrew-tap.yml`;
- `.github/workflows/publish-automation-release.yml`;
- `actions/publish/formula/**`;
- publisher-only workflow scripts:
  - `add-formula-spec-fixture.sh`;
  - `authorize-homebrew-tap-update.py`;
  - `commit-formula.sh`;
  - `push-formula.sh`;
  - `reconcile-homebrew-tap-policy.sh`;
  - `require-formula-validation.sh`;
  - `resolve-source-inputs.sh`;
  - `validate-formula.sh`;
- `scripts/setup-deploy-key.sh`;
- publisher-only tests:
  - `test/formula-generator.py`;
  - `test/publishing-base.py`;
  - `test/fixtures/source/**`;
  - `test/fixtures/e2e/**`.

Keep:

- `delete-formula.yml`;
- `delete-formula.sh`;
- `push-tap-maintenance.sh`;
- `Formula/**`.

Then simplify `.github/workflows/test.yml` to the permanent tap-only test surface
established by HT-03.

Completion criteria:

- no active source file implements reusable Homebrew publishing;
- no `pull_request_target` automation policy remains;
- no workflow creates `automation-v*` releases;
- Formula deletion still works and retains bounded retry behavior;
- tap test workflow passes.

Commit unit:

```text
refactor!: remove tap-hosted Homebrew automation
```

This is the principal breaking repository cleanup commit.

### HT-06 — Clean tap configuration

Actions:

- remove obsolete publisher-specific entries from `.github/actionlint.yaml`;
- delete `.github/actionlint.yaml` entirely if no exception remains;
- retain `.github/dependabot.yml` only for GitHub Actions still used by tap-local CI;
- verify no config references removed workflows/actions/scripts.

Completion criteria:

- actionlint passes without stale suppressions;
- Dependabot only manages active tap dependencies.

Commit unit:

```text
chore: remove obsolete tap automation config
```

This may be folded into HT-05 only if the diff stays small and reviewable.

### HT-07 — Rewrite README around tap ownership

README final scope:

- what the tap contains;
- `brew tap jinyongp/tap` / Formula installation usage as appropriate;
- current Formula list or discovery guidance;
- tap maintenance/operator behavior that genuinely belongs here;
- Formula deletion procedure if it is intended as an operator-facing contract.

Remove documentation for:

- tap-hosted reusable publish/check workflows;
- tap-hosted auto-merge policy;
- `automation-v*` consumer pinning;
- low-level `actions/publish/formula`;
- deploy-key provisioning from this repository;
- Formula spec/generator implementation that belongs to shared Homebrew automation.

The architecture/inventory documents remain as historical engineering records unless a
separate documentation-retention decision is made.

Completion criteria:

- README contains no instruction to use `homebrew-tap` as an Actions provider;
- README describes the repository as a tap-state/maintenance repository.

Commit unit:

```text
docs: narrow homebrew-tap to tap maintenance
```

### HT-08 — Retire active automation release path

Code-level retirement is complete when
`publish-automation-release.yml` is gone.

Historical remote objects:

- keep existing `automation-v1.1.0 ... automation-v1.5.0` tags/releases by default;
- keep `formula-fixture-v1.0.0` by default;
- do not create new tags/releases in either family.

Deleting historical tags/releases is not needed to finish the repository
simplification and is excluded unless explicitly requested.

Completion criteria:

- no workflow can create a new automation/fixture release;
- historical objects are read-only legacy provenance.

Commit unit:

- normally covered by HT-05; no separate commit required.

### HT-09 — Final acceptance

Run all applicable final checks:

1. repository structure
   - no `actions/publish/formula`;
   - no publish/auto-merge/automation-release reusable workflows;
   - only tap-maintenance workflow scripts remain.

2. reference search
   - no active README/config/test/code reference to removed automation paths;
   - occurrences in historical architecture/inventory docs are allowed and classified.

3. workflow/static validation
   - `actionlint`;
   - shell syntax for remaining scripts;
   - whitespace/diff checks.

4. tap behavior
   - Formula deletion dry-run;
   - invalid Formula deletion rejection;
   - tap-local first-push rejection -> fetch/rebase/retry convergence regression.

5. Formula state
   - all checked-in Formula files pass the repository's chosen syntax/audit validation;
   - Formula files are unchanged unless a separate Formula update is explicitly in
     scope.

6. Git review
   - inspect complete diff from the pre-simplification baseline;
   - verify only `homebrew-tap` changed;
   - verify no unrelated staged work;
   - verify worktree clean after each work-unit commit.

7. external gate confirmation
   - repeat read-only consumer search immediately before declaring removal final;
   - verify remaining executable references, if any, are immutable full commit SHAs.

Completion criteria:

- all checks pass;
- any remaining external old-automation consumer is immutable full-SHA pinned;
- repository contains only tap-state/tap-maintenance responsibilities;
- worktree is clean.

## Commit sequence

Expected implementation commit sequence:

1. `refactor: isolate tap maintenance push`
2. `test: isolate tap maintenance coverage`
3. G2 pinned-consumer compatibility gate
4. `refactor!: remove tap-hosted Homebrew automation`
5. `chore: remove obsolete tap automation config` if kept separate
6. `docs: narrow homebrew-tap to tap maintenance`
7. final acceptance

No commit combines external repository changes because external repository changes are
out of scope.

## Stop conditions

Stop immediately without further destructive changes when:

- G2 finds a mutable live executable consumer reference;
- tap-local deletion loses retry/no-force guarantees;
- Formula validation regresses;
- actionlint/workflow validation fails after cleanup;
- a commit/hook/signing operation fails;
- any required change would need modifying another repository.

## Definition of done

`homebrew-tap` is complete when all of the following are true:

- it contains Formula state and tap-local maintenance only;
- Formula deletion is independently implemented and tested;
- no reusable publish/check/auto-merge workflow remains;
- no publisher Formula action/generator remains;
- no automation release workflow remains;
- no publisher deploy-key tooling remains;
- active CI is tap-only;
- README is tap-only;
- any remaining external reference to a removed public path is immutable full-SHA
  pinned and migrates independently in its consumer repository;
- historical automation/fixture releases are no longer produced;
- final validation passes and the worktree is clean.
