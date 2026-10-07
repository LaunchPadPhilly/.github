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

Post your findings as a single PR review with event type COMMENT.
Do NOT approve this PR and do NOT request changes as a formal review
state; this review is advisory only. A human reviewer is the merge
gate, not you.
