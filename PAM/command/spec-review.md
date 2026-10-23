---
description: Final review — verifies implementation + tests against the Gherkin spec and runs the affected suite
agent: spec-reviewer
arguments: <domain>/<feature-slug>
---

Run the spec-reviewer agent with the following arguments:

$ARGUMENTS

The reviewer will verify implementation + tests against the Gherkin spec, run the affected suite, perform diff-based assertion checks, audit Gherkin freeze enforcement, and produce code-review and coverage reports.
