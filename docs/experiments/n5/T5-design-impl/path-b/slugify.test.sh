#!/usr/bin/env bash

# Test harness for slugify.mjs

cd "$(dirname "$0")"

passed=0
failed=0

run_test() {
  local test_name="$1"
  local input="$2"
  local expected="$3"
  local expected_exit="${4:-0}"

  output=$(node slugify.mjs "$input" 2>/dev/null)
  actual_exit=$?

  if [ "$actual_exit" -eq "$expected_exit" ]; then
    if [ "$expected_exit" -eq 0 ]; then
      if [ "$output" = "$expected" ]; then
        echo "PASS $test_name"
        ((passed++))
      else
        echo "FAIL $test_name: expected '$expected', got '$output'"
        ((failed++))
      fi
    else
      echo "PASS $test_name"
      ((passed++))
    fi
  else
    echo "FAIL $test_name: expected exit $expected_exit, got $actual_exit"
    ((failed++))
  fi
}

# Test 1: Basic functionality
run_test "test_basic" "Hello World" "hello-world"

# Test 2: Punctuation stripped
run_test "test_punctuation_stripped" "Hi! It's fine." "hi-its-fine"

# Test 3: Accents dropped (both readings acceptable)
output=$(node slugify.mjs "Café São Paulo" 2>/dev/null)
if [ "$output" = "caf-so-paulo" ] || [ "$output" = "cafe-sao-paulo" ]; then
  echo "PASS test_accents_dropped"
  ((passed++))
else
  echo "FAIL test_accents_dropped: expected 'caf-so-paulo' or 'cafe-sao-paulo', got '$output'"
  ((failed++))
fi

# Test 4: Truncation (70-char title)
long_title="This is a very long title that exceeds the maximum sixty character limit for slugs"
output=$(node slugify.mjs "$long_title" 2>/dev/null)
actual_exit=$?
output_len=${#output}
if [ "$actual_exit" -eq 0 ] && [ "$output_len" -le 60 ] && [[ ! "$output" =~ -$ ]]; then
  echo "PASS test_truncation"
  ((passed++))
else
  echo "FAIL test_truncation: expected output <=60 chars with no trailing -, got length=$output_len, output='$output', exit=$actual_exit"
  ((failed++))
fi

# Test 5: Empty after strip
output=$(node slugify.mjs "!!!" 2>/dev/null)
actual_exit=$?
if [ "$actual_exit" -eq 3 ]; then
  echo "PASS test_empty_after_strip"
  ((passed++))
else
  echo "FAIL test_empty_after_strip: expected exit 3, got $actual_exit"
  ((failed++))
fi

# Summary
echo ""
echo "Tests passed: $passed"
echo "Tests failed: $failed"

if [ "$failed" -gt 0 ]; then
  exit 1
fi

exit 0
