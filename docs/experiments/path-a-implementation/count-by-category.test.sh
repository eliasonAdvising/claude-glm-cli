#!/usr/bin/env bash
#
# Test harness for count-by-category.

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLI="$HERE/count-by-category"

PASS_COUNT=0
FAIL_COUNT=0

# tmp dir cleaned up on exit
TMPDIR_TEST="$(mktemp -d -t cbc-test-XXXXXX)"
trap 'rm -rf "$TMPDIR_TEST"' EXIT

run_case() {
    local name="$1"
    local csv_path="$2"
    local column="$3"
    local expected_exit="$4"
    local expected_stdout="$5"

    local actual_stdout actual_exit
    set +e
    actual_stdout="$("$CLI" --input "$csv_path" --column "$column" 2>/dev/null)"
    actual_exit=$?
    set -e

    if [[ "$actual_exit" -ne "$expected_exit" ]]; then
        printf 'FAIL %s: expected exit %s, got %s\n' \
            "$name" "$expected_exit" "$actual_exit"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        return
    fi

    if [[ "$actual_stdout" != "$expected_stdout" ]]; then
        printf 'FAIL %s: expected stdout %q, got %q\n' \
            "$name" "$expected_stdout" "$actual_stdout"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        return
    fi

    printf 'PASS %s\n' "$name"
    PASS_COUNT=$((PASS_COUNT + 1))
}

# ---- test_empty_csv ----
# CSV with only a header row, no data. Expect exit 0 + no stdout output.
empty_csv="$TMPDIR_TEST/empty.csv"
cat > "$empty_csv" <<'EOF'
id,category,amount
EOF
run_case "test_empty_csv" "$empty_csv" "category" 0 ""

# ---- test_single_category ----
# 3 data rows all with the same category value.
# Expect one line "<value><TAB>3" on stdout.
single_csv="$TMPDIR_TEST/single.csv"
cat > "$single_csv" <<'EOF'
id,category,amount
1,fruit,10
2,fruit,20
3,fruit,30
EOF
run_case "test_single_category" "$single_csv" "category" 0 $'fruit\t3'

# ---- test_multiple_categories ----
# 6 data rows across 3 categories with counts 3, 2, 1.
# Expect 3 lines in the correct sort order (count desc, then category asc).
multi_csv="$TMPDIR_TEST/multi.csv"
cat > "$multi_csv" <<'EOF'
id,category,amount
1,fruit,10
2,fruit,20
3,fruit,30
4,veg,40
5,veg,50
6,grain,60
EOF
expected_multi=$'fruit\t3\nveg\t2\ngrain\t1'
run_case "test_multiple_categories" "$multi_csv" "category" 0 "$expected_multi"

# ---- summary ----
total=$((PASS_COUNT + FAIL_COUNT))
printf '\n%s/%s passed\n' "$PASS_COUNT" "$total"

if [[ "$FAIL_COUNT" -gt 0 ]]; then
    exit 1
fi
exit 0
