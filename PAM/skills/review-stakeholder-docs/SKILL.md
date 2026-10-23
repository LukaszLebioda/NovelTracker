---
name: review-stakeholder-docs
description: Review canonical EARS requirements and Markdown-UI DSL wireframes for stakeholder clarity, completeness, traceability, and safe HackMD sharing.
---

# Review Stakeholder Documentation

Use this skill before sharing a migrated domain's `requirements.md` or `.ui.md` files in HackMD, and after material feedback. This is a documentation review, not an implementation review.

## Inputs

Read:

1. `spec/domains/<domain>/requirements.md`.
2. `spec/domains/<domain>/ui/*.ui.md` when the directory exists.
3. `spec/domains/<domain>/traceability.md` for internal validation only.
4. `spec/ui/design-system.md`.
5. `spec/legacy/<domain>.md` only to verify that a claimed mapping has not been fabricated.

Do not edit legacy material, frozen Gherkin, production code, tests, or contracts.

## Review dimensions

### Stakeholder clarity

- The first screenful explains status, date, scope, consultation goal, and the domain goal paragraph. No business-owner field and no as-built / `apps/*` delivery section.
- Terms are defined before or at first use.
- A stakeholder can explain every requirement without code, endpoint, schema, or legacy knowledge.
- The document avoids raw citations, file paths, database terms, implementation classes, and unexplained abbreviations.
- Out-of-scope items are visible enough to prevent false expectations.

### EARS quality

- Each `REQ-*` has exactly one main EARS statement in the correct grammar form.
- The statement has a clear trigger or state when needed and one observable outcome.
- `must`, `should`, or `could` priority is present, and status is one of the agreed values.
- Acceptance criteria make the result verifiable without prescribing internal implementation.
- The same business behaviour is not duplicated across requirements.
- Open questions are not masquerading as requirements and have an affected `REQ-*` (and status); no owner column is required in the Q table.

### Traceability

- Every `REQ-*` appears once in `traceability.md`.
- Every traceability mapping points to a real legacy source or states that it is a new decision.
- The mapping does not elevate `[DERIVED]`, an old implementation detail, or an unresolved conflict into an approved fact.
- Requirement identifiers are stable; report an ID reassignment as blocking.

### UI DSL quality

- Every wireframe names its actor, goal, and supporting `REQ-*`.
- Every referenced requirement exists and is not rejected.
- The screen makes normal, empty, loading, error, destructive confirmation, and permission states visible where relevant.
- Every action anchor has one plain-language interaction note and no two actions share an anchor.
- Layout blocks follow the Markdown-UI DSL grammar and remain understandable when rendered as plain Markdown in HackMD.
- The wireframe contains mock data only and does not imply a production-ready design or implementation.

## Findings format

Report findings first, ordered by severity:

| Severity | File and location | Finding | Why it matters | Required correction |
|---|---|---|---|---|
| Blocking | `requirements.md`, REQ-003 | <finding> | <risk> | <specific correction> |

Use these severities:

- `Blocking` — unclear or contradictory product behaviour, missing decision question for material uncertainty, invalid requirement traceability, or UI that introduces unapproved behaviour.
- `Major` — not testable, confusing to stakeholders, missing an essential state, or outside scope without a clear label.
- `Minor` — wording, terminology, formatting, or readability improvement.

After the findings, provide a brief verdict: `Ready for HackMD`, `Ready after minor corrections`, or `Not ready`. Do not silently rewrite product decisions during review.
