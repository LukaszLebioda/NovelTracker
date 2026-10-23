---
description: Flow tracking — owns /spec-flow, tracks feature sets through stages, and runs each stage as a subagent until documentation completes or the flow hits a genuine blocker
agent: spec-orchestrator
arguments: <feature description>
---

Run the spec-orchestrator agent with the following arguments:

$ARGUMENTS

The orchestrator will create/update the feature-set state file and drive every sub-feature through stages (gather → critique → design → test → implement → review → document) by invoking each stage's agent directly via the `task` tool, chaining through stages automatically until every sub-feature is documented or blocked on something that needs your input. Use `/spec-document <domain>/<feature-slug>` to refresh documentation for an existing feature outside a new flow.
