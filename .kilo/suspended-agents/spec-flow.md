---
description: Automatic driver — runs the pipeline for a feature by chaining the stage agents (analyse → critique → design → test → implement) until implemented or blocked
agent: spec-orchestrator
arguments: <feature description>
---

> **SUSPENDED (2026-10-27).** Parked, not registered: Kilo only discovers
> `.kilo/command/*.md`, so `/spec-flow` is unavailable while this file lives here.
> To reactivate, move it back to `.kilo/command/spec-flow.md` (and
> `spec-orchestrator.md` to `.kilo/agent/`) and delete this banner.

Run the spec-orchestrator agent with the following arguments:

$ARGUMENTS

The orchestrator records the prompt, then drives every stage by invoking the
stage agent directly via the `task` tool — chaining automatically (analyse →
critique → design → test → implement) and stopping only when the feature is
implemented or genuinely blocked on your input, without you typing each stage.
Stages 6 (review) and 7 (document) are not created yet. To run a single stage by
hand instead, use `/spec-analyse`, `/spec-critique`, `/spec-design`, `/spec-test`,
`/spec-implement`.
