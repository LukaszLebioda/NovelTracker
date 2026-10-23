---
description: Documentation — reconcile an implemented feature and publish separate Dev, DevOps, and Operator documents
agent: spec-documenter
arguments: <domain>/<feature-slug>
---

Run the spec-documenter agent with the following arguments:

$ARGUMENTS

The documenter compares the current implementation with the feature and review artifacts before publishing. On agreement, it creates or updates:

- `docs/dev/<domain>/<feature-slug>.md`
- `docs/devops/<domain>/<feature-slug>.md`
- `docs/operator/<domain>/<feature-slug>.md`

The Dev document includes current database and API contract schemas. All diagrams use PlantUML. If material drift is found, no audience document is published; the agent writes `spec/features/<domain>/<feature-slug>.documentation-drift.md` and records a blocked status in the feature log.
