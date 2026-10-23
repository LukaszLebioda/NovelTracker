---
description: Prompt design — interactively gathers requirements for a new feature and drafts a ready-to-paste /spec-flow prompt block
agent: spec-prompt-designer
arguments: <rough feature idea>
---

Run the spec-prompt-designer agent with the following arguments:

$ARGUMENTS

The designer will ask clarifying questions, propose domain, host app, module placement, and feature slug based on `spec/legacy/` and `AGENTS.md`'s domain map, then write a paste-ready `spec-flow-prompt-<feature-slug>.md` at the repo root. It never invokes `/spec-flow` itself and never edits `spec/`, `apps/`, or `packages/`.
