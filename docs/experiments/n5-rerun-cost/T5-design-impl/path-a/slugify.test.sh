#!/usr/bin/env bash
# slugify.test.sh — exercise slugify.mjs against the 5 spec tests

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SLUGIFY="$SCRIPT_DIR/slugify.mjs"

PASS_COUNT=0
FAIL_COUNT=0

# run_case <name> <input> <expected_stdout> <expected_exit>
run_case() {
  local name="$1"
  local input="$2"
  local expected_out="$3"
  local expected_exit="$4"

  local actual_out
  local actual_exit
  actual_out="$(node "$SLUGIFY" "$input" 2>/dev/null)"
  actual_exit=$?
  # trim trailing newline for comparison
  actual_out="${actual_out%$'\n'}"

  if [[ "$actual_exit" -ne "$expected_exit" ]]; then
    echo "FAIL $name: expected exit $expected_exit, got $actual_exit (stdout=\"$actual_out\")"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    return
  fi

  if [[ -n "$expected_out" && "$actual_out" != "$expected_out" ]]; then
    echo "FAIL $name: expected \"$expected_out\", got \"$actual_out\""
    FAIL_COUNT=$((FAIL_COUNT + 1))
    return
  fi

  echo "PASS $name"
  PASS_COUNT=$((PASS_COUNT + 1))
}

# 1. test_basic
run_case "test_basic" "Hello World" "hello-world" 0

# 2. test_punctuation_stripped
run_case "test_punctuation_stripped" "Hi! It's fine." "hi-its-fine" 0

# 3. test_accents_dropped — spec allows either "caf-so-paulo" or "cafe-sao-paulo"
TEST3_NAME="test_accents_dropped"
TEST3_OUT="$(node "$SLUGIFY" "Café São Paulo" 2>/dev/null)"
TEST3_EXIT=$?
TEST3_OUT="${TEST3_OUT%$'\n'}"
if [[ "$TEST3_EXIT" -eq 0 && ( "$TEST3_OUT" == "caf-so-paulo" || "$TEST3_OUT" == "cafe-sao-paulo" ) ]]; then
  echo "PASS $TEST3_NAME"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo "FAIL $TEST3_NAME: expected \"caf-so-paulo\" or \"cafe-sao-paulo\" exit 0, got \"$TEST3_OUT\" exit $TEST3_EXIT"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# 4. test_truncation — 70-char title, result must be <= 60 chars with no trailing '-'
TEST4_NAME="test_truncation"
# 70-char input: 7 words of 9 chars + 6 spaces = 7*9 + 6 = 69... let's count carefully
# "abcdefghi jklmnopqr stuvwxyza bcdefghij klmnopqrs tuvwxyzab cdefghijk" — count
# 9+1+9+1+9+1+9+1+9+1+9+1+9 = 9*7 + 6 = 69
# Add one more char to make 70
TEST4_INPUT="abcdefghi jklmnopqr stuvwxyza bcdefghij klmnopqrs tuvwxyzab cdefghijkl"
# Verify length is 70
INPUT_LEN=${#TEST4_INPUT}
TEST4_OUT="$(node "$SLUGIFY" "$TEST4_INPUT" 2>/dev/null)"
TEST4_EXIT=$?
TEST4_OUT="${TEST4_OUT%$'\n'}"
TEST4_LEN=${#TEST4_OUT}
if [[ "$TEST4_EXIT" -eq 0 && "$INPUT_LEN" -eq 70 && "$TEST4_LEN" -le 60 && "$TEST4_OUT" != *- ]]; then
  echo "PASS $TEST4_NAME"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo "FAIL $TEST4_NAME: input_len=$INPUT_LEN result_len=$TEST4_LEN exit=$TEST4_EXIT out=\"$TEST4_OUT\""
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# 5. test_empty_after_strip
TEST5_NAME="test_empty_after_strip"
node "$SLUGIFY" "!!!" >/dev/null 2>&1
TEST5_EXIT=$?
if [[ "$TEST5_EXIT" -eq 3 ]]; then
  echo "PASS $TEST5_NAME"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo "FAIL $TEST5_NAME: expected exit 3, got $TEST5_EXIT"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

echo ""
echo "Results: $PASS_COUNT passed, $FAIL_COUNT failed"

if [[ "$FAIL_COUNT" -eq 0 ]]; then
  exit 0
else
  exit 1
fi
