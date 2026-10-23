# Core (always on)

## Context budget

- Hard cap: **170k tokens** per session/agent. Prefer tools over pasting large files; compact early.
- Load skills **on demand** via the `skill` tool. Cascade: parent skill may invoke child skills when needed.
- Do not dump full convention skills into context "just in case".

## Task gates (mandatory)

1. **Preflight** — before implementation, load skill `task-preflight`. No code until checks pass or user unblocks.
2. **Atomic work** — one responsibility per change set (one endpoint family, one UI surface, or one test layer). Split larger requests.
3. **No guessing** — missing reqs, contracts, schema, or acceptance criteria → stop and ask. Do not invent domain rules.
4. **Tests with code** — every behaviour change ships tests in the same task:
   - Backend: unit/integration (PGlite) + controller (supertest) as applicable → skill `test-backend`
   - Contracts mocks when API shape changes → skill `add-contracts-feature` / `test-frontend` MSW
   - Frontend: component + user-flow (integration/e2e-style RTL) → skill `test-frontend`
5. **Done means green** — run the relevant lint/typecheck/tests for touched apps before finishing.

## Package manager & types

- **yarn only** (Berry). Never npm/pnpm.
- **Zod only** for validation. Types = `z.infer<typeof Schema>` — no parallel interfaces.
- Shared request/response schemas live in `packages/contracts`.

## Git commits (when asked to commit)

```
<ticket> <verb> <what>
```

Ticket from branch name (e.g. `ULT40-4`). Verb imperative lowercase. No period, no AI co-author lines. Subject ≤100 chars. Body only for **why**.

## Secrets

Never commit or log secrets, keys, or credentials.

## Skills map (load when matching)

| When | Skill |
|---|---|
| Any non-trivial task start | `task-preflight` |
| Nest/Drizzle/API work | `backend-conventions` |
| pam-ui feature/UI work | `frontend-conventions` |
| Backend tests | `test-backend` |
| Frontend tests / MSW | `test-frontend` |
| New/updated contracts | `add-contracts-feature` |
| New API capability | `add-backend-feature` (+ `add-backend-module` if needed) |
| New UI feature | `add-frontend-feature` |
| Legacy→EARS / wireframes | `convert-legacy-domain-docs`, `markdown-ui-dsl`, `review-stakeholder-docs` |
