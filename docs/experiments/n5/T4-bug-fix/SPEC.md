# T4: Fix a bug in `pluralize`

The function `pluralize(count, word)` in `pluralize.js` has a bug.

## The bug (verbatim repro from the failing test in `pluralize.test.js`)

When `count === 1`, the singular form should be returned. The function incorrectly returns the plural form even for `count === 1` for certain irregular nouns.

Failing test case:
```
pluralize(1, "knife")  // returns "knives", but should return "knife"
```

## What you must do

1. Diagnose the bug in `pluralize.js`.
2. Fix it so the failing test passes.
3. Verify ALL existing tests in `pluralize.test.js` still pass after the fix.

## Constraints

- Touch ONLY `pluralize.js` — do not modify `pluralize.test.js`
- Do not change the public API signature `pluralize(count, word)`
- Do not add dependencies
- The fix should be minimal and targeted at the root cause

## Acceptance

```
node --test pluralize.test.js
```

All 6 tests must pass after your fix (the 1 currently-failing test included).
