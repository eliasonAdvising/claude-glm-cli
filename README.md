# glm-cli

Portable GLM-4.6 sub-agent dispatch for Claude Code sessions. Use any Claude Code workflow with GLM as the bounded executor — same harness, different model, ~3× cheaper per call.

## What this is

glm-subagent wraps `claude --print` with `ANTHROPIC_BASE_URL` pointed at Z.AI's Anthropic-compatible endpoint. Bounded mechanical tasks (lint fixes, scaffolding, refactor-without-behavior-change) run on GLM tokens while the orchestrator stays on Claude. The wrapper is project-agnostic and can be installed globally on any machine.

Install once per machine, run `glm-init` per project. The wrapper auto-layers per-project conventions from `.claude/glm-conventions.md` into the system prompt, so packets stay task-specific. Every dispatch logs telemetry to `~/.local/share/glm/usage.jsonl` for cost tracking and failure-mode analysis.

## Install

```bash
git clone https://github.com/your-org/glm-cli.git ~/projects/glm-cli
~/projects/glm-cli/install.sh
```

Then set up `~/.glm-key` (chmod 600) with your Z.AI bearer token:

```bash
echo "your-zai-bearer-token" > ~/.glm-key
chmod 600 ~/.glm-key
```

### Verify

```bash
glm-subagent --version
# Expected output: glm-cli v0.1.0
```

## Per-project setup

Inside any repo:

```bash
glm-init
```

This creates `.claude/glm-conventions.md`. Edit that file to add project-specific rules (voice conventions, file-gating rules, import ordering, etc.). The wrapper auto-loads these conventions into each GLM subprocess.

## Three dispatch lanes

| Lane | When | Skill |
|---|---|---|
| `glm-task` | 1-2 mechanical tasks | [skills/glm-task/SKILL.md](skills/glm-task/SKILL.md) |
| `glm-fan` | ≥3 parallel-eligible tasks | [skills/glm-fan/SKILL.md](skills/glm-fan/SKILL.md) |
| Claude `Agent` tool | Judgment work | Use directly, not via glm-cli |

**Decision matrix:** If the task needs Claude-quality judgment or will be owner-facing → Agent lane. If mechanical and GLM-eligible → check parallelism: 1-2 tasks → `glm-task`; ≥3 tasks on different files → `glm-fan`.

## Telemetry

Every dispatch logs to `~/.local/share/glm/usage.jsonl`. Query with:

```bash
glm-usage --last 7d
glm-usage --format table
glm-usage --format csv
```

Example output:

```
2026-06-20 to 2026-06-20 — 12 dispatches
Model: glm-4.6
Total wall-clock: 4m23s
Success rate: 92%
```

**v0.1 limitation:** Per-call token counts are null. The Anthropic-compatible endpoint via `claude --print` doesn't surface `.usage`. Wall-clock, packet bytes, response bytes, and exit codes are captured.

TODO: Add direct Z.AI chat completions API call path to capture prompt_tokens, completion_tokens, and total_tokens.

## Superpowers integration

When using superpowers workflows (subagent-driven-development, writing-plans, executing-plans), annotate each task at task-list time with its dispatch lane: `[lane: Agent | glm | glm-fan/group-N]`. The decision happens once, cold, before any implementer fires.

Brief authors stay on the SDD task-brief format; only the dispatch mechanism changes per lane. For the full routing rules and worked examples, see [SUPERPOWERS-INTEGRATION.md](SUPERPOWERS-INTEGRATION.md).

## File layout

```
bin/
  glm-subagent     - the wrapper
  glm-init         - per-project setup
  glm-usage        - telemetry queries
skills/
  glm-task/        - single-dispatch discipline
  glm-fan/         - parallel-Agent → GLM lane
install.sh         - symlink installer
SUPERPOWERS-INTEGRATION.md
README.md
```

## Environment variables

| Var | Required | Default | Where |
|---|---|---|---|
| `GLM_API_KEY` | yes | — | Env var or `~/.glm-key` file (chmod 600) |
| `GLM_MODEL` | no | `glm-4.6` | Shell or `~/.bashrc` |
| `GLM_SMALL_MODEL` | no | `glm-4.5-air` | Shell or `~/.bashrc` |
| `GLM_ENDPOINT` | no | `https://api.z.ai/api/anthropic` | Shell or `~/.bashrc` |

`GLM_API_KEY` is a developer-only secret. Do not set it as a Coolify env var or in `.env` files in repo directories.

## Limitations (v0.1)

- No per-call token counts — the Anthropic-compatible endpoint via `claude --print` doesn't surface `.usage`. Wall-clock and bytes are logged; tokens are null. See Telemetry section for TODO.
- No auto-retry in `glm-fan` when an Agent reports BLOCKED — the orchestrator decides per-Agent how to recover.
- Wrapper assumes the `claude` CLI is on PATH.
- Tested on bash 5.2 / jq 1.7 / Linux. macOS works in principle but the `date -u -d` syntax differs; v0.2 will use POSIX-portable date.
- No per-call token counts — see above.

## License + credits

MIT. Built atop Anthropic's Claude Code CLI and Z.AI's GLM-4.6 Anthropic-compatible endpoint.
