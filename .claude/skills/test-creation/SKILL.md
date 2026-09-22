---
name: test-creation
description: Write automated tests for a feature from its OpenProject user story, meeting the org's E2E-first testing bar. Use when a dev asks to write tests, add test coverage, or create tests for a work package / user story / OpenProject task.
---

# Test Creation

Write tests that would satisfy the `automated-test-review` CI gate — this
skill is the dev-facing counterpart to that check, so devs can meet the bar
before opening a PR instead of finding out from a failed check.

## Step 1 — get the user story

Ask for (or infer from branch name / recent commits) the OpenProject work
package id. Fetch it with `mcp__openproject__op_get_work_package`. Extract
the concrete, observable outputs it commits to — what a user or another
system should be able to see or do once this ships. If the work package's
acceptance criteria are vague or missing, say so and ask the dev to
tighten them before writing tests against guesses — a test built on a
guessed requirement tests the guess, not the story.

## Step 2 — pick the test shape

Default to **one E2E test per meaningfully distinct output**, exercising
the real path — real DB, real API boundary, real service — not mocks.
Reach for a unit test only for pure logic with no meaningful integration
surface (a calculation, a parser, a pure transform) where an E2E test
would add no additional confidence over a unit test. When in doubt, prefer
E2E — this org has decided E2E is the primary mechanism, not a nice-to-have.

Do not write the simplest passing case and stop. Build in real variance:
multiple records, a boundary value, a second actor, an already-populated
starting state, a state transition — whatever would actually distinguish a
correct implementation from a subtly wrong one. A single happy-path test
does not meet the bar even if it's technically an E2E test.

## Step 3 — build in the artifact and repeatability requirements

Every E2E test must, by design:

- **Leave an artifact.** Write the observed end state — DB rows, API
  response body, a structured assertions-vs-observations report — to a
  fixture/output directory or test-report path a human or CI step can open
  after the run. A green checkmark alone is not acceptable output.
- **Be repeatable.** Own its setup and teardown. Generate unique
  ids/namespaces per run (timestamp, uuid, worker index) instead of writing
  into shared fixture rows/records that a second run or parallel run would
  collide on. Never depend on another test having run first, or on
  leftover state from a previous run. Design it so `run twice back to back`
  is a real, unremarkable case, not a manual-cleanup situation.

## Step 4 — avoid the two harmful patterns

- **No tautological / change-detector tests.** If you notice the test can
  only fail by being deliberately broken, or would fail on any refactor
  regardless of behavior change (snapshotting incidental internal
  structure, asserting a mock was called with today's exact arguments),
  rewrite it to assert on the user-visible output instead, or drop it.
- **Regression tests widen coverage, they don't pin the repro.** If this is
  a bug-fix test, do not just replay the exact reported input through the
  exact code path. Identify the *class* of input/state that was actually
  untested (e.g. "any timezone west of UTC", "any record updated twice in
  the same request") and write the test against that class so the next bug
  in the same family gets caught too.

## Step 5 — consolidate

Before finishing, check whether several tests you (or the existing suite)
wrote are near-duplicate trivial assertions on the same code path — collapse
them into one parameterized/table test rather than leaving five copies that
differ by one input value.

## Handing off

Reference the OpenProject work package id in the test file/commit (e.g. a
comment or commit trailer `Refs: OP#1234`) so `automated-test-review` can
match the test back to the story's outputs during CI review.
