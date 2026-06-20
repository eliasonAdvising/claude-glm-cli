# T3: Refactor `formatAccount` into 3 named helpers

A working function `formatAccount` is provided in `formatter.js`. Refactor it into three smaller named helpers without changing its external behavior.

## Required output signature

```js
// formatter.js — after refactor
export function validateAccount(input) { /* throws on invalid */ }
export function normalizeAccount(raw) { /* returns the normalized object */ }
export function renderAccount(normalized) { /* returns the display string */ }

// The original entry point — keep the same signature + behavior.
export function formatAccount(input) {
  validateAccount(input);
  const norm = normalizeAccount(input);
  return renderAccount(norm);
}
```

## Constraints

- Each helper must be PURE (no I/O, no console.log, no mutation of input).
- `validateAccount` throws on invalid input; otherwise returns nothing (void).
- `normalizeAccount` returns an object with the normalized fields.
- `renderAccount` returns the display string.
- The original `formatAccount(input)` signature and return-value behavior MUST be preserved exactly.
- Do NOT add new dependencies.
- Do NOT modify the test file `formatter.test.js` (it tests the public API).

## Acceptance

```
node --test formatter.test.js
```

All existing tests must pass.

## Style

Names exactly as above. Each helper exported. ESM `export` syntax matching the existing file.
