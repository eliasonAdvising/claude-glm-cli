---
name: glm-task
description: Dispatch one bounded mechanical coding task to GLM-4.6 via `glm-subagent`. Use ONLY for narrow deterministic work (rename, lint/type fix, scaffold, refactor-without-behavior-change) in a known file scope. Project conventions auto-layer from .claude/glm-conventions.md.
---

# glm-task — single GLM sub-agent dispatch

GLM is reached as a **sub-agent**, not a separate terminal. The orchestrator (this Claude session) calls `glm-subagent` with a packet on stdin; the wrapper spawns a one-shot `claude --print` subprocess with `ANTHROPIC_BASE_URL` pointing at Z.AI. The subprocess gets the full Claude Code harness (Read, Edit, Bash, etc.) but runs against GLM-4.6. Its final stdout returns to the orchestrator.

This is a Bash-invoked sibling of the Agent tool, not a replacement.

## When to use (eligibility checklist)

Use `glm-task` when **all** of these are true:

- The work is mechanical / deterministic (no judgment call, no copy/voice/design)
- File scope is known up-front (≤5 files typical)
- Success is verifiable by a named test or lint/typecheck command
- GLM-tier output quality is sufficient (lint, types, mechanical edits — yes; subtle refactors or anything semantic — Agent)

**Typical GLM-eligible work:**
- Rename symbol across files
- Add Vitest scaffolds for a pure function
- Fix lint/type errors with a clear rule
- Refactor-without-behavior-change in a bounded scope

**Use the Agent tool instead when:**
- The task needs Claude-quality judgment (planning, design review, multi-perspective lenses)
- The output will be owner-facing or voice-sensitive
- The work involves security-sensitive paths

## Packet schema

The packet is the stdin content piped to `glm-subagent`. Every field earns its tokens.

```text
<glm_task_packet>
Task:
[One sentence imperative stating exactly what GLM should do.]

Why this matters:
[Briefly explain the goal in business or project terms.]

Context:
[Minimum background needed to act correctly.]

Relevant files:
- path/to/file1
- path/to/file2

Inputs available:
- [APIs, types, commands, test files, docs GLM should use]
- [Known constraints or prior decisions]

Constraints:
- Do not change [list what must remain stable]
- Do not introduce new dependencies unless explicitly required
- Keep scope to the files listed above unless absolutely necessary
- Preserve existing behavior outside the requested change
- If something is ambiguous, stop and escalate rather than guessing

Expected output:
- [What GLM should return: code, tests, patch, explanation]
- [Whether to include reasoning notes or only final artifacts]

Success criteria:
- [Criterion 1]
- [Criterion 2]

Verification steps:
- [Command to run tests]
- [Command to run lint or typecheck]
- [Manual check if needed]

Stop conditions:
- Stop when success criteria are met
- Stop if the task would require broad refactoring
- Stop if the request conflicts with constraints
- Escalate if requirements are unclear (cap: 3 iterations)

Do not change:
- [Anything outside scope]
- [Public interfaces]
- [Database schema]
- [Copy/design text]

Notes for the GLM sub-agent:
- [Project-specific guidance — but prefer conventions file for this]
</glm_task_packet>
```

## Invocation

```bash
glm-subagent < /tmp/glm-packet.md
```

Or via heredoc:

```bash
glm-subagent <<'PACKET'
<glm_task_packet>
...
</glm_task_packet>
PACKET
```

The wrapper is on PATH after `npm install -g glm-cli`. No project-local script needed.

## Per-project conventions

Project-specific rules live in `<project>/.claude/glm-conventions.md` and get **auto-layered** by the wrapper into each GLM subprocess. Packet authors should NOT restate boilerplate like:

- TS strict mode rules
- Import ordering conventions
- Em-dash preferences
- Project-specific file gating rules

Put those in `.claude/glm-conventions.md` once. Packets stay task-specific.

## Stop / escalate signals

Treat any of these in the subprocess stdout as escalation:

- "STOP:" prefix or explicit "escalating to Claude"
- "needs <file>" indicating scope expansion
- Empty / truncated output
- Verification commands failed after the sub-agent's allotted retries

On any of these: do not loop. Read recent learnings, then either refine + retry once or take over in Claude.

## Loop discipline

The packet's `Stop conditions` cap iterations at 3. The orchestrator caps its own retry pattern at **1 refined retry** per task before escalating to a Claude Agent.

After every dispatch (success, no-op, stop, abandoned), append a one-line dated bullet to `LEARNINGS.md` (or your project's learning-log file) with:
- Outcome
- What worked / what failed (one phrase)
- Refined-prompt pattern worth reusing (if applicable)

## Telemetry

Every `glm-subagent` dispatch logs to `~/.local/share/glm/usage.jsonl` automatically. Track token spend, success rate, and common failure modes.
