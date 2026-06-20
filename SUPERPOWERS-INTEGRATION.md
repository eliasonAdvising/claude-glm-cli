# SUPERPOWERS-INTEGRATION — routing GLM-eligible work from superpowers workflows

## Why this doc exists

Documented routing rules don't enforce themselves. When a superpowers workflow (subagent-driven-development, executing-plans, writing-plans) dispatches implementers, the default implementer-prompt template maps directly to a Claude `Agent` tool call. Switching mid-flow to GLM requires rewriting the dispatch shape (`bash glm-subagent` with packet on stdin) — different wrapper, same brief. In practice, orchestrators drift into Claude dispatch even for tasks the plan explicitly flagged as GLM territory because the routing decision per task is high-friction when already moving fast.

The fix: pre-commit a route per task at task-list time, not per-task once mid-flow. This doc teaches that lane-labeling pattern and shows the dispatch-shape translation for each lane.

## The mental model

When a superpowers workflow dispatches an implementer (subagent-driven-development's implementer-prompt.md, executing-plans' task dispatcher), three implementer lanes exist. Choose at task-list creation time, not mid-flight.

| Implementer lane | When to use | Mechanism |
|---|---|---|
| Claude `Agent` tool | Judgment, multi-file integration, design, copy/voice, security-sensitive paths | `Agent({subagent_type: "general-purpose", prompt: "<implementer-brief>"})` |
| `bash glm-subagent` (single) | One bounded mechanical task per CLAUDE-MD §12 eligibility checklist (mechanical, known scope, verifiable) | `glm-subagent <<'PACKET'\n<glm_task_packet>...\nPACKET` |
| `glm-fan` (Agent → GLM, N in parallel) | ≥3 independent mechanical tasks, file-conflict-safe | Fire N Agents in one turn; each Agent owns one glm-subagent subprocess |

**Decision matrix:** If the task needs Claude-quality judgment or will be owner-facing → Agent lane. If mechanical and GLM-eligible → check parallelism: 1-2 tasks → glm-subagent; ≥3 tasks on different files → glm-fan.

## At task-list time, label every task with its lane

When transitioning from writing-plans to subagent-driven-development (or executing-plans), annotate each task with its dispatch lane *before* firing any implementer. The decision happens once, cold.

**Lane labels:**
- `[lane: Agent]` — Claude `Agent` tool (judgment, copy, design, security-gated files per §7)
- `[lane: glm]` — Single `glm-subagent` dispatch (mechanical, bounded, GLM-eligible per eligibility checklist)
- `[lane: glm-fan/group-X]` — Parallel fan-out; group-X identifies tasks that can run in parallel (same group tag = safe to parallelize)

**Worked annotation example** (hypothetical 8-task plan):

```
1. [lane: glm-fan/group-A] Add Vitest scaffolds for src/lib/utils.ts
2. [lane: Agent] Update homepage hero copy per owner feedback
3. [lane: Agent] Design new mega-menu IA
4. [lane: glm-fan/group-A] Fix lint errors in src/components/Button.tsx
5. [lane: Agent] Refactor auth flow (multi-file integration)
6. [lane: glm-fan/group-A] Add error-summary alert to Contact form
7. [lane: Agent] Review security implications of new CSP header
8. [lane: glm-fan/group-A] Rename isUserLoggedIn → isAuthenticated across 3 files
```

Tasks 1, 4, 6, 8 can fire as glm-fan in one orchestrator turn. Tasks 2, 3, 5, 7 run sequentially on Agent. The decision is made before any dispatch fires.

## The dispatch wrapper for SDD

When subagent-driven-development's process says "Dispatch implementer subagent (implementer-prompt.md)" and the task's lane is GLM, the implementer dispatch shape changes but the brief content stays the same.

**For `[lane: glm]` tasks:**

Instead of:
```
Agent({subagent_type: "general-purpose", prompt: "<implementer-brief from implementer-prompt.md>"})
```

Dispatch:
```bash
glm-subagent <<'PACKET'
<glm_task_packet>
Task:
<Sentence from implementer-brief's "Your task" section>

Why this matters:
<Brief from implementer-brief's context>

Context:
<Minimum background from implementer-brief>

Relevant files:
- <files listed in implementer-brief>

Inputs available:
- <constraints, APIs, test commands from implementer-brief>

Constraints:
- Do not change [anything outside scope]
- Preserve existing behavior
- If ambiguous, stop and escalate

Expected output:
- <Code, tests, or patch per implementer-brief>

Success criteria:
- <Named tests or commands from implementer-brief>

Verification steps:
- <Commands from implementer-brief>

Stop conditions:
- Stop when success criteria are met
- Escalate if unclear after 3 attempts

Do not change:
- <Protected files/interfaces from implementer-brief>

Notes for the GLM sub-agent:
- You are the executor. Edit files directly.
- Run verification commands yourself.
- Return a one-line summary.
</glm_task_packet>
PACKET
```

**The reviewer pass (task-reviewer-prompt.md) stays on Claude** — reviewers are judgment work, always the Agent lane.

## The fan-out pattern for parallel-eligible groups

When ≥3 tasks share the same `glm-fan/group-X` tag, the orchestrator fires N Agents in one turn. Each Agent owns one glm-subagent subprocess for one task. See `glm-fan` skill SKILL.md for the Agent prompt template — the template handles monitoring, retry, and DONE/BLOCKED reporting.

**Dispatch shape for glm-fan:**

```
Orchestrator (Claude)
  → Agent 1 (general-purpose, fan-out)
     → Bash → glm-subagent → GLM subprocess (Task 1)
     → Agent monitors stdout, checks git log -1, reports summary
  → Agent 2 (parallel in same orchestrator turn)
     → Bash → glm-subagent → GLM subprocess (Task 2)
     → ...
  → Agent N
     → ...
  → Orchestrator synthesizes Agent summaries
```

Wall-clock for N tasks = max(single task duration), not sum(serial durations).

**Key safety rule:** Tasks in a glm-fan group MUST touch different files. Write conflicts = race condition. Group tasks by file-ownership, not just by "looks mechanical."

## Telemetry checkpoint

At the end of a superpowers workflow, run:

```bash
glm-usage --last 24h
```

Append a one-line summary to the `LEARNINGS.md` file that subagent-driven-development already maintains:

```
- 2026-MM-DD: <workflow-name> — <GLM-tasks-ran> tasks via glm-subagent / <Agent-tasks-ran> via Agent; <wall-clock-minutes> total; <success-rate>% GLM first-pass success; common failure: <one-phrase>
```

This closes the empirical-data loop. Track token spend per lane, success rate, and common BLOCKED reasons. The data informs future lane-labeling decisions.

## One pitfall

The SDD skill's "no parallel implementers" rule (from its source text: *"Never: dispatch multiple implementation subagents in parallel (conflicts)"*) is about file-conflict prevention. It does NOT apply when each implementer touches a different file.

**The exception:** Parallel-fan is safe when tasks operate on disjoint file sets. Tagging tasks as `[lane: glm-fan/group-A]` signals "these tasks are file-conflict-safe and can run in parallel." The SDD serial constraint applies within-file, not across-files.

Don't let the "never parallel" rule bleed into parallel-safe cases. The rule is: parallel tasks → different files. Not: parallel tasks → never.

## One worked example

**Writing-plans output** (hypothetical 8 tasks from a design spec):

1. Create `src/components/audiences/agents.tsx` — verbatim from brief B.1
2. Create `src/components/audiences/entrepreneurs.tsx` — verbatim from brief B.2
3. Create `src/components/audiences/nonprofits.tsx` — verbatim from brief B.3
4. Create `src/components/audiences/sales-partners.tsx` — verbatim from brief B.4
5. Create `src/components/audiences/marketers.tsx` — verbatim from brief B.5
6. Update `src/pages/our-mission.astro` — integrate new audience sections into existing page
7. Refactor header mega-menu — restructure IA for new audiences
8. Update homepage copy per owner feedback — voice judgment call

**Lane labeling at task-list time:**

```
1. [lane: glm-fan/group-illustrations] Create src/components/audiences/agents.tsx — verbatim B.1
2. [lane: glm-fan/group-illustrations] Create src/components/audiences/entrepreneurs.tsx — verbatim B.2
3. [lane: glm-fan/group-illustrations] Create src/components/audiences/nonprofits.tsx — verbatim B.3
4. [lane: glm-fan/group-illustrations] Create src/components/audiences/sales-partners.tsx — verbatim B.4
5. [lane: glm-fan/group-illustrations] Create src/components/audiences/marketers.tsx — verbatim B.5
6. [lane: Agent] Update src/pages/our-mission.astro — integrate audiences (multi-file, §7-gated)
7. [lane: Agent] Refactor header mega-menu — IA work, design judgment
8. [lane: Agent] Update homepage copy — voice judgment, owner-facing
```

**Dispatch sequence:**

1. **Orchestrator fires 5 Agents in one turn** (Tasks 1-5, glm-fan/group-illustrations). Each Agent owns one glm-subagent subprocess for one `.tsx` file. Packets are verbatim-transcription briefs with `npm run typecheck && lint` as success criteria.
2. **~1 wall-clock minute later**, all 5 Agents report DONE. Orchestrator commits the batch.
3. **Sequential Agent dispatches** for Tasks 6, 7, 8 (each is judgment work, §7-gated, or voice-sensitive). One at a time, per SDD's serial rule for Agent-lane work.
4. **Reviewer pass** (always Agent lane) verifies all 8 tasks against the original plan.

**Without lane labeling:** The orchestrator might fire all 8 tasks via Agent (default SDD rhythm) — 10+ minutes wall-clock, higher token cost. With lane labeling: ~1 minute for the 5 illustrations (parallel GLM) + ~2 minutes for the 3 Agent tasks = ~3 minutes total, lower cost.
