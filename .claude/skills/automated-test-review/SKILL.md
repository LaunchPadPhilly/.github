---
name: automated-test-review
description: Grade whether a PR's automated tests verify the acceptance criteria of its linked OpenProject user story, using the shared five-tier severity rubric. Use for automated-test review, test-adequacy review, or checking whether a PR's tests meet the org's E2E-first testing bar.
disable-model-invocation: true
---

# Automated Test Review

The CI job does not invoke this skill. It loads `prompts/test-review.md`,
which is the source of truth for the review wording and the verdict shape.
This file is the same guidance for interactive use.

> **Severity** — label every finding with the shared five-tier rubric in
> [`review-rubric/rubric.md`](../../../review-rubric/rubric.md) (nitpick / minor /
> medium / major / blocking). Only `major` and `blocking` fail the check.

The review grades each acceptance criterion; it is not a yes/no gate and
not a hunt for gaps. A criterion that is properly tested produces no
finding.

## Finding the story

1. Look for an OpenProject reference (`OP#1234`, `op:1234`, a URL) in the
   PR title, description, and commit messages.
2. No reference: do not infer intent from the diff. Read the repo's
   CLAUDE.md. Only if it requires every change to trace to a work
   package is a missing link `blocking`; otherwise report no findings
   and say nothing was graded.
3. Fetch the work package (`search_work_packages`, filter by `id`) and
   its comments (`list_work_package_comments`) for the acceptance
   criteria: concrete, observable outputs, not implementation detail.
4. No acceptance criteria is one `medium` finding. A story plainly
   unrelated to the diff is one `minor` finding. Grade nothing in
   either case.

## Finding the tests

Search the whole repository, not just the diff. A test that already
exists elsewhere counts. Say which paths and terms you searched before
calling a criterion untested.

## Ground rules and the tier a violation normally earns

Weigh each by the risk of the criterion (money, data integrity, auth,
deploys are riskier than labels and layout).

1. **E2E-first.** A criterion whose only test mocks the boundary the
   criterion is about is `major`. Pure logic needs only a unit test.
2. **Variance.** Happy-path-only is `medium` for a risky criterion,
   `minor` otherwise.
3. **Artifact and repeatability.** No inspectable artifact is `minor`
   (`medium` if risky). Order-dependent or state-leaking tests are
   `medium`.
4. **No tautological or change-detector tests.** They are not evidence.
   If one is a criterion's only test, that criterion is `major`.
5. **Regression tests** that only re-run the reported input are
   `medium` when the class of input is still untested.
6. **Combine trivial tests.** `nitpick`, or `minor` if they stand in for
   a needed test.

A criterion with no working test anywhere is `blocking`.

## Verdict

Write `.test-review-verdict.json` matching
[`review-rubric/verdict.schema.json`](../../../review-rubric/verdict.schema.json)
with `job: "test-review"`, a `summary`, and one finding per problem
(`criterion` quotes the acceptance criterion). The workflow derives
pass/fail from it: the job fails on a missing or invalid file, or on any
`major` or `blocking` finding. Then post a single PR review with event
type COMMENT, never an approval or change request.
