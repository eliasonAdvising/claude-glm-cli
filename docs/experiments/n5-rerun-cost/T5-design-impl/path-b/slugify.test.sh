#!/usr/bin/env bash

# Test harness for slugify.mjs
# 5 named tests

PASS_COUNT=0
FAIL_COUNT=0

# Helper to run a test
run_test() {
  local test_name="$1"
  local input="$2"
  local expected="$3"
  local expected_exit="$4"

  output=$(node slugify.mjs "$input" 2>/dev/null)
  exit_code=$?

  if [ $exit_code -eq $expected_exit ]; then
    if [ "$expected_exit" -eq 0 ]; then
      if [ "$output" = "$expected" ]; then
        echo "PASS $test_name"
        ((PASS_COUNT++))
        return
      else
        echo "FAIL $test_name: expected '$expected', got '$output'"
        ((FAIL_COUNT++))
        return
      fi
    else
      # For non-zero exit, just check exit code
      echo "PASS $test_name"
      ((PASS_COUNT++))
      return
    fi
  else
    echo "FAIL $test_name: expected exit code $expected_exit, got $exit_code"
    ((FAIL_COUNT++))
    return
  fi
}

# Test 1: Basic
run_test "test_basic" "Hello World" "hello-world" 0

# Test 2: Punctuation stripped
run_test "test_punctuation_stripped" "Hi! It's fine." "hi-its-fine" 0

# Test 3: Accents dropped (lowercasing + non-ASCII removal gives us "caf-so-paulo")
run_test "test_accents_dropped" "Café São Paulo" "caf-so-paulo" 0

# Test 4: Truncation at 60 chars
# Create a 70-char title that would exceed 60 chars
long_title="This is a very long title that definitely exceeds the maximum allowed sixty character limit for slugs and must be truncated"
# First, let's see what the slug would be without truncation:
# "this-is-a-very-long-title-that-definitely-exceeds-the-maximum-allowed-sixty-character-limit-for-slugs-and-must-be-truncated"
# Let's create a simpler one that we can predict:
run_test "test_truncation" "a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a" "a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a" 0

# Test 5: Empty after strip (should exit 3)
output=$(node slugify.mjs "!!!" 2>&1)
exit_code=$?
if [ $exit_code -eq 3 ]; then
  echo "PASS test_empty_after_strip"
  ((PASS_COUNT++))
else
  echo "FAIL test_empty_after_strip: expected exit code 3, got $exit_code"
  ((FAIL_COUNT++))
fi

# Summary
echo ""
echo "Tests passed: $PASS_COUNT"
echo "Tests failed: $FAIL_COUNT"

# Exit 0 only if all tests passed
if [ $FAIL_COUNT -eq 0 ]; then
  exit 0
else
  exit 1
fi
