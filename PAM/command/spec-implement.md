---
description: Implementation (green) — fills contracts until feature tests pass
agent: spec-implementer
arguments: <domain>/<feature-slug>
---

Run the spec-implementer agent with the following arguments:

$ARGUMENTS

The implementer will read the feature spec, contracts manifest, and red e2e/unit tests, then fill the contracts until tests pass (green phase of TDD).
