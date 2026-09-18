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

### Adding this to a new repo

Copy `templates/claude-review-caller.yml` into the target repo as
`.github/workflows/claude-review.yml`, and ensure this repo secret is
set (`Settings → Secrets and variables → Actions`):

- `CLAUDE_CODE_OAUTH_TOKEN`

Currently wired up on: `N10AI`, `ImpactEd_AI`, `One_Off_Apparel`,
`lp-internal-ai-v1`, `elevate215`.
