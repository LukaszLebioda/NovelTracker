# NovelTracker — STATUS

> **Read this first, in any session or window.** It is the single source of
> truth for where the project is and what to do next. Update it before ending
> any task. Never leave status only in chat — chats are NOT shared between
> sessions; these files are.

## How to resume in a fresh session

1. Read this file, then `AGENTS.md`, then `README.md` ("Current state & decisions").
2. Do the "Next action" below.
3. Work the pipeline with the numbered agents / commands:
   `01-spec-analyst` (/spec-gather) → `02-spec-critic` (/spec-critique) →
   `03-spec-architect` (/spec-design) → `04-spec-test-author` (/spec-test) →
   `05-spec-implementer` (/spec-implement).
4. **Before finishing:** update the stage table and the "Next action" here, and
   append a dated entry to the README progress log.

## Pipeline stages

gather → critique → design → test → implement → review → document

## Status by feature

Legend: ✅ done · 🚧 in progress · ⬜ not started

| Domain | Feature | gathered | critiqued | designed | tested (red) | implemented |
|---|---|---|---|---|---|---|
| auth | register | ✅ | ✅ | ✅ | ✅ | ⬜ |
| auth | login-logout | ✅ | ✅ | ✅ | ✅ | ⬜ |
| novels | create-novel | ✅ | ✅ | ✅ | ⬜ | ⬜ |
| novels | view-novels | ✅ | ✅ | ✅ | ⬜ | ⬜ |
| novels | edit-novel | ✅ | ✅ | ✅ | ⬜ | ⬜ |
| novels | delete-novel | ✅ | ✅ | ✅ | ⬜ | ⬜ |

## Next action

**Stage 5 — implement the auth domain.** Build the `users`/`sessions` migration,
the endpoints `POST /api/auth/register|login|logout` and `GET /api/auth/me`, and
the React register/login/logout screens, until `npm run test:api` and
`npm run test:e2e` pass. Command: `/spec-implement auth`.

Then the novels domain: for each of `create-novel`, `view-novels`, `edit-novel`,
`delete-novel`, run `/spec-test <feature>` then `/spec-implement <feature>`.

## Pending decisions / conventions

Defaults already chosen (tell the agent to change any before building):
UUID ids; httpOnly session cookie `nt_session`; JSON error envelope with
`snake_case` codes (`invalid_credentials`, `unauthenticated`); plain JavaScript
(Node ESM); raw SQL migrations via `node-postgres` (no ORM).

## How to run locally

From `NovelTracker/`: `npm install` → `cp .env.example .env` → `npm run migrate`
→ `npm run dev:server` (:3000) + `npm run dev:client` (:5173); `npm run test:api`
(Newman) and `npm run test:e2e` (Playwright);
`docker compose -f docker/docker-compose.yml up --build`.

## Where the details live

- Rules: `.kilo/rules/core.md` · agents: `.kilo/agent/` · commands: `.kilo/command/`
- Requirements (rules of record): `spec/domains/<domain>/requirements.md`
- Scenarios: `spec/features/<domain>/*.feature` · reviews: `*.review.md`
- Designs: `spec/features/<domain>/*.design.md` · data models: `spec/domains/<domain>/data-model.md`
- Narrative history: `README.md` progress log
