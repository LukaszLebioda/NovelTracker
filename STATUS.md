# STATUS.md — NovelTracker

> **The single source of truth for where the project is and what to do next.**
> Read this first when resuming (it is pointed to from the auto-loaded
> `AGENTS.md`). Keep it short and unambiguous: a fresh agent with no prior context
> must be able to resume from here alone. Never leave status only in chat.
> Durable project instructions live in `AGENTS.md`; the narrative history is the
> `README.md` progress log.

## Pipeline

analyse → critique → design → test → implement → review → document

Legend: ✅ done · 🚧 in progress · ⬜ not started

| Domain | Feature      | analysed | critiqued | designed | tested (red) | implemented |
| ------ | ------------ | -------- | --------- | -------- | ------------ | ----------- |
| novels | create-novel | ✅       | ✅        | ✅       | ⬜           | ⬜          |

**Scope (narrowed 2026-10-27):** only **creating a novel** is specified.
Authentication (login/logout) and per-user ownership, viewing/filtering, editing,
and deleting are **deferred**; their specs and tests were removed.

## Next action

**Stage 4 — write the tests, then implement `create-novel`.** Run
`/spec-test novels/create-novel` to write the red (failing) tests, then
`/spec-implement novels/create-novel` until `npm run test:api` and
`npm run test:e2e` pass.

Prerequisites to run anything: `npm install` (the workspace is not installed yet)
and a running PostgreSQL with `.env` filled in (`DATABASE_URL`, `PORT`).

## History

Decisions and reversals are logged in the `README.md` progress log (the _why_);
git tracks the _what_.
