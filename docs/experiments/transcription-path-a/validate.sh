#!/usr/bin/env bash
# Validator for CHANGELOG.md
# Exits 0 only if every check passes; exits 1 on any failure.

set -u

FILE="CHANGELOG.md"
FAIL_COUNT=0

pass() {
  echo "PASS $1"
}

fail() {
  echo "FAIL $1: $2"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

# Check 1: CHANGELOG.md exists
if [ -f "$FILE" ]; then
  pass "file-exists"
else
  fail "file-exists" "CHANGELOG.md not found"
  echo ""
  echo "Cannot continue without CHANGELOG.md"
  exit 1
fi

# Check 2: Exactly 1 '# ' heading (top-level title)
H1_COUNT=$(grep -c '^# ' "$FILE")
if [ "$H1_COUNT" -eq 1 ]; then
  pass "single-h1"
else
  fail "single-h1" "expected 1 '# ' heading, found $H1_COUNT"
fi

# Check 3: Exactly 5 '## ' headings (one per version)
H2_COUNT=$(grep -c '^## ' "$FILE")
if [ "$H2_COUNT" -eq 5 ]; then
  pass "five-h2"
else
  fail "five-h2" "expected 5 '## ' headings, found $H2_COUNT"
fi

# Check 4: Every '## ' heading line contains an em-dash (—, U+2014)
H2_LINES=$(grep -n '^## ' "$FILE" || true)
MISSING_EMDASH=0
MISSING_LINE=""
while IFS= read -r line; do
  [ -z "$line" ] && continue
  if ! printf '%s' "$line" | grep -q '—'; then
    MISSING_EMDASH=1
    MISSING_LINE="$line"
    break
  fi
done <<< "$H2_LINES"
if [ "$MISSING_EMDASH" -eq 0 ]; then
  pass "h2-em-dash"
else
  fail "h2-em-dash" "h2 missing em-dash: $MISSING_LINE"
fi

# Check 5: No exclamation marks anywhere
if grep -q '!' "$FILE"; then
  EX_LINE=$(grep -n '!' "$FILE" | head -1)
  fail "no-exclamations" "found '!' at: $EX_LINE"
else
  pass "no-exclamations"
fi

# Check 6: No contractions
if grep -Eq "don't|can't|won't|isn't|aren't|hasn't|haven't|wouldn't|shouldn't|couldn't" "$FILE"; then
  CON_LINE=$(grep -nE "don't|can't|won't|isn't|aren't|hasn't|haven't|wouldn't|shouldn't|couldn't" "$FILE" | head -1)
  fail "no-contractions" "found contraction at: $CON_LINE"
else
  pass "no-contractions"
fi

# Check 7: No first-person pronouns (case-sensitive, word-bounded)
if grep -wE '(I|we|our|us)' "$FILE" >/dev/null 2>&1; then
  PR_LINE=$(grep -nwE '(I|we|our|us)' "$FILE" | head -1)
  fail "no-first-person" "found first-person pronoun at: $PR_LINE"
else
  pass "no-first-person"
fi

# Check 8: Every bullet line (starts with '- ') ends with a period
BULLET_BAD=$(awk '/^- / { if (substr($0, length($0), 1) != ".") { print NR": "$0; exit } }' "$FILE")
if [ -z "$BULLET_BAD" ]; then
  pass "bullets-end-period"
else
  fail "bullets-end-period" "bullet without period at line $BULLET_BAD"
fi

# Check 9: The intro paragraph appears verbatim
INTRO="All notable changes to this project. Format loosely follows Keep a Changelog; versioning is SemVer."
if grep -Fq "$INTRO" "$FILE"; then
  pass "intro-verbatim"
else
  fail "intro-verbatim" "intro paragraph not found verbatim"
fi

# Check 10: File ends with exactly one trailing newline
# Conditions:
#   - Last byte must be newline
#   - Second-to-last byte must NOT be newline (no extra blank line)
SIZE=$(wc -c < "$FILE")
if [ "$SIZE" -lt 2 ]; then
  fail "single-trailing-newline" "file too small to evaluate"
else
  LAST_BYTE=$(tail -c 1 "$FILE" | od -An -c | awk '{print $1}')
  PENULT_BYTE=$(tail -c 2 "$FILE" | head -c 1 | od -An -c | awk '{print $1}')
  if [ "$LAST_BYTE" = "\\n" ] && [ "$PENULT_BYTE" != "\\n" ]; then
    pass "single-trailing-newline"
  else
    fail "single-trailing-newline" "last bytes are not exactly one newline (last='$LAST_BYTE' penult='$PENULT_BYTE')"
  fi
fi

echo ""
if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "All checks passed."
  exit 0
else
  echo "$FAIL_COUNT check(s) failed."
  exit 1
fi
