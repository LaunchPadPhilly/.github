---
name: thermo-nuclear-code-quality-review
description: Review a PR's diff for correctness and maintainability, grading each finding on the shared five-tier severity rubric. Use for a code quality review, maintainability review, or deep code audit of a PR.
---

# Code Quality Review

The skill keeps its original directory name because callers and history
reference `thermo-nuclear-code-quality-review`; the review itself is no
longer "thermo-nuclear". The CI job does not invoke this skill. It loads
`prompts/code-review.md`, which is the source of truth for the review
wording. This file is the same guidance for interactive use.

> **Severity** — label every finding with the shared five-tier rubric in
> [`review-rubric/rubric.md`](../../../review-rubric/rubric.md) (nitpick / minor /
> medium / major / blocking). Only `major` and `blocking` fail the check.

## Standard

Review the diff versus its base branch for bugs, broken contracts, and
maintainability. Read the surrounding code before judging. Report only
what you can support from the code. Most PRs have few real problems; if
there is nothing worth the author's time, say so briefly and stop.

## What to look for

- Bugs: logic errors, unhandled error paths, edge cases, races, data
  loss, security issues.
- Broken contracts: callers, tests, migrations, or config left
  inconsistent by the change.
- Maintainability: tangled control flow, special cases bolted onto
  unrelated flows, duplicated logic where a canonical helper exists,
  logic in the wrong layer, needless wrappers, casts, or optionality
  that hide the real contract.
- Size: a file this PR pushes past 1000 lines.

## Weighing findings

- The rubric decides the tier, not how differently you would have
  designed it.
- Structural, design, and restructuring suggestions are `medium` at
  most. Raise one only if you can name the concrete defect or rework it
  will cause, and then rate it as that defect.
- A file crossing 1000 lines is `minor` by default.
- A simpler restructuring is advice: say what it would delete or
  simplify, in one finding.
- Do not report what you could not verify, or style preferences the
  repo's own linter and conventions do not ask for.

## Output

One entry per finding, most severe first: tier, `file:line`, what is
wrong and what merging as-is would cause, and the evidence. A one-line
tally by tier goes at the top. Post a single PR review with event type
COMMENT. Never approve and never request changes; a human is the merge
gate.
