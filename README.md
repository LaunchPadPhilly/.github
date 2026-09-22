# LaunchPadPhilly/.github

Org-wide shared GitHub Actions workflows and Claude skills, so that
per-repo automation is a thin caller instead of copy-pasted logic that
drifts across repos.

## Claude Review

`.github/workflows/claude-review-reusable.yml` is a `workflow_call`
target that runs an automatic, review-only Claude pass on every PR in
a calling repo. It never approves or requests changes — only posts a
`COMMENT`-type review. The review prompt (thermo-nuclear code quality
standards) is inlined directly in the workflow file; the readable
source of that prompt is kept at
`.claude/skills/thermo-nuclear-code-quality-review/SKILL.md` — keep
both in sync if you edit the standards. Full design notes are in the
reusable workflow's header comment.

Bills a Claude Pro/Max subscription (`CLAUDE_CODE_OAUTH_TOKEN`) —
the only auth path. If that call fails (missing/revoked token, rate
limit, quota), the job fails and shows red on the PR check, on
purpose — no silent fallback to metered API billing.

## Automated Test Review

A second, separate job in the same reusable workflow —
`.claude/skills/automated-test-review/SKILL.md` — judges whether a PR's
tests actually verify the outputs committed to by its linked OpenProject
work package, against the org's E2E-first testing ground rules (real paths
over mocks, verifiable/repeatable artifacts, no tautological or
narrowly-pinned regression tests). Unlike Claude Review above, **this one
is a real merge gate**: it fails the job (red check) when tests are
missing or inadequate, and uploads a `test-review-verdict` JSON artifact
either way so the verdict is inspectable, not just a checkmark.

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

Tool names (`search_work_packages`, `list_work_package_comments`, ...) are
confirmed live — connected via the claude.ai OpenProject connector's OAuth
path and inspected real responses, not guessed. **Still unverified:** CI
authenticates with a personal API token (Bearer), a different auth path
than the OAuth one just tested — confirm that actually reaches the same
tools with `show_full_output: true` on a throwaway PR before relying on
this job, same discipline that caught the two real GitHub-tool-name bugs
in `review`'s rollout. See the CAUTION block in
`claude-review-reusable.yml`'s header.

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
`lp-internal-ai-v1`, `elevate215` — for `review` only. `test-review` is new
and not yet rolled out to any repo — do a live-verified throwaway PR first
(see the caution above), then add the required-status-check.
