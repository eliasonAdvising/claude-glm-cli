#!/usr/bin/env bash
# Validator for endpoints.json — runs 10 checks, prints PASS <n> per check.
# Exits 0 only if all 10 pass.

set -u

FILE="endpoints.json"
fail=0

check() {
  local n="$1"
  local desc="$2"
  local ok="$3"
  if [ "$ok" = "1" ]; then
    echo "PASS $n"
  else
    echo "FAIL $n: $desc"
    fail=1
  fi
}

# 1. endpoints.json exists and parses as JSON
if [ -f "$FILE" ] && jq empty "$FILE" >/dev/null 2>&1; then
  check 1 "endpoints.json exists and parses" 1
else
  check 1 "endpoints.json exists and parses" 0
  echo "Aborting: cannot proceed without valid JSON."
  exit 1
fi

# 2. Top-level fields exactly: version, endpoints, retry_policies, env
top_keys=$(jq -r 'keys_unsorted | join(",")' "$FILE")
if [ "$top_keys" = "version,endpoints,retry_policies,env" ]; then
  check 2 "top-level fields exact and ordered" 1
else
  check 2 "top-level fields exact and ordered (got: $top_keys)" 0
fi

# 3. endpoints array length = 5
ep_len=$(jq '.endpoints | length' "$FILE")
if [ "$ep_len" = "5" ]; then
  check 3 "endpoints array length = 5" 1
else
  check 3 "endpoints array length = 5 (got: $ep_len)" 0
fi

# 4. Each endpoint has all 5 required fields
ep_ok=$(jq '[.endpoints[] | has("name") and has("method") and has("path") and has("retry_policy") and has("timeout_ms")] | all' "$FILE")
if [ "$ep_ok" = "true" ]; then
  check 4 "each endpoint has 5 required fields" 1
else
  check 4 "each endpoint has 5 required fields" 0
fi

# 5. retry_policies has all 3 named policies with all 3 fields each
rp_ok=$(jq '
  (.retry_policies | has("aggressive") and has("gentle") and has("none"))
  and ([.retry_policies[] | has("max_attempts") and has("backoff_ms") and has("jitter")] | all)
' "$FILE")
if [ "$rp_ok" = "true" ]; then
  check 5 "retry_policies complete (3 policies × 3 fields)" 1
else
  check 5 "retry_policies complete (3 policies × 3 fields)" 0
fi

# 6. env array length = 3
env_len=$(jq '.env | length' "$FILE")
if [ "$env_len" = "3" ]; then
  check 6 "env array length = 3" 1
else
  check 6 "env array length = 3 (got: $env_len)" 0
fi

# 7. Each env entry has all 4 required fields
env_ok=$(jq '[.env[] | has("key") and has("type") and has("default") and has("required")] | all' "$FILE")
if [ "$env_ok" = "true" ]; then
  check 7 "each env entry has 4 required fields" 1
else
  check 7 "each env entry has 4 required fields" 0
fi

# 8. API_BASE_URL is required: true
base_req=$(jq '.env[] | select(.key == "API_BASE_URL") | .required' "$FILE")
if [ "$base_req" = "true" ]; then
  check 8 "API_BASE_URL required: true" 1
else
  check 8 "API_BASE_URL required: true (got: $base_req)" 0
fi

# 9. aggressive policy has max_attempts: 5
agg_max=$(jq '.retry_policies.aggressive.max_attempts' "$FILE")
if [ "$agg_max" = "5" ]; then
  check 9 "aggressive.max_attempts = 5" 1
else
  check 9 "aggressive.max_attempts = 5 (got: $agg_max)" 0
fi

# 10. delete_user uses retry_policy: none
del_pol=$(jq -r '.endpoints[] | select(.name == "delete_user") | .retry_policy' "$FILE")
if [ "$del_pol" = "none" ]; then
  check 10 "delete_user retry_policy = none" 1
else
  check 10 "delete_user retry_policy = none (got: $del_pol)" 0
fi

exit "$fail"
