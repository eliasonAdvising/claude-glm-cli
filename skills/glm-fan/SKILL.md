---
name: glm-fan
description: Dispatch N parallel-eligible bounded GLM tasks via N Claude Agents (each Agent owns one glm-subagent subprocess). Wall-clock = slowest single task, not sum. Use when ≥3 independent mechanical tasks need parallel execution.
---

# glm-fan — parallel Agent → GLM dispatch

The **parallel-Agent → GLM** lane: an orchestrator Claude session dispatches N general-purpose Agents in one turn; each Agent owns one GLM subprocess via `glm-subagent`, monitors the result, optionally retries with a refined packet, runs a quick post-flight check, and reports DONE/BLOCKED back. The orchestrator synthesizes Agent summaries.

**Wall-clock for N tasks = max(tasks), not sum(tasks).**

## Dispatch shape

```
Orchestrator (Claude)
  → Agent (general-purpose, fan-out — N in one orchestrator turn)
     → Bash (inside the Agent's harness) → glm-subagent
        → GLM subprocess returns to its Agent
     → Agent monitors stdout, checks git log -1, optionally retries with refined packet
     → Agent reports DONE/BLOCKED summary to orchestrator
  → Orchestrator synthesizes Agent summaries
```

Each Agent gets its own GLM subprocess. Independent files = safe.

## When to use

Use `glm-fan` when **all** of these are true:

- **≥3 parallel-eligible GLM tasks** (otherwise single dispatch is faster — no Agent overhead)
- Each task is GLM-eligible per `glm-task` criteria (mechanical, known scope, verifiable)
- Tasks touch **different files** (avoid write conflicts)
- Success criteria are clear (typecheck, lint, named test)

**Perfect use cases:**
- 5 illustration components from a design spec
- 8 lint-fix sweeps across different modules
- N test-scaffold additions for pure functions

**Cost shape:**
- Agent token cost: ~5k tokens per Agent for orchestration overhead
- GLM token cost: the actual work (e.g., ~5k tokens for a mechanical refactor)
- Wall-clock win: 5 tasks serialized ≈ 10 minutes; 5 tasks parallel ≈ 1 minute

When N < 3, use direct `glm-task` instead — Agent overhead exceeds parallelism benefit.

## Agent prompt template

Each Agent receives:

```
You are a GLM task monitor. Your job:

1. Receive this GLM packet (below). Fire it via:
   glm-subagent <<'PACKET'
   <packet>
   PACKET

2. Monitor the stdout. Look for:
   - Final "DONE: ..." line = success
   - "STOP:" / empty / truncated = escalation
   - Anything else = check git log -1 to verify

3. If escalation: retry ONCE with a refined packet (add clarity from the error). If that fails, report BLOCKED.

4. Post-flight check: run <verification-command> or git log -1 to confirm expected change landed.

5. Report back in this exact format:
   DONE: <one-line summary>
   or
   BLOCKED: <what failed and why>

Your packet:
<glm_task_packet>
Task:
...
</glm_task_packet>
```

The orchestrator fires N Agents in parallel via multiple Agent tool calls in one turn.

## Worked example — 5 illustration components

**Orchestrator dispatches 5 Agents in one turn:**

```
Agent 1: "Monitor GLM task for src/components/audiences/agents.tsx — verbatim transcription from brief B.1"
Agent 2: "Monitor GLM task for src/components/audiences/entrepreneurs.tsx — verbatim from brief B.2"
Agent 3: "Monitor GLM task for src/components/audiences/nonprofits.tsx — verbatim from brief B.3"
Agent 4: "Monitor GLM task for src/components/audiences/sales-partners.tsx — verbatim from brief B.4"
Agent 5: "Monitor GLM task for src/components/audiences/marketers.tsx — verbatim from brief B.5"
```

Each Agent's packet contains:
- Relevant files: the one `.tsx` file
- Task: "Create this component per the attached brief (verbatim)"
- Success criteria: `npm run typecheck && npm run lint --max-warnings=0`
- Stop conditions: "Stop when typecheck + lint pass"

**~1 minute wall-clock later**, all 5 Agents report DONE. Orchestrator commits.

## Limitations

**File-conflict avoidance:** Parallel tasks MUST touch different files. Two GLM subprocesses writing the same file = race condition. If you have N tasks that overlap files, serialize them or batch by file.

**No auto-retry in v0.1:** If any Agent reports BLOCKED, the orchestrator decides per-Agent how to recover (refine packet, escalate to Claude, do it directly). There's no automatic second-pass loop yet.

**Agent overhead:** Each Agent costs ~5k Claude tokens for orchestration. For 1-2 tasks, direct `glm-task` is cheaper and faster.

**Latency for serial work:** Two LLM hops (orchestrator → Agent → GLM) add latency compared to direct Bash → GLM. Only worth it for parallelism.

## Recovery path

If an Agent reports BLOCKED:

1. **Read the Agent's report** — what failed and why
2. **Decide recovery:**
   - **Refine packet:** If the failure is a clear missing constraint, author a refined packet and dispatch a new Agent for the same task
   - **Escalate to Claude:** If GLM can't handle it, dispatch a Claude Agent sub-agent directly
   - **Do it yourself:** If the task is now small enough, fix it in the orchestrator session
3. **Re-synth** when all tasks are DONE or recovered

## When NOT to use

- **< 3 tasks** — use `glm-task` directly instead
- **Tasks share files** — serialize them or batch by file
- **Tasks need orchestrator mid-flight context** — Agents don't share state with each other or the orchestrator until they report back
- **Tasks are GLM-ineligible** — judgment work, copy/voice, security-sensitive paths — use Claude Agents directly

## Telemetry

Every `glm-subagent` dispatch (including those spawned by Agents) logs to `~/.local/share/glm/usage.jsonl`. Track: token spend per lane (Agent vs GLM), success rate, common BLOCKED reasons.

## Relationship to other skills

- `glm-task`: single dispatch, no Agent overhead. Use for 1-2 tasks.
- `glm-fan`: parallel dispatch via N Agents. Use for ≥3 tasks on different files.
- Agent tool (direct): Claude-only judgment work. Use for design, planning, reviews.
