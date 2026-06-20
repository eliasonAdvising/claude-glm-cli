#!/bin/bash
set -eo pipefail

F=endpoints.json
PASS=0
FAIL=0

check() {
  local n="$1"
  local desc="$2"
  if eval "$3" >/dev/null 2>&1; then
    echo "PASS $n"
    PASS=$((PASS + 1))
  else
    echo "FAIL $n: $desc"
    FAIL=$((FAIL + 1))
  fi
}

check 1 "endpoints.json exists and parses as JSON" "jq empty '$F' 2>&1"
check 2 "Top-level fields are version, endpoints, retry_policies, env" "jq -e '(keys | sort) == ([\"version\", \"endpoints\", \"retry_policies\", \"env\"] | sort)' '$F'"
check 3 "endpoints array length = 5" "jq -e '.endpoints | length == 5' '$F'"
check 4 "Each endpoint has all 5 required fields" "jq -e '.endpoints | all((keys | sort) == ([\"method\", \"name\", \"path\", \"retry_policy\", \"timeout_ms\"] | sort))' '$F'"
check 5 "retry_policies has all 3 named policies with all 3 fields each" "jq -e '(.retry_policies | keys | sort) == ([\"aggressive\", \"gentle\", \"none\"] | sort) and (.retry_policies | all((keys | sort) == ([\"backoff_ms\", \"jitter\", \"max_attempts\"] | sort)))' '$F'"
check 6 "env array length = 3" "jq -e '.env | length == 3' '$F'"
check 7 "Each env entry has all 4 required fields" "jq -e '.env | all((keys | sort) == ([\"default\", \"key\", \"required\", \"type\"] | sort))' '$F'"
check 8 "API_BASE_URL is required: true" "jq -e '.env[] | select(.key == \"API_BASE_URL\") | .required == true' '$F'"
check 9 "aggressive policy has max_attempts: 5" "jq -e '.retry_policies.aggressive.max_attempts == 5' '$F'"
check 10 "delete_user uses retry_policy: none" "jq -e '.endpoints[] | select(.name == \"delete_user\") | .retry_policy == \"none\"' '$F'"

echo ""
echo "PASS: $PASS/10"

if [ $FAIL -eq 0 ]; then
  exit 0
else
  echo "FAILED: $FAIL checks"
  exit 1
fi
