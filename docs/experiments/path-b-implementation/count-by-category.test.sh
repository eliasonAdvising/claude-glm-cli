#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CBC_SCRIPT="$SCRIPT_DIR/count-by-category"

total_tests=0
passed_tests=0

run_test() {
    local test_name="$1"
    local csv_content="$2"
    local column="$3"
    local expected_stdout="$4"
    local expected_exit="${5:-0}"

    ((total_tests++)) || true

    # Create temp CSV file using printf to handle newlines correctly
    local test_csv="/tmp/cbc-test-$test_name.csv"
    printf '%s' "$csv_content" > "$test_csv"

    # Run the script
    local actual_stdout
    local actual_exit
    actual_stdout=$("$CBC_SCRIPT" --input "$test_csv" --column "$column" 2>&1)
    actual_exit=$? || true

    # Compare results
    if [[ "$actual_exit" -eq "$expected_exit" ]]; then
        if [[ "$expected_exit" -eq 0 ]]; then
            if [[ "$actual_stdout" == "$expected_stdout" ]]; then
                echo "PASS $test_name"
                ((passed_tests++)) || true
            else
                echo "FAIL $test_name: stdout mismatch"
                echo "  Expected: '$expected_stdout'"
                echo "  Got:      '$actual_stdout'"
            fi
        else
            echo "PASS $test_name"
            ((passed_tests++)) || true
        fi
    else
        echo "FAIL $test_name: exit code mismatch"
        echo "  Expected exit: $expected_exit"
        echo "  Got exit:      $actual_exit"
    fi

    # Cleanup
    rm -f "$test_csv"
}

# test_empty_csv — CSV with only a header row, no data
run_test "empty_csv" \
    $'category,value\n' \
    "category" \
    "" \
    0

# test_single_category — 3 data rows all with the same category value
run_test "single_category" \
    $'category,value\nalpha,10\nalpha,20\nalpha,30\n' \
    "category" \
    $'alpha\t3'

# test_multiple_categories — 6 data rows across 3 categories with counts 3, 2, 1
run_test "multiple_categories" \
    $'category,value\nbeta,1\nalpha,2\ngamma,3\nbeta,4\nalpha,5\nbeta,6\n' \
    "category" \
    $'beta\t3\nalpha\t2\ngamma\t1'

# Summary
echo ""
echo "Tests passed: $passed_tests / $total_tests"

if [[ $passed_tests -eq $total_tests ]]; then
    exit 0
else
    exit 1
fi
