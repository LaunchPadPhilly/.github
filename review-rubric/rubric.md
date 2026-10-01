Severity rubric — shared by the code review and the test review. Label every
finding with exactly one of these five tiers. Severity measures the
consequence of merging the PR as-is, not how strongly you prefer a
different design. Only `major` and `blocking` fail the check; everything
else is advice the author may take or leave.

- nitpick — taste or polish. Merging as-is costs nothing but a preference.
  Code: a local variable named `data` that would read better as `rows`.
  Test: a test name that describes the mechanism instead of the behavior.

- minor — a small, real improvement that is fine to do in a follow-up or
  not at all. No bug, no meaningful maintenance cost.
  Code: a three-line helper that duplicates one already in the shared utils.
  Test: several near-identical trivial tests that could be one table test.

- medium — a real maintainability or coverage cost worth fixing soon, but
  not a merge risk today. Structural and design findings stop here unless
  you can name the concrete defect or rework they will cause.
  Code: a new one-off conditional bolted into a shared flow, or a file
  pushed past 1000 lines without being decomposed.
  Test: the end-to-end test for a criterion only exercises the single
  simplest input, or leaves no inspectable artifact behind.

- major — likely to cause a defect, outage, or significant rework soon, or
  leaves an acceptance criterion materially unverified. Fix before merge.
  Code: an external API call with no error handling, so a realistic timeout
  becomes a 500 for the user.
  Test: a criterion's only test mocks the service boundary it is about, so
  a real integration break would still pass.

- blocking — reserved for exactly four cases. If a finding is not one of
  them, it is not blocking.
    1. A correctness or data-loss bug you can show is reachable.
    2. A security issue (injection, auth bypass, secret exposure, ...).
    3. A broken build, broken migration, or broken deploy.
    4. An acceptance criterion with no working test at all.
  Code: SQL assembled from user input by string concatenation.
  Test: the story commits to "export excludes voided entries" and nothing
  in the repository tests it.

Choosing a tier:
- If a finding sits between two tiers, pick the lower one unless your
  evidence supports the higher one.
- A finding you are not confident in (`confidence: low`) cannot be major
  or blocking. Investigate until you are sure, or downgrade it.
- `major` and `blocking` findings need concrete evidence: the file and
  line, and the input, state, or sequence that triggers the problem.
  "This could be cleaner" is never evidence.
- Do not raise a finding's severity because there are many of it. Report
  the pattern once, at the severity of one instance.
