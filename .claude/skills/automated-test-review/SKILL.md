---
name: automated-test-review
description: Fail a PR whose diff lacks automated tests that genuinely verify the OpenProject user story's outputs. Use for automated-test review, test-adequacy review, or checking whether a PR's tests meet the org's E2E-first testing bar.
disable-model-invocation: true
---

# Automated Test Review

This skill judges whether a PR's automated tests are adequate proof that the
linked OpenProject user story actually works — not whether *some* test
exists. A PR can have 100% green CI and still fail this review.

This is a **merge-blocking** check, run separately from the
`thermo-nuclear-code-quality-review` skill (which stays advisory-only). If
this skill's verdict is `tests_adequate: false`, the calling workflow fails
the job on purpose.

> **Severity** — label every finding with the shared five-tier rubric in
> [`review-rubric/rubric.md`](../../../review-rubric/rubric.md) (nitpick / minor /
> medium / major / blocking). Only `major` and `blocking` fail the check.

## Step 1 — find the user story

1. Read the PR title/description and commit messages for an OpenProject
   work package reference (e.g. `OP#1234`, `op:1234`, a work-package URL).
2. If none is found: **fail immediately**. `tests_adequate: false`,
   `reasons: ["no OpenProject work package linked to this PR"]`. Do not
   attempt to infer intent from the diff alone — there is nothing to test
   the diff against.
3. If found, fetch the work package with `search_work_packages` (filter by
   `id`). Its `description.raw` field is markdown — read it, and pull any
   comments via `list_work_package_comments` if acceptance criteria were
   refined there instead of in the description, for the concrete,
   observable outputs the story commits to
   (not implementation detail — the *user-visible* behavior).
4. If the work package has no discernible acceptance criteria / expected
   outputs (just a title), fail: `reasons: ["OP#<id> has no acceptance
   criteria to test against"]`. Ask that the work package be filled in
   before the PR can pass this check — do not guess what "done" means.

## Step 2 — check what the diff actually added

Read the PR diff. For each output the user story commits to, find the test
(if any) that exercises it, then judge that test against the ground rules
below. A missing test for a committed output is treated the same as an
inadequate one.

## Ground rules for "proper automated tests"

These are the bar — not suggestions. Cite the specific rule a test fails
when flagging it.

1. **E2E-first.** For any feature with real complexity, an end-to-end test
   exercising the real path (not mocks) is the primary evidence, not a
   supplement to unit tests. Don't accept a mocked-unit-test suite in place
   of an E2E test when the real path (real DB, real API, real service
   boundary) could have been exercised instead.
2. **E2E tests must have variance, not the easy path.** A test that only
   proves the happy path with the simplest possible input does not meet the
   bar. Look for realistic complexity: multiple records, edge-of-range
   values, a second actor/tenant, a state transition, something that would
   actually catch a subtly wrong implementation.
3. **E2E tests must produce a verifiable, repeatable artifact.**
   - *Artifact*: something a human or CI step can inspect after the run
     independent of the pass/fail signal — a diffable state snapshot (DB
     rows, API response body) written to a fixture/output directory, a
     structured JSON report of what was asserted vs. observed, or a
     trace/log uploaded by CI. "The assertions passed" is not an artifact.
   - *Repeatable*: deterministic given the same starting state; doesn't
     depend on execution order or state left over from another test; safe
     to re-run without manual cleanup (owns its own setup/teardown, uses
     unique ids/namespaces rather than colliding on shared fixtures).
   - A test missing either property fails this rule even if it's otherwise
     well-targeted.
4. **No tautological / change-detector tests.** A test that can only fail
   if someone deliberately breaks it, or that fails on *any* implementation
   change regardless of whether behavior changed (e.g. snapshotting
   internal structure, asserting a mock was called with the exact
   arguments the implementation happens to use today), does not count as
   coverage. Flag and disregard these even if present.
5. **Regression tests need genuine new coverage, not a pinned repro.** A
   regression test that only re-runs the exact reported input/code path is
   not sufficient by itself — check whether it widens coverage of the
   actual class of input/state that was untested. If it's just the bug
   report turned into an assertion, treat the underlying gap as still
   open.
6. **Combine trivial tests.** Several near-identical trivial-assertion
   tests that could be one parameterized/table test are a smell, not a
   blocker on their own — call it out as a finding but don't fail the PR
   for this alone unless it's masking rule 1–5 gaps (e.g. ten trivial unit
   tests standing in for the one E2E test that was actually needed).

## Step 3 — verdict

Write a JSON verdict file to `.test-review-verdict.json` at the repo root
(the calling workflow uploads this as a build artifact and greps it for the
pass/fail decision — this file *is* the artifact for this review itself, so
get the schema right):

```json
{
  "work_package_id": "1234",
  "tests_adequate": false,
  "outputs_checked": [
    {"output": "user can export their timesheet as CSV", "test": "none found", "verdict": "missing"},
    {"output": "export excludes voided entries", "test": "spec/timesheet_export_spec.rb:44", "verdict": "adequate"}
  ],
  "reasons": [
    "no test exercises the CSV export path end-to-end; only a mocked unit test on the formatter exists (rule 1)",
    "the existing formatter test always uses a single well-formed row — no variance (rule 2)"
  ]
}
```

`tests_adequate` is `false` if **any** committed output has a missing or
inadequate test. Then post a single PR review, event type `COMMENT`
(matching the org's review-only convention — this skill's *job step*
failing is the actual gate, not a formal GitHub review state), summarizing
the verdict file in human-readable form, quoting the specific rule each gap
violates.
