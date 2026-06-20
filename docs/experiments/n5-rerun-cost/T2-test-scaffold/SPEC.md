# T2: Write tests for a pure function

A pure function `parseDuration` is provided in `duration.js`. Write a Node.js test harness `duration.test.js` that exercises 7 named cases against it.

## The function (already exists at duration.js)

```js
// Parses human-readable duration strings into milliseconds.
//   "5s"    → 5000
//   "2m"    → 120000
//   "1h30m" → 5400000
//   ""      → throws Error("empty duration")
//   "5x"    → throws Error("invalid unit: x")
export function parseDuration(str) { /* impl */ }
```

## Test harness contract (duration.test.js)

Use only Node's built-in `node:test` and `node:assert` — no Vitest, no Jest.

```js
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { parseDuration } from './duration.js';

test('test_NAME', () => { ... });
```

## Required test cases (all 7 must exist with these exact names)

1. `test_seconds_only` — `parseDuration("30s") === 30_000`
2. `test_minutes_only` — `parseDuration("5m") === 300_000`
3. `test_hours_only` — `parseDuration("2h") === 7_200_000`
4. `test_combined_hms` — `parseDuration("1h30m45s") === 5_445_000`
5. `test_empty_string_throws` — `parseDuration("")` throws an `Error` matching `/empty/i`
6. `test_invalid_unit_throws` — `parseDuration("5x")` throws an `Error` matching `/invalid|unit/i`
7. `test_zero_value` — `parseDuration("0s") === 0`

## Acceptance

```
node --test duration.test.js
```

All 7 tests must pass. Test output must show each test name. No tests beyond the 7 listed.
