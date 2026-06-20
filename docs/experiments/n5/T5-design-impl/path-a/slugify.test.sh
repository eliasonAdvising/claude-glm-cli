#!/usr/bin/env bash
# slugify.test.sh — 5 named tests for slugify.mjs

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLI="node ${SCRIPT_DIR}/slugify.mjs"

PASS_COUNT=0
FAIL_COUNT=0

report_pass() {
  echo "PASS $1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

report_fail() {
  echo "FAIL $1: expected $2, got $3"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

# test_basic
test_basic() {
  local name="test_basic"
  local got exit_code
  got=$($CLI "Hello World" 2>/dev/null)
  exit_code=$?
  local expected="hello-world"
  if [[ "$got" == "$expected" && $exit_code -eq 0 ]]; then
    report_pass "$name"
  else
    report_fail "$name" "'$expected' (exit 0)" "'$got' (exit $exit_code)"
  fi
}

# test_punctuation_stripped
test_punctuation_stripped() {
  local name="test_punctuation_stripped"
  local got exit_code
  got=$($CLI "Hi! It's fine." 2>/dev/null)
  exit_code=$?
  local expected="hi-its-fine"
  if [[ "$got" == "$expected" && $exit_code -eq 0 ]]; then
    report_pass "$name"
  else
    report_fail "$name" "'$expected' (exit 0)" "'$got' (exit $exit_code)"
  fi
}

# test_accents_dropped
test_accents_dropped() {
  local name="test_accents_dropped"
  local got exit_code
  got=$($CLI "Café São Paulo" 2>/dev/null)
  exit_code=$?
  # Accept either "caf-so-paulo" (naive strip) or "cafe-sao-paulo" (Unicode-aware)
  if [[ ( "$got" == "caf-so-paulo" || "$got" == "cafe-sao-paulo" ) && $exit_code -eq 0 ]]; then
    report_pass "$name"
  else
    report_fail "$name" "'caf-so-paulo' or 'cafe-sao-paulo' (exit 0)" "'$got' (exit $exit_code)"
  fi
}

# test_truncation — feed a 70-char title, expect <=60 chars, no trailing '-'
test_truncation() {
  local name="test_truncation"
  # 70 chars: 10 groups of "abcdefg xx" — but better to be deterministic.
  # Build a title that is exactly 70 chars and would produce a long slug.
  local title="The quick brown fox jumps over the lazy dog and then runs back home ab"
  # Verify length is 70
  local title_len=${#title}
  if [[ $title_len -ne 70 ]]; then
    report_fail "$name" "title length 70" "title length $title_len"
    return
  fi
  local got exit_code
  got=$($CLI "$title" 2>/dev/null)
  exit_code=$?
  local got_len=${#got}
  if [[ $exit_code -eq 0 && $got_len -le 60 && "$got" != *- ]]; then
    report_pass "$name"
  else
    report_fail "$name" "len<=60 no trailing - (exit 0)" "'$got' len=$got_len (exit $exit_code)"
  fi
}

# test_empty_after_strip
test_empty_after_strip() {
  local name="test_empty_after_strip"
  local got exit_code
  got=$($CLI "!!!" 2>/dev/null)
  exit_code=$?
  if [[ $exit_code -eq 3 ]]; then
    report_pass "$name"
  else
    report_fail "$name" "exit 3" "exit $exit_code (stdout: '$got')"
  fi
}

test_basic
test_punctuation_stripped
test_accents_dropped
test_truncation
test_empty_after_strip

echo ""
echo "Results: ${PASS_COUNT} passed, ${FAIL_COUNT} failed"

if [[ $FAIL_COUNT -eq 0 ]]; then
  exit 0
else
  exit 1
fi
