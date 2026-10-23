---
description: Requirements gathering — drafts executable Gherkin feature specs from user prompts and legacy domain requirements
agent: spec-analyst
arguments: <feature description> | <domain>/<feature-slug> --revise
---

Run the spec-analyst agent with the following arguments:

$ARGUMENTS

If the argument contains `--revise`, this is a revision request. The analyst will read blocking reports and update the frozen `.feature` file (the sole path that edits existing Gherkin), then reset the flow to critique.
