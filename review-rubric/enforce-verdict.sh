#!/usr/bin/env bash
# Derive pass/fail for a review job from its verdict file. Shared by the
# `review` and `test-review` jobs so both gate identically.
#
#   enforce-verdict.sh <code-review|test-review> <verdict-file>
#
# Exit 0: the verdict is valid and holds no major or blocking finding.
# Exit 1: the file is missing, is not valid JSON, does not match
#         verdict.schema.json, or holds a major/blocking finding.
#
# The required fields and the tier names come from verdict.schema.json
# (next to this script, or $VERDICT_SCHEMA), so the schema stays the single
# source. The tiers that fail the check are the schema's `major` tier and
# every tier above it. The model never supplies a pass flag.
set -euo pipefail

job=${1:?usage: enforce-verdict.sh <code-review|test-review> <verdict-file>}
verdict=${2:?usage: enforce-verdict.sh <code-review|test-review> <verdict-file>}
schema=${VERDICT_SCHEMA:-"$(dirname "${BASH_SOURCE[0]}")/verdict.schema.json"}

fail() {
  echo "::error::$job: $1"
  exit 1
}

[ -f "$verdict" ] || fail "no verdict file at $verdict — treating as failed (no evidence the review ran to completion)."
jq -e . "$verdict" >/dev/null 2>&1 || fail "verdict file is not valid JSON — treating as failed."

echo "--- $job verdict ---"
jq . "$verdict"

# A jq error (e.g. .findings is a string) exits non-zero, same as a false
# result, so a malformed verdict cannot slip through as valid.
if ! jq -e --arg job "$job" --slurpfile schema "$schema" '
  . as $v
  | $schema[0] as $s
  | $s["$defs"].severity.enum as $tiers
  | $s["$defs"].finding as $fdef
  | ($v | type) == "object"
    and all($s.required[]; . as $k | $v | has($k))
    and $v.schema_version == $s.properties.schema_version.const
    and $v.job == $job
    and ($v.summary | type) == "string"
    and ($v.findings | type) == "array"
    and ((($v | has("dropped_findings")) | not)
      or ($v.dropped_findings | type == "array"
          and all(.[]; . as $d
            | type == "object"
              and all($s["$defs"].dropped_finding.required[]; . as $k | $d | has($k))
              and ($tiers | index($d.initial_severity)) != null)))
    and all($v.findings[];
      . as $f
      | type == "object"
        and all($fdef.required[]; . as $k | $f | has($k))
        and ($tiers | index($f.severity)) != null
        and ($tiers | index($f.initial_severity)) != null
        and ($fdef.properties.confidence.enum | index($f.confidence)) != null
        and ((($f.severity | IN("major", "blocking")) and $f.confidence == "low") | not))
' "$verdict" >/dev/null; then
  fail "verdict does not match review-rubric/verdict.schema.json — treating as failed."
fi

gating=$(jq --slurpfile schema "$schema" '
  $schema[0]["$defs"].severity.enum as $tiers
  | $tiers[($tiers | index("major")):] as $gating
  | [.findings[] | select(.severity as $x | $gating | index($x))]
  | length
' "$verdict")

if [ "$gating" -gt 0 ]; then
  fail "$gating major/blocking finding(s) — see the verdict artifact and the PR review."
fi
echo "$job: no major or blocking findings — pass."
