---
description: Test authoring — turns an approved feature into Playwright (UI) and Newman (API) tests
agent: 04-spec-test-author
arguments: <domain>/<feature-slug>
---

Run the spec-test-author agent for the given feature:

$ARGUMENTS

The test-author reads the feature, its design doc, and the data model, then
writes Playwright specs (app/tests/e2e) for UI scenarios and Postman/Newman
requests (app/tests/api) for API scenarios, one test per scenario carrying its
@req tag. It never edits specs or production code.
