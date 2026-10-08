Review this PR's diff against its base branch for code quality:
correctness, maintainability, abstraction quality, and codebase
health. Read the changed files and the code around them before you
judge anything.

Report only what you can support. Most PRs have few real problems;
an honest review of a clean PR is short. If you find nothing worth
the author's time, say so in one or two sentences and stop. Do not
pad the review to look thorough.

What to look for:
- Bugs: logic errors, unhandled error paths, bad edge cases, races,
  data loss, security issues.
- Broken contracts: callers, tests, migrations, or config that the
  change leaves inconsistent.
- Maintainability: tangled control flow, special cases bolted onto
  unrelated flows, duplicated logic where the codebase already has a
  canonical helper, logic in the wrong layer, needless wrappers,
  casts, or optionality that hide the real contract.
- Size: a file this PR pushes past 1000 lines.

How to weigh it:
- Every finding gets exactly one tier from the severity rubric below.
  The rubric decides the tier, not how much you would have designed
  it differently.
- Structural, design, and "this could be restructured" suggestions
  are `medium` at most. Raise one higher only if you can name the
  concrete defect or rework it will cause, and then rate it as that
  defect, not as a design opinion.
- A file crossing 1000 lines is `minor` by default.
- Suggesting a simpler restructuring is fine, but it is advice. Say
  what would be deleted or simplified, and keep it to one finding.
- Do not report anything you could not verify in the code. Do not
  report style preferences the repo's own linter or conventions do
  not ask for.

Format: one entry per finding, ordered most severe first, each with
its tier, `file:line`, what is wrong and what merging as-is would
cause, and the evidence (the triggering input or the quoted line).
Put a one-line tally of findings by tier at the top.

Self-challenge: before you write anything, draft your findings, then
go back through every one of them and try to knock it down. For each:
- Re-open the file at the cited line and the code around it. Does the
  claim still hold? Look for the guard, caller, test, or config that
  already handles it. A finding you can no longer support is dropped.
- Check the tier against the rubric's definition, not against how
  strongly you felt. If the evidence only supports a lower tier,
  downgrade it. Never raise a tier here.
Keep each finding's first tier as `initial_severity` and the tier it
ends at as `severity`; they differ only when you downgraded it. Record
every finding you dropped in `dropped_findings` with the reason. A
finding that survives unchanged has `initial_severity` equal to
`severity`.

Verdict: write a JSON verdict file to .code-review-verdict.json at the
repo root. The calling workflow uploads it as a build artifact and
derives pass/fail from it, so get the shape exactly right. It must
validate against the review-rubric schema, with `job` set to
"code-review":

{
  "schema_version": 1,
  "job": "code-review",
  "work_package_id": null,
  "summary": "One real bug in the retry path; the rest is clean.",
  "findings": [
    {
      "id": "F1",
      "severity": "major",
      "initial_severity": "blocking",
      "title": "Retry loop never backs off",
      "claim": "A 429 from the API is retried immediately, so a rate limit becomes a hot loop.",
      "evidence": "src/client.ts:88 retries with no delay when status is 429. Re-checked: no caller adds a delay, but the loop is capped at 3 tries, so it is not unbounded.",
      "file": "src/client.ts",
      "line": 88,
      "confidence": "high"
    }
  ],
  "dropped_findings": [
    {
      "title": "Missing null check on user.email",
      "initial_severity": "major",
      "reason": "src/auth.ts:41 already rejects a null email before this code runs."
    }
  ]
}

`work_package_id` is null for this job. `file` and `line` are null only
for a finding with no single location. Use `confidence: low` rather
than inflating a finding you cannot back up; a low-confidence finding
cannot be major or blocking. A clean PR gets `"findings": []`; omit
`dropped_findings` if you dropped nothing. The workflow fails the job
only if the file is missing or invalid, or if `findings` holds a
`major` or `blocking` finding. Dropped findings never gate. You do not
decide pass or fail.

Then post your findings as a single PR review with event type COMMENT.
The summary line at the top says how many findings the self-challenge
dropped and downgraded, for example "2 findings dropped, 1
downgraded", then the tally by tier. Do NOT approve this PR and do NOT
request changes as a formal review state; the check's red or green
comes from the verdict file, and a human reviewer is still the merge
gate.
