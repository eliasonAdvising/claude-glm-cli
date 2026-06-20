---
date: 2026-06-20
experiment: claude-vs-claude-plus-glm — n=5 cross-task synthesis
tasks: 5 (transcription, test-scaffold, refactor, bug-fix, design-impl)
status: completed
verdict: GLM 111/125; Claude 122/125; ~9% aggregate quality gap. Wall-clock — GLM 2.7× faster serialized. Task class is the dominant variable. Three tasks tie within 1 point; one task is a tie; one task (transcription validator) shows a meaningful gap; one task (design CLI harness) shows a large gap.
---

# Side-by-side experiment #3 — n=5 cross-task synthesis

## Premise

Two prior n=1 experiments (`2026-06-20-glm-vs-claude.md` for bash CSV CLI, `2026-06-20-glm-vs-claude-transcription.md` for CHANGELOG) plus a production wave (Wave 3 audience illustrations) suggested a routing matrix but explicitly noted: "n=2 formal + production data is enough to draw the routing matrix above but not to defend it under scrutiny — n=5 across varied task classes would."

This is that n=5. Five task classes, two independent implementations per task (Claude Agent vs `glm-subagent`), one blind scorer per task using a class-specific 5-dimension rubric.

## Tasks

Designed to span the routing-matrix dimensions:

| Task | Class | Spec precision |
|---|---|---|
| **T1** — Build `endpoints.json` from a structured spec + a `validate.sh` (10 named checks) | Pure transcription | Maximally precise |
| **T2** — Write 7 named Vitest-shaped tests for a provided `parseDuration` function | Test scaffold | Spec dictates test names + cases |
| **T3** — Refactor `formatAccount` into 3 named helpers, preserve public API | Mechanical refactor | Signatures dictated; helper internals open |
| **T4** — Diagnose + fix a `pluralize(1, "knife") === "knives"` bug with 6 test cases | Bug fix from clear repro | Bug located by failing test |
| **T5** — Build a `slugify.mjs` CLI + bash test harness with 5 named tests | Design-judgment implementation | 7 rules listed; Unicode/edge handling open |

Each task pre-staged any input artifacts (the existing function under test for T2/T3/T4) so both paths had identical starting points.

## Method

For each task:
1. Author SPEC.md (and any input files)
2. Dispatch Path A (Claude Agent) and Path B (glm-subagent via Agent monitor) — both received the same SPEC, both worked in isolated `/tmp/glm-exp-3/<task>/path-{a,b}/` dirs
3. Both implementations verified independently against the spec's acceptance test
4. Dispatch a blind Claude Agent scorer with both implementations labeled `Implementation 1` / `Implementation 2` (no model attribution) and a task-class-specific 5-dimension rubric
5. Unmask after scoring

**All 10 implementations passed their own acceptance tests.** Functional correctness was a tie across the board. The scoring is about quality.

## Per-task results

### T1 — Transcription (build endpoints.json + validate.sh)

| | Claude (Path A) | GLM (Path B) |
|---|---|---|
| Wall-clock | 319s | **46s** (GLM 6.9× faster) |
| Validator pass | 10/10 | 10/10 |
| **Score** | **25/25** | **20/25** |
| Gap | — | **meaningful** |

**Scorer's verdict:** *"Both produce identical correct JSON, but Implementation 2's validator has a class of bug that defeats its purpose — checks 8, 9, and 10 don't compare jq output; they just rely on jq exiting 0 whether the predicate is true or false. If `delete_user.retry_policy` were `\"aggressive\"`, check 10 would still PASS."*

GLM also had a bash syntax issue (`!jq` without space) and hardcoded an absolute path. The JSON output itself was perfect; the validator was theater.

### T2 — Test scaffold (write 7 named tests)

| | Claude | GLM |
|---|---|---|
| Wall-clock | 14s | 19s |
| Tests pass | 7/7 | 7/7 |
| **Score** | **24/25** | **25/25** |
| Gap | trivial (GLM +1) |

GLM used `assert.strictEqual` (explicit) where Claude used `assert.equal` (which under `node:assert/strict` is equivalent but reads as loose). Both implementations are functionally indistinguishable; the dimension that separates them is self-documenting precision.

### T3 — Refactor (split formatAccount into 3 helpers)

| | Claude | GLM |
|---|---|---|
| Wall-clock | 37s | 41s |
| Tests pass | 7/7 | 7/7 |
| **Score** | **25/25** | **24/25** |
| Gap | trivial (Claude +1) |

GLM used `Math.sign(balance)` which returns `0` for input `0` — same observable result here but slightly less defensive than Claude's explicit `balance < 0 ? -1 : 1`. GLM also omitted precedence parens around `sign * Math.round(...) / 100` — works but reads less clearly. Both refactors are correct.

### T4 — Bug fix (`pluralize(1, "knife")` returns "knives")

| | Claude | GLM |
|---|---|---|
| Wall-clock | 16s | 21s |
| Tests pass | 6/6 | 6/6 |
| **Score** | **25/25** | **25/25** |
| Gap | **TIE — byte-identical fix** |

Both inserted the same single line at the same position:

```diff
 export function pluralize(count, word) {
+  if (count === 1) return word;
   if (IRREGULAR[word]) return IRREGULAR[word];
```

The canonical root-cause fix. Neither chose the symptom-fix path (removing words from the IRREGULAR map). Both used `===`, both matched the file's existing style. Indistinguishable.

### T5 — Design implementation (slugify CLI)

| | Claude | GLM |
|---|---|---|
| Wall-clock | 63s | **41s** (GLM 1.5× faster) |
| Tests pass | 5/5 | 5/5 |
| **Score** | **23/25** | **17/25** |
| Gap | **large** |

**Scorer's verdict:** The `slugify` functions themselves are nearly identical. The differentiation lives in the harness.

GLM's harness:
- Truncation test claims a "70-char title" but the title is **83 chars** (silent spec drift, no length assertion guards it)
- No `set -u`, no `set -euo pipefail`
- Mixed inline-vs-helper test style (inconsistent rigor across tests)

Claude's harness:
- `test_truncation` *asserts the fixture is exactly 70 chars before running* — exactly the discipline that catches drift
- `set -u`
- All tests through named helper functions with structured `report_pass` / `report_fail`
- Resolves `SCRIPT_DIR` so the harness runs from any CWD

This is the same class of issue we saw in experiment #1 — bash testing harnesses where GLM passes its own validator without enforcing what the validator claims to enforce. Repeatable failure mode.

## Aggregate

| | Claude | GLM | Delta |
|---|---|---|---|
| Total score | **122/125** | **111/125** | Claude +11 (8.8%) |
| Total wall-clock (serialized) | 449s | **168s** | GLM 2.7× faster |
| Tasks where Claude wins | 3 (T1 meaningful, T3 trivial, T5 large) | | |
| Tasks where GLM wins | 1 (T2 trivial) | | |
| Tasks tied | 1 (T4 byte-identical) | | |
| Tasks within 1 point | T2, T3, T4 (3 of 5) | | |

## The pattern that holds across all three experiments

Plotting all data points:

| | Spec precision | Quality delta | Wall-clock advantage |
|---|---|---|---|
| Bug fix (T4) | High (failing test points at the line) | **TIE** | Claude minor |
| Test scaffold (T2) | High (names + cases dictated) | **GLM +1** | Claude minor |
| Refactor (T3) | High (signatures dictated) | **Claude +1** | Claude minor |
| Transcription main (CHANGELOG, T1 endpoints.json) | High (exact strings) | **Primary byte-identical**, validator weak | **GLM 7-39×** |
| Concept-described (Wave 3 illustrations) | Medium (concept + register + tokens) | GLM acceptable with reviewer-fix loop | GLM 4.2× |
| Design-impl with edge cases (T5 slugify, exp#1 CSV CLI) | Medium-low (rules listed, choices open) | **Claude wins meaningfully or large** | Mixed |

**Three tight findings:**

1. **GLM is at-parity-or-better on tightly-bounded mechanical tasks** (refactor, bug fix, test scaffold, transcription's primary artifact). Three of five tasks at n=5 land within 1 point in either direction; one is byte-identical.

2. **GLM struggles with auxiliary bash/test harnesses** — the same failure mode showed up in 3 of 3 tasks that asked for a bash validator/harness: experiment #1, experiment #2, and T1 of this n=5. The harness passes its own checks but doesn't actually enforce the spec. This is a *category* failure, not random.

3. **GLM wins wall-clock for transcription dramatically (7×)** and ties or wins narrowly elsewhere. Net: GLM is faster for serialized work, and `glm-fan` lets parallel-eligible mechanical work compound that win.

## Failure-mode taxonomy (from all three experiments)

GLM-specific failures, categorized:

| Pattern | Where seen | Risk |
|---|---|---|
| Bash test harness with non-enforcing predicate | exp#1 (`set -e + $?` race), exp#2 (`tail -c 1`), n=5 T1 (`jq` predicate exit code), n=5 T5 (no `set -u`, drifted fixture) | High — passes own validator, hides real bugs |
| v0.1 banned tokens (project conventions gap) | Wave 3 (used `--color-brand-teal-dark`) | Medium — caught by reviewer, but recurring if conventions file is incomplete |
| Light/dark token misuse on dark panels | Wave 3 (3 invisible merchant rows) | Medium — caught by browse verification |
| Less-defensive JavaScript expressions | n=5 T3 (`Math.sign(0) === 0` semantics, missing precedence parens) | Low — semantically equivalent, just less readable |
| Slight over-restraint on edge cases | n=5 T5 (no `set -u`, no extras like `-h` alias) | Low-medium — depends on context |

**Failure modes NOT observed in GLM** (worth noting — these would be common AI-dispatch concerns):
- Hallucinating file contents
- Modifying files outside `relevant_files`
- "Fixing" things that weren't broken (the sparkline z-order misdiagnosis in Wave 3 → GLM correctly reported no-op)
- Adding unrelated features
- Breaking the public API of a refactored function
- Producing JSON that doesn't parse
- Producing bash that doesn't run

## Routing matrix — n=5-supported version

Promoting confidence levels based on the new data:

| Task class | Default route | Confidence | Evidence |
|---|---|---|---|
| Verbatim transcription (primary artifact) | **GLM** | **High** | Byte-identical at n=2 (exp#2, T1 JSON); 7-39× wall-clock |
| Verbatim transcription (auxiliary validator/harness) | **Claude** OR review-after-GLM | **High** | 4/4 GLM auxiliary harnesses had non-enforcing predicate bug |
| Test scaffold | **GLM** | **High (new)** | n=5 T2 tied; ~equal wall-clock |
| Mechanical refactor with named contract | **GLM** | **High (new)** | n=5 T3 within 1 point; ~equal wall-clock |
| Bug fix from clear repro | **GLM** | **High (new)** | n=5 T4 byte-identical; canonical fix |
| Concept-described UI (illustrations) | **GLM (via glm-fan)** | **Medium-high** | Wave 3 production data + reviewer loop catches issues |
| Design-judgment implementation (CSV CLI, slugify) | **Claude Agent** | **High** | n=2 (exp#1 + T5); GLM ships latent bugs |
| Copy/voice writing | **Claude Agent** | High | Project memory rule; not experimentally tested |
| Multi-perspective review / scoring | **Claude Agent** | High | Judgment work |
| Architecture / scope decisions | **Claude (orchestrator)** | High | Project memory rule |

**The big upgrade from prior matrix:** Test scaffold, refactor, bug fix — three task classes promoted from "Medium / Untested" to "High" confidence on the basis of n=5 ties/wins for GLM.

**The big sharpening:** "GLM for bash harnesses" is now a specific anti-pattern. When the deliverable includes a bash validator/test runner with its own pass/fail logic, route the harness review to Claude even if the primary artifact ships through GLM.

## Wall-clock and cost shape

| | Claude | GLM |
|---|---|---|
| n=5 total dispatches | 5 | 5 |
| n=5 total wall-clock (serial) | 449s | 168s |
| n=5 avg per dispatch | 90s | 34s |
| Tokens per dispatch (avg) | ~43k subagent_tokens (exact) | bytes proxy only (`packet_bytes ~3.5k`, `response_bytes ~250`) |

**The token comparison remains asymmetric** — Claude's count is the full Agent tool loop; GLM's is only orchestrator-visible packet/response. v0.2 wrapper telemetry (sidecar API call to capture `.usage`) remains the priority that would unlock a real $ cost comparison.

If GLM's internal tokens are roughly similar magnitude to Claude's (~45k per dispatch — plausible based on similar work shape), then at Z.AI list pricing:
- 5 GLM dispatches: ~225k tokens × $1.40/M blended ≈ $0.32
- 5 Claude dispatches: ~215k tokens × $11/M blended (Sonnet) ≈ $2.36

→ **~7-8× $ savings on GLM if the internal-token assumption holds.** Unverifiable until v0.2.

## What this experiment did NOT cover

- Multi-file changes (everything here was single-file)
- Long-running iteration (we did n=1 dispatch per task, no refinement cycles measured here)
- Tasks where the spec is ambiguous on purpose
- Live integration testing (these were all isolated /tmp directories)
- Cross-task contamination — would GLM perform differently if given 5 tasks in one bundled packet vs 5 separate dispatches?

These remain open questions. The n=5 closes the "single-task-class anecdote" objection but opens the next round of unknowables.

## Recommendation

**Ship F1 v2 (real GLM token capture) before the next experiment.** Every iteration of this work has hit the same wall: we can compare wall-clock and quality precisely, but not $ cost. With token-level data, the routing matrix above could be re-derived on the dimension that actually matters for "should we use GLM here" — cost per quality-point — instead of needing the wall-clock-plus-quality two-step.

In the meantime, the matrix above is the n=5-supported default. Apply it.

## Raw artifacts

All 5 task specs + both implementations preserved at:

```
docs/experiments/n5/
├── T1-transcription/
│   ├── SPEC.md
│   ├── path-a/ (Claude)
│   └── path-b/ (GLM)
├── T2-test-scaffold/
├── T3-refactor/
├── T4-bug-fix/
└── T5-design-impl/
```

Anyone reading the repo can re-run any single scorer and re-derive the verdict.
