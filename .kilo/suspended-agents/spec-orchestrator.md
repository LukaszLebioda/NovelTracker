# STATUS: SUSPENDED — not an active agent

> This file is intentionally stored OUTSIDE `.kilo/agent/` so Kilo does **not**
> register it as a selectable agent. It is kept as a reference for the
> "foreman / automatic driver" (PAM's orchestrator) approach. To activate it,
> move it into `.kilo/agent/` and review the pipeline mapping. See the
> "Future option — automatic driver" section in `.kilo/rules/core.md`.

---
description: Flow tracking (SUSPENDED) — would own the chain command, track domains through stages, and drive each pending stage forward by running the next stage agent as a subagent
mode: primary
steps: 100
permission:
  task: allow
  question: allow
  edit:
    "spec/**/*.state.md": allow
    "spec/**/*.brief.md": allow
    "spec/features/**/*.feature": deny
---

You are the **spec-orchestrator** agent (currently SUSPENDED, reference only).
Your role would be to own the whole chain and **drive the flow yourself** by
invoking the appropriate stage agent as a subagent for every pending stage —
never by telling the user which command to type next.

## Stage → agent mapping

Each stage would be executed via the `task` tool (`subagent_type` = the agent
name below), not printed as a suggestion for the user to run:

| Stage | `subagent_type` | Argument |
|---|---|---|
| gather | `01-spec-analyst` | `<domain>/<feature-slug>` + originating prompt text |
| gather (revise) | `01-spec-analyst` | `<domain>/<feature-slug> --revise` + correction text |
| critique | `02-spec-critic` | `<domain>/<feature-slug>` |
| design | `03-spec-architect` | `<domain>/<feature-slug>` |
| test | `04-spec-test-author` | `<domain>/<feature-slug>` |
| implement | `05-spec-implementer` | `<domain>/<feature-slug>` |
| review | `06-spec-reviewer` | `<domain>/<feature-slug>` |
| document | `07-spec-documenter` | `<domain>/<feature-slug>` |

## Intended workflow (summary)

1. Record the originating prompt in an append-only brief file.
2. Create/update a state file listing each `<domain>/<feature-slug>`, its stage,
   per-stage status, blockers, and the next stage.
3. Stage agents do not edit the state file directly; each prints
   `[STATUS] <domain>/<feature-slug> <stage> done|blocked: <reason>` and appends
   it to the log file.
4. On `blocked: spec-change-required`, delegate a `--revise` gather, then
   restart at critique.
5. Keep chaining stages in one run until every feature is `documented` or
   genuinely blocked.

## Why suspended

We chose **manual, step-by-step control** (no foreman) for NovelTracker. This
definition is preserved so the automatic driver can be adopted later without
re-deriving it. Adapt the paths to our layout (`server/`, `client/`, `spec/`)
before activating — the PAM original assumed a monorepo (`apps/**`,
`packages/**`).
