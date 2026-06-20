---
date: 2026-06-20
experiment: claude-only-vs-claude-plus-glm
task: build a small bash CLI (count-by-category) + test harness from a fixed spec
n: 1 (single task; n=1 is anecdote, not signal — repeat for trend data)
status: completed
verdict: Claude-only won this round on quality; GLM faster-per-dollar but lower-quality output for this task class
---

# Side-by-side experiment: Claude-only vs Claude+GLM

## Question

For a representative bounded-mechanical task, is the Claude+GLM dispatch (Workflow B) actually cheaper, faster, and equal-or-better quality than Claude-only (Workflow A)?

## Design

A single fixed spec (`/tmp/glm-exp/SPEC.md` during run; reproduced inline below). Two implementations produced independently:

- **Path A — Claude-only**: Claude orchestrator dispatched a Claude `Agent` (general-purpose) implementer with the spec as the prompt. Standard SDD pattern, no GLM.
- **Path B — Claude + GLM**: Same orchestrator dispatched `bash scripts/glm-subagent.sh < packet.md` with the spec wrapped in a `glm_task_packet`. GLM-4.6 subprocess via Z.AI's Anthropic-compatible endpoint; same Claude Code harness behind it, different model in front.

Both paths ran in `/tmp/glm-exp/path-{a,b}/` (empty starting directories). Both produced two files: `count-by-category` (the CLI) and `count-by-category.test.sh` (the test harness with three named cases).

A third independent Claude `Agent` was then dispatched as a **blind scorer** — given the two implementations labeled "Implementation 1" and "Implementation 2" with no model attribution, scored on a 5-dimension rubric, picked a winner.

## The task spec (verbatim from `/tmp/glm-exp/SPEC.md`)

Build `count-by-category`, a bash CLI that:
- Reads a CSV file with a header row (`--input <file>`)
- Groups rows by a named column (`--column <name>`)
- Emits tab-separated `category<TAB>count` lines, sorted by count desc (ties broken by category asc)
- Handles `--help` and `--version` flags
- Returns exit codes 0/1/2/3 for valid/missing-input/missing-column/column-not-in-header
- Pure bash + awk + sort, no new deps, `set -euo pipefail`

Plus a test harness `count-by-category.test.sh` with three named cases:
- `test_empty_csv` — header only
- `test_single_category` — 3 rows same category
- `test_multiple_categories` — 6 rows across 3 categories with counts 3/2/1

Acceptance: `bash -n` clean on both files; `./count-by-category.test.sh` exits 0 with all PASS.

## Measurements

### Wall-clock per dispatch

| Path | Wall-clock |
|---|---|
| **A (Claude Agent)** | 185s (`duration_ms` from Agent tool result) |
| **B (glm-subagent)** | 321s (`wall_clock_ms` from `~/.local/share/glm/usage.jsonl`) |

GLM was **~1.7× slower wall-clock** for this task. Note: the orchestrator's Bash tool serialized the two dispatches (they weren't actually parallel in elapsed wall-clock); per-dispatch numbers above are apples-to-apples.

### Tokens / bytes (per the user's "no estimates" preference)

| Path | Captured |
|---|---|
| **A** | `subagent_tokens: 47,795` (exact, total of input + output across the Agent's entire tool loop) |
| **B** | `packet_bytes: 2,769`, `response_bytes: 184`, `wall_clock_ms: 321,474`, `exit_code: 0` |

**Honest comparison limitation**: Path A's `subagent_tokens` is the FULL token count across all of the Agent's internal tool turns. Path B's `packet_bytes` / `response_bytes` are ONLY the orchestrator-visible packet and final response — they exclude all of GLM's internal Read/Write/Bash tool turns inside the `claude --print` subprocess. The two numbers are not directly comparable.

If we use public list pricing:
- Claude Sonnet 4.6: $3/M input, $15/M output (assuming 80/20 split on 47,795 total ≈ $0.26 per dispatch)
- Claude Opus 4.7: $15/M input, $75/M output (same split ≈ $1.29 per dispatch)
- GLM-4.6: $0.60/M input, $2.20/M output. With actual internal token count unknown (the v0.1 wrapper doesn't capture `.usage` per the documented TODO), this is unanswerable without the v0.2 telemetry path.

### Verification results

| Check | Path A | Path B |
|---|---|---|
| `bash -n count-by-category` | clean | clean |
| `bash -n count-by-category.test.sh` | clean | clean |
| Self test (`./count-by-category.test.sh`) | 3/3 PASS | 3/3 PASS |
| Cross test (A's harness vs B's CLI) | — | 3/3 PASS |
| Cross test (B's harness vs A's CLI) | 3/3 PASS | — |
| Functional spot-check (real CSV input) | matches expected output | matches expected output |
| Refinement cycles needed | 0 | 0 |

Both implementations are functionally correct on the spec'd happy path AND on each other's test suites. No first-try failures.

### File size

| Path | CLI lines | Test lines | Total |
|---|---|---|---|
| A | 177 | 91 | 268 |
| B | 124 | 81 | 205 |

Path B's implementation is about 25% smaller.

### Blind quality score (5-point rubric, by independent Claude Agent)

| Dimension | Path A score | Path B score |
|---|---|---|
| Correctness of spec coverage | 5/5 | 3/5 |
| Code clarity | 5/5 | 3/5 |
| Robustness (CRLF, quoted CSV, etc.) | 5/5 | 2/5 |
| Test quality | 4/5 | 2/5 |
| Idiomatic bash | 5/5 | 2/5 |
| **TOTAL** | **24/25** | **12/25** |

**Gap size per scorer**: meaningful.

#### Specific scorer findings on Path B (worth flagging)

The scorer caught a real latent bug in Path B's test harness:

> `set -euo pipefail` + `actual_exit=$? || true` on line 27 is broken: under `set -e`, a nonzero exit from `$CBC_SCRIPT` aborts the harness before `$?` is captured (the `|| true` attaches to the assignment, not the command substitution); also redirects stderr into stdout (`2>&1` line 26), so any error message would pollute the stdout comparison; uses fixed `/tmp/cbc-test-*.csv` paths (collisions across parallel runs); doesn't trap-clean on failure.

This is exactly the class of subtle bash bug that would silently mask test failures in CI — the tests pass on the happy path but a real bug in the implementation might be quietly swallowed.

The scorer also flagged Path B's:
- `gsub(/^"|"$|"/, "", val)` strips ALL internal quotes (not just leading/trailing), corrupting CSV fields with legitimate embedded quotes
- `if (val != "")` silently DROPS rows with empty category values rather than counting them as `""` — spec doesn't authorize this
- No CRLF handling (Path A explicitly strips CR)
- `IFS=, read -ra` on the header will mis-split quoted headers containing commas
- Fixed `/tmp/cbc-test-*.csv` paths cause collisions on parallel runs (Path A uses `mktemp -d` with a trap)
- `--input=val` form (single-arg with embedded `=`) not supported in Path B

#### What Path B did better

- More concise CLI (~70% the size of Path A's)
- `((var++)) || true` — GLM identified and worked around the bash gotcha that `((var++))` returns 1 when `var=0`, which would abort under `set -e`. That's a genuine catch.
- Sort syntax (`sort -k2,2rn -k1,1`) is compact and correct.

## Interpretation

**On THIS task**, Path A wins cleanly on quality (24/25 vs 12/25 — half), is faster wall-clock (185s vs 321s), and produces a more spec-complete implementation. Path B was meaningfully worse despite both passing the same acceptance gate.

**This is one data point on one task.** Important caveats:

1. **n=1 is anecdote, not signal.** Repeat on 3-5 tasks of varied complexity before claiming a trend.
2. **Task class matters.** This task was design-light, implementation-heavy with non-trivial edge cases (CSV parsing, error paths, sort semantics). GLM appears weaker on the "tasteful defensive engineering" axis. A pure transcription task (e.g., the home restructure illustration components that we serialized through Claude when we should have parallelized through GLM) would likely show different numbers.
3. **The token comparison is asymmetric and unfair to GLM.** We captured Claude's full tool-loop token count (47,795) but only GLM's external packet/response bytes (2,769 / 184). GLM's actual internal token consumption is unknown and possibly much higher.
4. **The quality-cost trade-off can't be computed precisely** without resolving #3. If GLM's actual tokens were similar magnitude to Claude's, the ~25× public-pricing differential means GLM is still cheaper per dollar even when meaningfully worse — and the right move is to use it where 12/25-quality output is acceptable (e.g., scaffolding that the orchestrator will heavily review).

## What to do with this

**Short term** (no glm-cli changes required):
- The dual-model workflow is not free quality. Continue routing GLM only to tasks where the orchestrator's review-after-commit gate is strong enough to catch the kind of latent bugs the scorer found here.
- The `set -e + actual_exit=$? || true` bug pattern in Path B is a generalizable risk. Add to `.claude/glm-conventions.md` for any project that GLM writes bash test harnesses for.

**Medium term** (glm-cli v0.2 candidates):
- F1 v2: extend `glm-subagent` with a sidecar direct-API call to capture real `.usage` data, OR document that this will never be possible through `claude --print` and accept the proxy permanently.
- Add a "quality gate" stage to the SDD/glm-fan integration: before accepting a GLM commit, run a blind-scorer pass against the spec. If quality < threshold, kick back to the orchestrator.
- Re-run this experiment on a true transcription task (e.g., a single audience-illustration redraft from the Wave 3 punch list) to test the "task class matters" hypothesis.

**Long term**:
- n=5 cross-task experiment: same harness, 5 tasks of varied complexity (transcription / refactor / new-feature / test-scaffold / one harder design task). Produces a defensible per-task-class routing matrix.

## Raw artifacts

- Spec: `/tmp/glm-exp/SPEC.md` (scratched; reproduced inline above)
- Path A implementation: `/tmp/glm-exp/path-a/` (scratched; preserved in `path-a-implementation/` below for review)
- Path B implementation: `/tmp/glm-exp/path-b/` (scratched; preserved in `path-b-implementation/` below for review)
- Path A report: `/tmp/glm-exp/path-a-report.md`
- Telemetry line for Path B: `~/.local/share/glm/usage.jsonl` (newest entry as of 2026-06-20T15:53:04Z)

The implementation files are checked into this experiments directory under `path-a-implementation/` and `path-b-implementation/` for permanent reference.
