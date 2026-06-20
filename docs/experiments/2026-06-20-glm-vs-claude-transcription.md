---
date: 2026-06-20
experiment: claude-only-vs-claude-plus-glm
task: transcribe 5 structured release entries into CHANGELOG.md + write a validator
n: 1 (second data point; combined with the first experiment, n=2 across task classes)
status: completed
verdict: GLM produced byte-identical primary output; lost 4/25 quality points only on validator robustness. Wall-clock favored GLM by ~39×. Hypothesis "task class matters" confirmed.
---

# Side-by-side experiment #2: transcription task

## Question

Companion to `2026-06-20-glm-vs-claude.md`. That experiment showed Claude winning a design-heavy bash CLI task by a meaningful gap (24/25 vs 12/25). The report's interpretation section hypothesized: **task class matters; GLM might do well on transcription work.** This experiment tests that hypothesis.

## Design

Same harness shape as experiment #1: one spec, two paths, blind scorer, n=1.

The task this time is **transcription** — the spec dictates the exact content (intro paragraph verbatim, five structured release entries with exact descriptions, style rules enumerated). The implementer's job is to mechanically convert structured input into formatted output, not to make design decisions.

- **Path A — Claude-only**: Claude orchestrator → Claude Agent (general-purpose) implementer.
- **Path B — Claude + GLM**: Same orchestrator → `glm-subagent` (GLM-4.6 via Z.AI Anthropic-compat endpoint).
- **Same spec, same acceptance test, same blind scorer rubric** (5 dimensions × 5 points).

Both implementers built two files in their respective scratch dirs (`/tmp/glm-exp-2/path-{a,b}/`):
- `CHANGELOG.md` — five release entries formatted per spec
- `validate.sh` — a 10-check validator with PASS/FAIL output

## The spec (excerpted from `/tmp/glm-exp-2/SPEC.md`)

Build a `CHANGELOG.md` with:
- `# Changelog` heading
- Verbatim intro paragraph
- Five `## [VERSION] — YYYY-MM-DD` entries (em-dash, not hyphen), newest first
- Type group headers (`### Features`, `### Fixes`, `### Refactoring`, `### Documentation`, `### Breaking changes`)
- Bullets formatted as `- **scope:** description.`
- Style rules: no exclamations, no contractions, no first-person, em-dashes throughout, periods on every bullet, single trailing newline

Plus a `validate.sh` with 10 specific automated checks covering each style rule and structural requirement.

The five release entries were enumerated verbatim in the spec (version, date, type, scope, description, breaking flag).

## Results

### Wall-clock per dispatch

| Path | Wall-clock |
|---|---|
| **A (Claude Agent)** | **1,131s** (18.8 min — `duration_ms` from Agent tool result) |
| **B (glm-subagent)** | **29s** (`wall_clock_ms` from `~/.local/share/glm/usage.jsonl`) |

**Path B was ~39× faster wall-clock.** The 1,131s for Path A is meaningfully higher than experiment #1's 185s for a comparably-complex task; possible explanations include API latency variance, prompt-cache misses, or queue time during the dispatch window. The token count (see below) suggests the Agent did roughly the same amount of work as in experiment #1, so the wall-clock variance is unlikely to be all on the Agent.

### Tokens / bytes

| Path | Captured |
|---|---|
| **A** | `subagent_tokens: 46,585` (exact, full tool loop) |
| **B** | `packet_bytes: 2,814`, `response_bytes: 51`, `wall_clock_ms: 28,637`, `exit_code: 0` |

Same caveat as experiment #1: Path A's token count is the full Agent tool loop; Path B's bytes are only orchestrator-visible (packet sent, final response received). GLM's internal token consumption is unknown and remains the v0.2 telemetry TODO.

### Verification

| Check | Path A | Path B |
|---|---|---|
| `bash -n validate.sh` | clean | clean |
| `./validate.sh` self-test | 10/10 PASS | 10/10 PASS |
| Cross test (A's validator vs B's CHANGELOG) | — | 10/10 PASS |
| Cross test (B's validator vs A's CHANGELOG) | 10/10 PASS | — |
| Refinement cycles needed | 0 | 0 |

### File sizes

| Path | CHANGELOG lines | validator lines | Total |
|---|---|---|---|
| A | 37 | 127 | 164 |
| B | 37 | 37 | 74 |

Path A's validator is ~3.4× longer than Path B's — more thorough, with comments and per-check helper functions.

### The dramatic finding: byte-identical CHANGELOGs

```
$ diff /tmp/glm-exp-2/path-a/CHANGELOG.md /tmp/glm-exp-2/path-b/CHANGELOG.md
(no output — files are byte-identical)
```

Both implementers produced the **exact same CHANGELOG.md.** When the spec is precise enough, both Claude and GLM converge on the same output. This is the cleanest possible signal that transcription is where GLM holds its own.

### Blind quality score

| Dimension | Path A | Path B |
|---|---|---|
| Spec fidelity (CHANGELOG) | 5/5 | 5/5 |
| Style-rule compliance | 5/5 | 5/5 |
| Validator quality | 5/5 | **3/5** |
| Restraint | 5/5 | 5/5 |
| Polish | 5/5 | **3/5** |
| **TOTAL** | **25/25** | **21/25** |

**Gap size per scorer**: small (vs experiment #1's "meaningful").

#### What the scorer found

**Both CHANGELOGs were perfect.** All four lost points are in `validate.sh`.

**Specific Path B weaknesses:**
- Check 10 uses `tail -c 1 $CHANGELOG | wc -l` to verify "single trailing newline." This returns 1 if the last byte is `\n` but **cannot distinguish "one newline" from "two or more newlines"** — exactly the false-negative the spec explicitly called out. Path A used `od -An -c` to byte-check both the last and penultimate bytes, which actually enforces the rule.
- `eval`-based dispatcher (line 9) — compact but sacrifices clarity and quoting safety.
- Most invocations of `$CHANGELOG` aren't quoted — would break on filenames with spaces.
- No `set -euo pipefail`.
- The interpolated `got $(grep -c ...)` in pass-message arguments evaluates subprocess calls even on PASS, doubling work.

**Notable Path A strengths:**
- `od -An -c` byte-level newline check that actually enforces the spec.
- Per-check pass/fail helpers with line numbers in failure messages.
- `set -u` and proper quoting throughout.

## Interpretation

**For THIS task class** (precise transcription with enumerated content): GLM is functionally equivalent to Claude on the primary artifact and only modestly worse on auxiliary tooling. Wall-clock favors GLM dramatically.

Combined with experiment #1, a pattern emerges across 2 data points:

| Task class | Quality gap | Wall-clock gap |
|---|---|---|
| **Implementation with design judgment** (bash CSV CLI) | Meaningful (24 vs 12) | Path A faster (185s vs 321s) |
| **Pure transcription** (CHANGELOG) | Small (25 vs 21) | Path B faster (29s vs 1,131s) |

The "where to route what" rule the previous experiment hinted at is sharpening:

- **Bounded transcription** (verbatim copy, enumerated content, precise spec → output mapping) → **GLM lane is the right default.** It produced byte-identical primary output 39× faster.
- **Design-loaded implementation** (CSV parsing, error path design, edge case judgment) → **Claude lane.** GLM ships latent bugs that pass spec-defined tests but would burn you later.
- **Auxiliary tooling** (validators, test harnesses, scripts) → **lean Claude** when the tooling itself has edge cases (the trailing-newline check above is the canonical example).

Important caveats (carried from experiment #1):
- n=2 is still anecdote, not signal. A defensible per-task-class routing matrix needs n=5+ across varied task families.
- GLM token comparison remains asymmetric (Claude full vs GLM packet-only) — cost comparison is still unknowable without the v0.2 telemetry path.
- The 1,131s Path A wall-clock is high enough to warrant investigation — likely external factors (cache miss, API queue) rather than Agent work. Re-running experiment #1 against the same window would help isolate.

## What to do with this (cross-referenced with experiment #1)

**Short term**:
- **Update the CLAUDE.md / `.claude/glm-conventions.md` routing guidance**: explicit "transcription = GLM lane default" with the byte-identical-CHANGELOG result as the cite.
- Re-route the Wave 3 audience illustration redrafts to GLM. The graphic designer's concept descriptions are precise enough that they're functionally transcription, and serializing them through Claude is exactly the cost we now have data to avoid.
- Add a quality-gate note to glm-task SKILL.md: "for GLM-generated bash scripts that include their own validators, the validator must be reviewed for false-negative risk."

**Medium term** (glm-cli v0.2):
- F1 v2 to capture real GLM tokens, finally unlocking a precise cost comparison.
- An n=5 cross-task experiment with the harness (transcribe markdown, refactor existing code, write tests, write a CLI, redraft an illustration) to firm up the routing matrix.

**Long term**:
- Build the routing decision into the SDD task-list templating: at writing-plans time, classify each task as `transcription | design | hybrid` and pre-route. Make the cold decision once, in advance, with empirical defaults.

## Raw artifacts

- Spec: `/tmp/glm-exp-2/SPEC.md` (scratched during run; can be regenerated from this report's spec section)
- Path A files preserved at `path-a-implementation/` below
- Path B files preserved at `path-b-implementation/` below
- Telemetry line for Path B: `~/.local/share/glm/usage.jsonl` (timestamp `2026-06-20T16:24:03+00:00`)
- Diff of the two CHANGELOG.md files: empty (byte-identical)
