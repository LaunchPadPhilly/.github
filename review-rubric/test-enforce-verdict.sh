#!/usr/bin/env bash
# Runs enforce-verdict.sh against real verdict files and checks the exit code
# and which failure it reports. Run it directly: review-rubric/test-enforce-verdict.sh
set -uo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
enforce="$here/enforce-verdict.sh"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

failures=0

# verdict <name> <job> <findings-json> writes $tmp/<name>.json
verdict() {
  printf '{"schema_version":1,"job":"%s","work_package_id":null,"summary":"s","findings":%s}\n' \
    "$2" "$3" >"$tmp/$1.json"
}

finding() { # finding <severity> <confidence> [initial_severity]
  printf '{"id":"F1","severity":"%s","initial_severity":"%s","title":"t","claim":"c","evidence":"e","file":"a.ts","line":3,"confidence":"%s"}' \
    "$1" "${3:-$1}" "$2"
}

# expect <label> <want-exit> <want-message-fragment> <job> <file>
expect() {
  local label=$1 want=$2 fragment=$3 out got
  out=$("$enforce" "$4" "$5" 2>&1)
  got=$?
  if [ "$got" -ne "$want" ] || ! grep -qF -- "$fragment" <<<"$out"; then
    echo "FAIL: $label (exit $got, wanted $want with \"$fragment\")"
    echo "$out" | sed 's/^/    /'
    failures=$((failures + 1))
  else
    echo "ok:   $label"
  fi
}

# --- valid verdicts: pass unless a major/blocking finding is present ---
verdict empty code-review '[]'
expect "no findings passes" 0 "pass" code-review "$tmp/empty.json"

verdict advisory code-review "[$(finding nitpick low),$(finding minor medium),$(finding medium high)]"
expect "nitpick, minor and medium never fail" 0 "pass" code-review "$tmp/advisory.json"

verdict major code-review "[$(finding major medium)]"
expect "major fails the code review" 1 "major/blocking" code-review "$tmp/major.json"

verdict blocking test-review "[$(finding blocking high)]"
expect "blocking fails the test review" 1 "major/blocking" test-review "$tmp/blocking.json"

verdict downgraded code-review "[$(finding minor high blocking)]"
expect "a finding downgraded from blocking uses its final tier" 0 "pass" code-review "$tmp/downgraded.json"

# dropped_findings is a record of removed findings and never gates
printf '{"schema_version":1,"job":"code-review","work_package_id":null,"summary":"s","findings":[],"dropped_findings":[{"title":"t","initial_severity":"blocking","reason":"the guard is two lines above"}]}\n' >"$tmp/dropped.json"
expect "a dropped blocking finding does not fail the job" 0 "pass" code-review "$tmp/dropped.json"

# --- invalid verdicts: fail loudly, and say it is the file that is wrong ---
expect "missing file fails" 1 "no verdict file" code-review "$tmp/absent.json"

echo 'not json' >"$tmp/garbage.json"
expect "non-JSON fails" 1 "not valid JSON" code-review "$tmp/garbage.json"

expect "a verdict for the other job fails" 1 "does not match" test-review "$tmp/empty.json"

verdict badtier code-review "[$(finding urgent high)]"
expect "unknown severity fails" 1 "does not match" code-review "$tmp/badtier.json"

verdict lowmajor code-review "[$(finding major low)]"
expect "major with low confidence is invalid, not a pass" 1 "does not match" code-review "$tmp/lowmajor.json"

printf '{"schema_version":1,"job":"code-review","summary":"s","findings":[{"id":"F1","severity":"major","initial_severity":"major","title":"t","evidence":"e","file":null,"line":null,"confidence":"high"}]}\n' >"$tmp/noclaim.json"
expect "finding missing a required field fails" 1 "does not match" code-review "$tmp/noclaim.json"

printf '{"schema_version":1,"job":"code-review","work_package_id":null,"summary":"s","findings":"none"}\n' >"$tmp/strfindings.json"
expect "findings that is not an array fails" 1 "does not match" code-review "$tmp/strfindings.json"

printf '{"schema_version":1,"job":"code-review","work_package_id":null,"summary":"s","findings":[],"dropped_findings":[{"title":"t","initial_severity":"blocking"}]}\n' >"$tmp/baddrop.json"
expect "a dropped finding with no reason fails" 1 "does not match" code-review "$tmp/baddrop.json"

if [ "$failures" -gt 0 ]; then
  echo "$failures test(s) failed"
  exit 1
fi
echo "all passed"
