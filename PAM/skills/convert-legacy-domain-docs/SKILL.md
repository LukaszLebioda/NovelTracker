---
name: convert-legacy-domain-docs
description: Convert one read-only legacy domain into stakeholder-ready EARS requirements, internal traceability, and UI-wireframe backlog without changing legacy evidence or frozen Gherkin.
---

# Convert Legacy Domain Documentation

Use this skill when a domain in `spec/legacy/<domain>.md` must be migrated to the stakeholder-facing documentation model. The deliverable is understandable to non-technical readers in HackMD and remains traceable to historical evidence.

## Scope and safety

- Work on exactly one `<domain>` per task.
- Never edit, move, summarize in place, or delete `spec/legacy/<domain>.md`.
- Do not edit `.feature` files, production code, contracts, database schemas, or generated lint artefacts during conversion.
- Preserve uncertainty. A legacy claim that is ambiguous, obsolete, contradictory, implementation-specific, or unsupported becomes a decision question; it never becomes an approved requirement.
- Write stakeholder-facing documents in Polish unless the task explicitly requires another language. Keep names required by law, a provider, or an existing UI verbatim and explain them in plain Polish at first use.

## Inputs

Read, in this order:

1. `spec/legacy/<domain>.md` — historical evidence only.
2. A current scope document only when the task explicitly names its path — current scope decisions take precedence over legacy. Do not search for a conventional scope path when none is supplied.
3. Existing `spec/features/**/<feature>.feature`, contracts, and reviews that reference the domain — useful to discover delivered behaviour, but not proof that an unfinished legacy rule is still wanted.
4. Current implementation only if the user asks for an as-built comparison. Do not infer new business scope from code.

If no current scope document is explicitly supplied, record that the current scope is unknown and keep legacy `[DERIVED]`, ambiguous, obsolete, or conflicting claims as decision questions.

Ask a short blocking question only when a decision cannot be represented honestly as an open question. Otherwise continue and record it in the decision table.

## Outputs

Create or update only these paths:

```text
spec/domains/<domain>/requirements.md
spec/domains/<domain>/traceability.md
spec/domains/<domain>/ui/<screen>.ui.md  # only for stakeholder-visible screens in scope
```

Use `spec/templates/requirements.md` and `spec/templates/screen.ui.md` as the structural baseline. Read `spec/ui/design-system.md` before creating a wireframe.

## Conversion procedure

1. Identify the business goal, users, vocabulary, domain boundary, current scope, out-of-scope items, rules, events, errors, and stakeholder-visible screens.
2. Remove implementation noise from `requirements.md`: source paths, line numbers, SQL columns, endpoint paths, Kafka topic names, framework names, enum values, raw citations, and investigation logs belong in the legacy archive or `traceability.md`, not in the stakeholder document.
3. Consolidate duplicates into one business outcome. Split a compound statement when it contains more than one trigger, outcome, or independently testable rule.
4. Assign stable, sequential `REQ-001`, `REQ-002`, ... identifiers. Never reuse an identifier for a different outcome. Map every new ID to its legacy source IDs in `traceability.md`.
5. Write each requirement in exactly one appropriate EARS form:

| Situation | Polish EARS form |
|---|---|
| Always true | `System musi <rezultat>.` |
| User or system event | `Gdy <wyzwalacz>, system musi <rezultat>.` |
| A continuing state | `Dopóki <stan>, system musi <rezultat>.` |
| Error or unwanted condition | `Jeżeli <warunek>, system musi <bezpieczna reakcja>.` |
| Optional capability | `Jeżeli funkcja <nazwa> jest włączona, system musi <rezultat>.` |

6. Add a plain-language purpose and observable acceptance criteria below every EARS statement. A reader must be able to understand the outcome without knowing EARS.
7. Add all unresolved facts to `## Pytania do decyzji` with an affected requirement and status (no owner column in the stakeholder file). Do not hide uncertainty in prose or use vague labels such as "do ustalenia" without a question.
8. Create `traceability.md` as an internal-only table with `REQ ID`, legacy source / old ID, source class, conversion decision, and notes. Link to the legacy file; do not duplicate its contents.
9. Identify only screens that are visible to a stakeholder-facing actor and within current scope. For each, use the `markdown-ui-dsl` skill to create an independent `.ui.md` file. Do not create a wireframe for an API, background job, database table, or deferred screen.
10. Check that every `REQ-*` referenced by a wireframe exists in `requirements.md`, and that the wireframe introduces no decision absent from an approved requirement or an explicit open question.

## Requirements document quality bar

- Start with status (`szkic do konsultacji interesariuszy`), date, scope, consultation goal, and a one-paragraph domain goal. Do **not** put a business owner or as-built / implementation status in the stakeholder file.
- Use short Polish sentences, active voice, real user roles, and visible outcomes.
- Define ambiguous business terms in one table.
- Include an explicit out-of-scope section to prevent accidental legacy carry-over.
- Use `must have`, `should have`, or `could have` priority. Mark every requirement `do akceptacji`, `zaakceptowane`, `wstrzymane`, or `odrzucone` (business acceptance, not code delivery).
- Q table columns: `ID | Pytanie | Wpływ | Status` — no owner column.
- Do not publish technical traceability, `apps/*` paths, or deployment legends in `requirements.md`.
- Do not assert compliance or legal obligations unless the current scope or a product decision supports them.

## Traceability template

```markdown
# <Domena> — śledzenie pochodzenia

**Przeznaczenie:** wyłącznie do pracy zespołu; nie udostępniać interesariuszom w HackMD.

| REQ ID | Źródło historyczne | Klasa źródła | Decyzja konwersji | Uwagi |
|---|---|---|---|---|
| REQ-001 | `spec/legacy/<domain>.md`, BR-1 | LEGACY | zachowano | zakres potwierdzony w jawnie wskazanym dokumencie zakresu |
| Q-001 | `spec/legacy/<domain>.md`, BR-2 | OPEN QUESTION | wymaga decyzji | decyzja: zespół nadzorujący po warsztacie |
```

## Completion checklist

- `requirements.md` is clear when read without the legacy file.
- Every accepted requirement is one testable EARS sentence with acceptance criteria.
- Every unresolved claim has a visible question (no owner field required in stakeholder docs).
- `traceability.md` maps all requirements and does not invent evidence.
- Every `.ui.md` has a stated screen goal, actor, linked `REQ-*`, default state, and relevant alternate states.
- No legacy file or frozen Gherkin file changed.
