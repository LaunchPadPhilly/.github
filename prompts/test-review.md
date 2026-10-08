Judge whether this PR's automated tests are adequate proof that the
linked OpenProject user story works. Grade each acceptance criterion
on the severity rubric below. This is not a yes/no check and not a
hunt for gaps: a criterion that is properly tested produces no
finding, and a PR with nothing worth reporting gets a short review
saying so.

Step 1 — find the user story:
1. Read the PR title/description and commit messages for an
   OpenProject work package reference (e.g. OP#1234, op:1234, a
   work-package URL).
2. If none is found, do not infer intent from the diff. Read the
   repo's CLAUDE.md (and AGENTS.md if present). Only if it requires
   every change to trace to a work package, report one `blocking`
   finding: no work package is linked. Otherwise report no findings
   and say in the summary that there is no linked work package, so
   nothing was graded.
3. If found, fetch the work package with
   mcp__openproject__search_work_packages (filter by id). Its
   description.raw field is markdown. Read it, and pull any comments
   via mcp__openproject__list_work_package_comments if acceptance
   criteria were refined there. The criteria are the concrete,
   observable outputs the story commits to (user-visible behavior,
   not implementation detail).
4. If the work package has no discernible acceptance criteria, report
   one `medium` finding asking for them and grade nothing. Do not
   guess what "done" means.
5. If the story is plainly unrelated to what the diff changes (for
   example a work package mentioned in passing), report one `minor`
   finding that the link looks wrong and grade nothing.

Step 2 — find the tests for each criterion. Read the PR diff via
mcp__github__get_pull_request_diff / get_pull_request_files, then
search the whole checked-out repository (Grep and Glob over the test
directories and any e2e or integration suites), not just the diff. A
test that already exists elsewhere counts. Before you report a
criterion as untested, say which paths and terms you searched.

Step 3 — judge each test against the ground rules below, in
proportion to the risk of the criterion. A criterion that touches
money, data integrity, auth, or a deploy deserves a stricter reading
than a label or a layout.

Ground rules for "proper automated tests", and the tier a violation
normally earns:
1. E2E-first. For a feature with real complexity, an end-to-end test
   on the real path (real DB, API, or service boundary) is the
   primary evidence. A criterion whose only test mocks the boundary
   the criterion is about is `major`. For simple or pure logic, a
   unit test is fine and earns no finding.
2. Variance. A test that only proves the happy path on the simplest
   input is `medium` when the criterion is risky and `minor`
   otherwise.
3. Artifact and repeatability. A missing inspectable artifact
   (snapshot, report, uploaded trace) is `minor`, or `medium` for a
   risky criterion. A test that is order-dependent or leaves state
   behind is `medium`.
4. No tautological or change-detector tests. Disregard them as
   evidence. If one is the only test for a criterion, that criterion
   is `major` (materially unverified).
5. A regression test that only re-runs the reported input is `medium`
   when the class of input is still untested.
6. Near-identical trivial tests that should be one table test are
   `nitpick`, or `minor` if they stand in for a test that is needed.

A criterion with no working test anywhere is `blocking`, as the
rubric says. Do not raise a tier because there are many gaps; report
the pattern once.

Step 4 — verdict: write a JSON verdict file to
.test-review-verdict.json at the repo root. The calling workflow
uploads it as a build artifact and derives pass/fail from it, so get
the shape exactly right. It must validate against this schema (the
rubric below describes the fields), with `job` set to "test-review":

{
  "schema_version": 1,
  "job": "test-review",
  "work_package_id": "1234",
  "summary": "Two of three criteria are tested; the quoting criterion has no test.",
  "findings": [
    {
      "id": "F1",
      "severity": "blocking",
      "initial_severity": "blocking",
      "title": "Comma quoting has no test",
      "criterion": "Subjects containing a comma are quoted",
      "claim": "No test exercises quoting, so the CSV could break on ordinary data.",
      "evidence": "Searched tests/ and e2e/ for 'quote', 'comma', 'escape'; the only export test is tests/test_export.py:4 with plain subjects.",
      "file": null,
      "line": null,
      "confidence": "high"
    }
  ]
}

Criteria that are adequately tested are not findings; mention them in
`summary`. Set `initial_severity` equal to `severity`. `file` and
`line` are null for a criterion that has no test anywhere. Use
`confidence: low` rather than inflating a finding you cannot back up;
a low-confidence finding cannot be major or blocking. The workflow
fails the job only if the file is missing or invalid, or if it holds
a `major` or `blocking` finding. You do not decide pass or fail.

Then post a single PR review, event type COMMENT, summarizing the
verdict for a human: a one-line tally by tier, the criteria that are
covered, then each finding with its tier, the criterion it concerns,
and the evidence. Do NOT approve or request changes as a formal
review state.
