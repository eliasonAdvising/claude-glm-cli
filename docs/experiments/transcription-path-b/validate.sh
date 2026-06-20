#!/bin/bash

CHANGELOG="CHANGELOG.md"
exit_code=0

check() {
    local name="$1"
    local command="$2"
    if eval "$command" >/dev/null 2>&1; then
        echo "PASS $name"
    else
        echo "FAIL $name: $3"
        exit_code=1
    fi
}

check "CHANGELOG.md exists" "test -f $CHANGELOG" "file not found"

check "exactly 1 # heading" "[ $(grep -c '^# ' $CHANGELOG) -eq 1 ]" "expected 1, got $(grep -c '^# ' $CHANGELOG)"

check "exactly 5 ## headings" "[ $(grep -c '^## ' $CHANGELOG) -eq 5 ]" "expected 5, got $(grep -c '^## ' $CHANGELOG)"

check "every ## heading has em-dash" "[ $(grep '^## ' $CHANGELOG | grep -c '—') -eq 5 ]" "not all ## lines contain em-dash"

check "no exclamation marks" "[ $(grep -c '!' $CHANGELOG) -eq 0 ]" "found $(grep -c '!' $CHANGELOG) exclamation marks"

check "no contractions" "! grep -E \"don't|can't|won't|isn't|aren't|hasn't|haven't|wouldn't|shouldn't|couldn't\" $CHANGELOG" "found contractions"

check "no first-person pronouns" "! grep -wE '(I|we|our|us)' $CHANGELOG" "found first-person pronouns"

check "every bullet ends with period" "[ $(grep '^- ' $CHANGELOG | grep -v '\.$' | wc -l) -eq 0 ]" "some bullets don't end with period"

check "intro paragraph present" "grep -q 'All notable changes to this project. Format loosely follows Keep a Changelog; versioning is SemVer.' $CHANGELOG" "intro paragraph not found"

check "file ends with single newline" "[ $(tail -c 1 $CHANGELOG | wc -l) -eq 1 ]" "file doesn't end with single newline"

exit $exit_code
