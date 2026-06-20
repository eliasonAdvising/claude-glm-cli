#!/bin/bash

FILE="/tmp/glm-exp-3/T1-transcription/path-b/endpoints.json"
PASS=0

# Check 1: File exists and parses as JSON
if jq empty "$FILE" 2>/dev/null; then
	echo "PASS 1"
	((PASS++))
else
	echo "FAIL 1: File does not exist or invalid JSON"
	exit 1
fi

# Check 2: Top-level fields exactly: version, endpoints, retry_policies, env
TOP_FIELDS=$(jq -r 'keys_unsorted | join(" ")' "$FILE")
if [[ "$TOP_FIELDS" == "version endpoints retry_policies env" ]]; then
	echo "PASS 2"
	((PASS++))
else
	echo "FAIL 2: Top-level fields incorrect"
	exit 1
fi

# Check 3: endpoints array length = 5
ENDPOINT_COUNT=$(jq '.endpoints | length' "$FILE")
if [[ "$ENDPOINT_COUNT" == "5" ]]; then
	echo "PASS 3"
	((PASS++))
else
	echo "FAIL 3: endpoints array length is $ENDPOINT_COUNT, expected 5"
	exit 1
fi

# Check 4: Each endpoint has all 5 required fields
ALL_ENDPOINTS_VALID=true
jq -c '.endpoints[]' "$FILE" | while read -r endpoint; do
	HAS_ALL=$(echo "$endpoint" | jq 'has("name") and has("method") and has("path") and has("retry_policy") and has("timeout_ms")')
	if [[ "$HAS_ALL" != "true" ]]; then
		ALL_ENDPOINTS_VALID=false
		break
	fi
done

if jq '.endpoints | all(has("name") and has("method") and has("path") and has("retry_policy") and has("timeout_ms"))' "$FILE" >/dev/null; then
	echo "PASS 4"
	((PASS++))
else
	echo "FAIL 4: Not all endpoints have required fields"
	exit 1
fi

# Check 5: retry_policies has all 3 named policies with all 3 fields each
POLICIES_VALID=true
for policy in aggressive gentle none; do
	if !jq --arg p "$policy" '.retry_policies | has($p) and (.retry_policies[$p] | has("max_attempts") and has("backoff_ms") and has("jitter"))' "$FILE" >/dev/null; then
		POLICIES_VALID=false
		break
	fi
done

if [[ "$POLICIES_VALID" == true ]]; then
	echo "PASS 5"
	((PASS++))
else
	echo "FAIL 5: retry_policies missing policies or fields"
	exit 1
fi

# Check 6: env array length = 3
ENV_COUNT=$(jq '.env | length' "$FILE")
if [[ "$ENV_COUNT" == "3" ]]; then
	echo "PASS 6"
	((PASS++))
else
	echo "FAIL 6: env array length is $ENV_COUNT, expected 3"
	exit 1
fi

# Check 7: Each env entry has all 4 required fields
if jq '.env | all(has("key") and has("type") and has("default") and has("required"))' "$FILE" >/dev/null; then
	echo "PASS 7"
	((PASS++))
else
	echo "FAIL 7: Not all env entries have required fields"
	exit 1
fi

# Check 8: API_BASE_URL is required: true
if jq '.env[] | select(.key == "API_BASE_URL") | .required == true' "$FILE" >/dev/null; then
	echo "PASS 8"
	((PASS++))
else
	echo "FAIL 8: API_BASE_URL required is not true"
	exit 1
fi

# Check 9: aggressive policy has max_attempts: 5
if jq '.retry_policies.aggressive.max_attempts == 5' "$FILE" >/dev/null; then
	echo "PASS 9"
	((PASS++))
else
	echo "FAIL 9: aggressive max_attempts is not 5"
	exit 1
fi

# Check 10: delete_user uses retry_policy: none
if jq '.endpoints[] | select(.name == "delete_user") | .retry_policy == "none"' "$FILE" >/dev/null; then
	echo "PASS 10"
	((PASS++))
else
	echo "FAIL 10: delete_user retry_policy is not none"
	exit 1
fi

echo "10/10 PASS"
exit 0
