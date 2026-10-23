---
description: Implementation — scaffolds and writes the application until the feature tests pass
agent: 05-spec-implementer
arguments: <domain>/<feature-slug>
---

Run the spec-implementer agent for the given feature:

$ARGUMENTS

The implementer reads the feature, its design doc, the data model, and the
tests, then scaffolds the project if needed and implements app/server (Express +
PostgreSQL) and app/client (React) until the Playwright and Newman tests pass. It
never edits specs or weakens tests.
