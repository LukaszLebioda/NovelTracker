---
description: Requirements gathering — turns a plain-language description into numbered requirements and tagged Gherkin
agent: spec-analyst
arguments: <feature description> | <domain>/<feature-slug> --revise
---

Run the spec-analyst agent with the following arguments:

$ARGUMENTS

The analyst writes/updates spec/domains/<domain>/requirements.md first, then the
tagged .feature. With --revise, it changes existing specs only as requested.
