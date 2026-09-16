# LaunchPadPhilly/.github

Org-wide shared GitHub Actions workflows and Claude skills, so that
per-repo automation is a thin caller instead of copy-pasted logic that
drifts across repos.

## Claude Review

`.github/workflows/claude-review-reusable.yml` is a `workflow_call`
target that runs an automatic, review-only Claude pass
(`thermo-nuclear-code-quality-review`, vendored in
`.claude/skills/` here) on every PR in a calling repo. It never
approves or requests changes — only posts a `COMMENT`-type review.
Full design notes are in the reusable workflow's header comment.

Bills a Claude Pro/Max subscription first (`CLAUDE_CODE_OAUTH_TOKEN`),
falls back to API billing only if that's unset or fails
(`ANTHROPIC_API_KEY`), and DMs Christian Kunkel on Slack whenever the
fallback actually runs — debounced to at most once per 20 minutes
across *all* calling repos combined, by checking real Slack message
history rather than per-repo local state.

### Adding this to a new repo

Copy `templates/claude-review-caller.yml` into the target repo as
`.github/workflows/claude-review.yml`, and ensure these repo secrets
are set (`Settings → Secrets and variables → Actions`):

- `CLAUDE_CODE_OAUTH_TOKEN`
- `ANTHROPIC_API_KEY`
- `SLACK_BOT_TOKEN`

Currently wired up on: `N10AI`, `ImpactEd_AI`, `One_Off_Apparel`,
`lp-internal-ai-v1`, `elevate215`.
