---
description: Test authoring (red) — turns approved features + contracts into failing plain Jest e2e tests
agent: spec-test-author
arguments: <domain>/<feature-slug>
---

Run the spec-test-author agent with the following arguments:

$ARGUMENTS

The test-author will read the approved feature spec and contracts manifest, then create failing plain Jest e2e tests (red phase of TDD).
