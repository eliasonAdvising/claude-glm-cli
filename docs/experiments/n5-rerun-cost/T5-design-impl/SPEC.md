# T5: `slugify` CLI

Build a small Node.js CLI `slugify.mjs` that turns a title into a URL slug.

## Usage

```
node slugify.mjs "<title>"
node slugify.mjs --help
node slugify.mjs --version
```

## Behavior

Input: any string (single positional arg, quoted).
Output: a URL-safe slug printed to stdout (no trailing newline preferred; one trailing newline is also OK).

Rules — apply in order:
1. Lowercase
2. Strip leading/trailing whitespace
3. Replace any run of whitespace with a single `-`
4. Remove characters that are not `[a-z0-9-]` (so accented chars, punctuation, emoji all drop)
5. Collapse multiple consecutive `-` into a single `-`
6. Strip leading and trailing `-`
7. If result exceeds 60 characters: truncate to 60 characters then strip a trailing `-` if any

Errors:
- `--help` and `--version` print to stdout and exit 0
- No argument: print error to stderr, exit 2
- Empty result after processing: print error to stderr, exit 3

## Test harness

Build `slugify.test.sh` (bash + node, executable) with these 5 named tests:

1. `test_basic` — `node slugify.mjs "Hello World"` → `hello-world`, exit 0
2. `test_punctuation_stripped` — `node slugify.mjs "Hi! It's fine."` → `hi-its-fine`, exit 0
3. `test_accents_dropped` — `node slugify.mjs "Café São Paulo"` → `caf-so-paulo` (or `cafe-sao-paulo` if you strip Unicode-aware; either reading is acceptable), exit 0
4. `test_truncation` — `node slugify.mjs "<a 70-char title>"` → result ≤ 60 chars, no trailing `-`, exit 0
5. `test_empty_after_strip` — `node slugify.mjs "!!!"` → exit 3 (empty result error)

The harness must print `PASS test_X` or `FAIL test_X: expected Y, got Z` per test and exit 0 only if all 5 pass.

## Constraints

- Pure Node.js, no npm dependencies, no external libs
- Single file `slugify.mjs`
- The test harness file
- Match the spec rules exactly; do not invent new behavior beyond what is listed

## Acceptance

```
bash -n slugify.test.sh
./slugify.test.sh
```

All 5 tests pass.
