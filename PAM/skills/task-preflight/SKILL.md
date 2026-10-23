---
name: task-preflight
description: Mandatory gate before any non-trivial implementation. Use at task start to verify inputs, split atomic work, plan skill cascade, and refuse coding when information is incomplete. Also use when scope is unclear or context may exceed 170k.
---

# Task preflight

Run **before** writing or editing production code. Other skills assume this passed.

## 1. Restate the task

In 1–3 bullets: goal, in-scope apps (`pam-api` / `pam-ui` / packages), out-of-scope.

## 2. Completeness check (stop if any fail)

| Check | Pass criteria |
|---|---|
| Goal | Concrete outcome, not vague “improve X” |
| Acceptance | How we know done (scenarios, API behaviour, UI flow) |
| Spec/source | Named path: feature file, requirements REQ ids, or explicit user rules |
| Placement | Target module/feature folder known or discoverable in one search |
| Contracts | Existing schemas identified, or plan to add via `add-contracts-feature` |
| Data | DB tables/columns known if persistence involved |
| Authz | Who may call it (admin/player/public) |
| Tests | Which layers required (see §4) |

If any row fails → **do not implement**. Ask the user only for the missing items. Do not invent domain behaviour.

## 3. Atomic split

If the request spans multiple independent responsibilities, split into ordered tasks and do **one** now:

- contracts / migration
- one API resource or use-case
- one UI surface
- one test layer only when fixing tests in isolation

Refuse mega-PRs in a single agent turn when they blow the context budget.

## 4. Required test plan (record before coding)

| Change touches | Must add/update |
|---|---|
| Service + DB | PGlite integration specs → `test-backend` |
| Controller/HTTP | supertest controller specs → `test-backend` |
| Pure util/guard | unit specs → `test-backend` |
| API contract shape | `*.mock.ts` fixtures + rebuild contracts |
| UI component behaviour | component specs (mocked hooks) → `test-frontend` |
| UI user journey / page | integration RTL+MSW (human-like clicks) → `test-frontend` |
| Feature Gherkin | app feature e2e under `apps/<app>/src/test/features/` per AGENTS.md |

No behaviour change without the matching tests in the same task.

## 5. Skill cascade (load only what this task needs)

Invoke via `skill` tool in order as applicable:

1. `add-contracts-feature` — if schemas/mocks missing
2. `backend-conventions` then `add-backend-module` / `add-backend-feature` — API work
3. `frontend-conventions` then `add-frontend-feature` — UI work
4. `test-backend` / `test-frontend` — while or immediately after implementation
5. Domain docs skills only for spec/docs tasks

Do **not** load all skills up front.

## 6. Context budget (170k)

- Prefer `grep`/`read` slices over whole large files
- One domain cluster / feature folder in active memory
- After large tool dumps, summarize and drop raw noise
- If approaching limit: finish current atomic unit, verify tests, stop; continue in a new session

## 7. Exit

- **Blocked** — list missing info; wait
- **Ready** — one-line plan + skills to load + test plan; then proceed
