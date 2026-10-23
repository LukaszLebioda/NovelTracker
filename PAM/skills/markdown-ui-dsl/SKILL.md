---
name: markdown-ui-dsl
description: Create and review low-fidelity stakeholder wireframes in Markdown-UI DSL for the canonical domain documentation model.
license: MIT
metadata:
  source: https://github.com/MegaByteMark/markdown-ui-dsl
  upstream-version: "1.0.3"
---

# Markdown-UI DSL For PAM

Use this skill to create or update `spec/domains/<domain>/ui/<screen>.ui.md`. It adapts the Markdown-UI DSL convention for a HackMD-first documentation workflow. It is an experimental wireframing convention, not a code generator or a replacement for EARS, Gherkin, contracts, tests, or production design review.

## Before editing

1. Read the matching `spec/domains/<domain>/requirements.md` and `spec/ui/design-system.md`.
2. Identify the actor, screen goal, linked `REQ-*` identifiers, and all visible states.
3. If a UI decision is not covered by a requirement, place it in the document as an explicit HTML comment or add it to the domain's decision questions. Do not silently choose product behaviour.
4. Do not alter existing production components as an implicit synchronization step. A `.ui.md` file may name a component only after an explicit task has established that relationship.

## File location and frontmatter

Create one screen per file at `spec/domains/<domain>/ui/<screen>.ui.md`.

```yaml
---
framework: React 19 + Vite 8 + Tailwind CSS v4 + shadcn/ui
theme: ../../../ui/design-system.md
status: draft
data: local mock data only
component: not-yet-linked
---
```

Use `component: not-yet-linked` for a proposal. Set a real path only when the user explicitly asks to bind a wireframe to an existing or newly created component.

## Strict DSL syntax

| Purpose | Syntax |
|---|---|
| Vertical layout | `||| COLUMN |||` ... `--- END ---` |
| Horizontal layout | `=== ROW ===` ... `--- END ---` |
| Card | `::: CARD :::` ... `--- END ---` |
| Modal or dialog | `::: MODAL :::` ... `--- END ---` |
| Header or footer | `::: HEADER :::` / `::: FOOTER :::` ... `--- END ---` |
| Button or action | `[ Label ](#action-id)` |
| Text input | `[ text: Placeholder ]` |
| Checkbox | `[ ] Label` or `[x] Label` |
| Radio button | `( ) Label` or `(x) Label` |
| Toggle | `[on] Label` or `[off] Label` |
| Select | `[v] Selected {Option 1, Option 2}` |
| Badge | `(( Status ))` |
| Image or skeleton placeholder | `[ IMG: Description ]` |
| Divider | `***` |
| Layout hint | `> align right`, `> space between` |
| Responsive instruction | `> @sm stack: vertical` or `> @lg columns: 3` |

Use standard Markdown for headings, descriptive text, lists, and tables. Use only `***` for visual dividers; `---` is reserved for a DSL block boundary. Close every layout, card, modal, header, or footer with `--- END ---`.

## Required screen structure

Every wireframe contains, in this order:

1. Title, screen goal, actor, and linked requirements in plain Polish.
2. `## Stan domyślny` with the primary action and normal content.
3. Relevant `## Stan pusty`, `## Stan ładowania`, `## Stan błędu`, `## Brak uprawnień`, or confirmation/dialog states.
4. `## Notatki o interakcjach`, mapping every `#action-id` to a plain-language outcome and the supporting `REQ-*`.

Use only fictitious local mock data. State explicitly that the document is a low-fidelity proposal, not a deployed screen.

## Accessibility and stakeholder clarity

- Give each action an explicit label. Do not use an icon as the only representation of a business action.
- Keep the key action visible on narrow screens; state responsive changes when an action moves into a menu.
- Explain error recovery and destructive actions in human language.
- Use headings and short labels that make sense when copied into HackMD without repository context.
- Do not use a table where a linear mobile-friendly list is clearer; document the responsive alternative if necessary.

## Synchronization rule

The default flow is one-way and explicit: a human approves the `.ui.md`, then a separately scoped task may create or update a prototype or a production component. Never claim automatic two-way synchronization. If an existing component and its wireframe conflict, stop and report the drift with both file paths; do not overwrite either side without an explicit decision.

## Validation checklist

- Frontmatter has a correct relative `theme` path and no production data.
- All blocks are closed and all action anchors are unique.
- The screen has no action, validation rule, or state that contradicts its linked `REQ-*`.
- The default, empty, loading, error, confirmation, and permission states are present when relevant.
- Labels are understandable to a non-technical stakeholder.
- No code, API endpoint, database field, secret, or real personal data is embedded in the wireframe.
