#!/usr/bin/env bash
# Validator for endpoints.json — 10 checks, prints PASS <n> per check, exit 0 only if all pass.
set -u

FILE="endpoints.json"
FAIL=0

pass() {
  echo "PASS $1"
}

fail() {
  echo "FAIL $1: $2"
  FAIL=1
}

# Check 1: file exists and parses as JSON
if [ -f "$FILE" ] && jq empty "$FILE" >/dev/null 2>&1; then
  pass 1
else
  fail 1 "endpoints.json missing or invalid JSON"
  exit 1
fi

# Check 2: top-level fields exactly: version, endpoints, retry_policies, env (order-sensitive)
TOP_KEYS=$(jq -r 'keys_unsorted | join(",")' "$FILE")
if [ "$TOP_KEYS" = "version,endpoints,retry_policies,env" ]; then
  pass 2
else
  fail 2 "top-level keys not exactly version,endpoints,retry_policies,env (got: $TOP_KEYS)"
fi

# Check 3: endpoints array length = 5
EP_LEN=$(jq '.endpoints | length' "$FILE")
if [ "$EP_LEN" = "5" ]; then
  pass 3
else
  fail 3 "endpoints length != 5 (got: $EP_LEN)"
fi

# Check 4: each endpoint has all 5 required fields
EP_OK=$(jq '[.endpoints[] | (has("name") and has("method") and has("path") and has("retry_policy") and has("timeout_ms"))] | all' "$FILE")
if [ "$EP_OK" = "true" ]; then
  pass 4
else
  fail 4 "one or more endpoints missing required fields"
fi

# Check 5: retry_policies has all 3 named policies, each with all 3 fields
RP_OK=$(jq '
  (.retry_policies | has("aggressive") and has("gentle") and has("none"))
  and
  ([.retry_policies.aggressive, .retry_policies.gentle, .retry_policies.none][]
    | (has("max_attempts") and has("backoff_ms") and has("jitter"))
  )
' "$FILE" | grep -c true)
# RP_OK should be 3 (3 inner trues from the iteration) when fully valid
RP_HAS=$(jq '(.retry_policies | has("aggressive") and has("gentle") and has("none"))' "$FILE")
RP_FIELDS=$(jq '[.retry_policies.aggressive, .retry_policies.gentle, .retry_policies.none] | map(has("max_attempts") and has("backoff_ms") and has("jitter")) | all' "$FILE")
if [ "$RP_HAS" = "true" ] && [ "$RP_FIELDS" = "true" ]; then
  pass 5
else
  fail 5 "retry_policies missing a named policy or required field"
fi

# Check 6: env array length = 3
ENV_LEN=$(jq '.env | length' "$FILE")
if [ "$ENV_LEN" = "3" ]; then
  pass 6
else
  fail 6 "env length != 3 (got: $ENV_LEN)"
fi

# Check 7: each env entry has all 4 required fields
ENV_OK=$(jq '[.env[] | (has("key") and has("type") and has("default") and has("required"))] | all' "$FILE")
if [ "$ENV_OK" = "true" ]; then
  pass 7
else
  fail 7 "one or more env entries missing required fields"
fi

# Check 8: API_BASE_URL is required: true
BASE_REQ=$(jq '.env[] | select(.key=="API_BASE_URL") | .required' "$FILE")
if [ "$BASE_REQ" = "true" ]; then
  pass 8
else
  fail 8 "API_BASE_URL.required != true (got: $BASE_REQ)"
fi

# Check 9: aggressive policy has max_attempts: 5
AGG_MAX=$(jq '.retry_policies.aggressive.max_attempts' "$FILE")
if [ "$AGG_MAX" = "5" ]; then
  pass 9
else
  fail 9 "aggressive.max_attempts != 5 (got: $AGG_MAX)"
fi

# Check 10: delete_user uses retry_policy: none
DEL_RP=$(jq -r '.endpoints[] | select(.name=="delete_user") | .retry_policy' "$FILE")
if [ "$DEL_RP" = "none" ]; then
  pass 10
else
  fail 10 "delete_user.retry_policy != none (got: $DEL_RP)"
fi

exit "$FAIL"
