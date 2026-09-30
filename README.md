# LaunchPadPhilly/.github

Org-wide shared GitHub Actions workflows and Claude skills, so that
per-repo automation is a thin caller instead of copy-pasted logic that
drifts across repos.

## Claude Review

`.github/workflows/claude-review-reusable.yml` is a `workflow_call`
target that runs an automatic, review-only Claude pass on every PR in
a calling repo. It never approves or requests changes — only posts a
`COMMENT`-type review. What the reviewer is told lives in plain files,
fetched at run time from this (public) repo — edit these, not the
workflow:

| File | Used by |
|---|---|
| `prompts/code-review.md` | `review` job |
| `prompts/test-review.md` | `test-review` job |
| `review-rubric/rubric.md` | appended to both prompts |

The skills in `.claude/skills/` are the local-dev counterparts for
running the same review by hand. Full design notes are in the reusable
workflow's header comment.

To try prompt changes before merging, point a throwaway PR's caller at
your branch: `uses: LaunchPadPhilly/.github/.github/workflows/claude-review-reusable.yml@<branch>`
with `with: { review_ci_ref: <branch> }`.

Bills a Claude Pro/Max subscription (`CLAUDE_CODE_OAUTH_TOKEN`) —
the only auth path. If that call fails (missing/revoked token, rate
limit, quota), the job fails and shows red on the PR check, on
purpose — no silent fallback to metered API billing.

### Severity rubric

Both jobs label findings on one five-tier scale — nitpick / minor / medium /
major / blocking — defined once in `review-rubric/rubric.md`, with the
verdict JSON shape in `review-rubric/verdict.schema.json`. Only `major`
and `blocking` findings are meant to fail a check.

## Automated Test Review

A second, separate job in the same reusable workflow judges whether a PR's
tests actually verify the outputs committed to by its linked OpenProject
work package, against the org's E2E-first testing ground rules (real paths
over mocks, verifiable/repeatable artifacts, no tautological or
narrowly-pinned regression tests). Unlike Claude Review above, **this one
is a real merge gate**: it fails the job (red check) when tests are
missing or inadequate, and uploads a `test-review-verdict` JSON artifact
either way so the verdict is inspectable, not just a checkmark. Its prompt
and ground rules are `prompts/test-review.md`.

The companion dev-facing skill, `.claude/skills/test-creation/SKILL.md`,
writes tests against the same ground rules from an OpenProject work
package — meant to be copied into each repo's own `.claude/skills/` and
run locally (`Skill` tool) before opening a PR, so devs hit these standards
before CI does, not instead of it.

`test-review` reaches OpenProject via OpenProject's own built-in MCP server
(an Enterprise add-on, enabled org-wide on `projects.liftofflearning.tech`
under Administration → Artificial Intelligence → Model Context Protocol) —
a remote HTTP endpoint at `<OPENPROJECT_URL>/mcp`, not a third-party npm
package or a self-run copy of any community/personal MCP server. Nothing
to check out or pin in this job as a result.

**Fully verified end-to-end (2026-09-22)** on a throwaway PR
(`LaunchPadPhilly/claude-review-ci-test` #2): the bearer personal-API-token
auth path reaches `<OPENPROJECT_URL>/mcp`, tool names
(`search_work_packages`, `list_work_package_comments`, ...) work as
confirmed, the verdict correctly cites real OpenProject acceptance
criteria, and a `COMMENT`-type PR review gets posted. Getting there
surfaced and fixed three independent, stacked bugs — see the CONFIRMED /
FULLY VERIFIED comments in `claude-review-reusable.yml`'s header and the
`test-review` job's own step comments for the live-run evidence of each.

### Adding this to a new repo

Copy `templates/claude-review-caller.yml` into the target repo as
`.github/workflows/claude-review.yml`, copy
`.claude/skills/test-creation/` into the target repo's own
`.claude/skills/` (skills aren't fetched cross-repo — see the reusable
workflow's header comment for why), and ensure these repo secrets are set
(`Settings → Secrets and variables → Actions`) — `OPENPROJECT_URL` and
`OPENPROJECT_API_KEY` are org-wide (one org secret each, scoped to the
participating repos), so most repos only need to inherit them:

- `CLAUDE_CODE_OAUTH_TOKEN`
- `OPENPROJECT_URL` — org-wide
- `OPENPROJECT_API_KEY` — org-wide; a personal API token from `<OPENPROJECT_URL>/my/access_token`, ideally for a dedicated read-only CI/bot identity rather than a real person's account

Then add the `test-review` job name as a **required status check** in
branch protection (`Settings → Branches`) — without that, the job can still
go red but won't actually block merging. `review` (code quality) should
stay off required-status-checks; it's advisory by design.

Currently wired up on: `N10AI`, `ImpactEd_AI`, `One_Off_Apparel`,
`lp-internal-ai-v1`, `elevate215` — for `review` only. `test-review` is
verified (see above) but not yet rolled out to any production repo as a
required status check — that's the next step.
