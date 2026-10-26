# AGENTS.md — NovelTracker

> **Resuming work?** This file is auto-loaded every session. The **Current
> status** section right below is the single source of truth for the stage and
> the exact next action — update it before you finish.

## Current status (resume here)

> Single source of truth for where the project is and what to do next. Keep it
> short: a fresh agent with no prior context must be able to resume from here.
> Never leave status only in chat. Product decisions live in the "Specs" section
> below; the narrative history is the README progress log.

**Pipeline:** gather → critique → design → test → implement → review → document

Legend: ✅ done · 🚧 in progress · ⬜ not started

| Domain | Feature      | gathered | critiqued | designed | tested (red) | implemented |
| ------ | ------------ | -------- | --------- | -------- | ------------ | ----------- |
| auth   | register     | ✅       | ✅        | ✅       | ✅           | ⬜          |
| auth   | login-logout | ✅       | ✅        | ✅       | ✅           | ⬜          |
| novels | create-novel | ✅       | ✅        | ✅       | ⬜           | ⬜          |
| novels | view-novels  | ✅       | ✅        | ✅       | ⬜           | ⬜          |
| novels | edit-novel   | ✅       | ✅        | ✅       | ⬜           | ⬜          |
| novels | delete-novel | ✅       | ✅        | ✅       | ⬜           | ⬜          |

### Next action

**Stage 5 — implement the auth domain.** Build the `users`/`sessions` migration,
the endpoints `POST /api/auth/register|login|logout` and `GET /api/auth/me`, and
the React register/login/logout screens, until `npm run test:api` and
`npm run test:e2e` pass. Command: `/spec-implement auth`.

Then the novels domain: for each of `create-novel`, `view-novels`, `edit-novel`,
`delete-novel`, run `/spec-test <feature>` then `/spec-implement <feature>`.

### Pending decisions / conventions

Defaults already chosen (tell the agent to change any before building): UUID ids;
httpOnly session cookie `nt_session`; JSON error envelope with `snake_case` codes
(`invalid_credentials`, `unauthenticated`); plain JavaScript (Node ESM); raw SQL
migrations via `node-postgres` (no ORM).

### Where the details live

- Rules: `.kilo/rules/core.md` · agents: `.kilo/agent/` · commands: `.kilo/command/`
- Requirements (rules of record): `spec/domains/<domain>/requirements.md`
- Scenarios: `spec/features/<domain>/*.feature` · reviews: `*.review.md`
- Designs: `spec/features/<domain>/*.design.md` · data models: `spec/domains/<domain>/data-model.md`
- How to run locally: `README.md` · narrative history: `README.md` progress log

## Project overview

NovelTracker is a web application for tracking novels. Users register and log
in, then create, view, edit, and delete novel entries with the following
fields:

**Required fields:**
- Author (text)
- Polish title (text)
- Original title (text)
- Year of publishing (4-digit year)
- Genre (one or more, chosen from a predefined dropdown list)

**Optional fields:**
- Picture (uploaded from local file system; JPEG/PNG/WebP/GIF, max 5 MB;
  default book icon if not provided; shown as a thumbnail, click opens larger)
- Description (text; short list preview with a "See more" pop-up; "no
  description yet" if empty)
- Favourite flag (shows the novel with an asterisk)

Users can only manage their own novels. Novels are listed A-Z by default and
can be filtered by author surname (case-insensitive substring), Polish title,
year of publishing, or favourites only. Emails are treated case-insensitively.

## Stack

PERN: PostgreSQL (database), Express.js (API server), React (frontend UI),
Node.js (runtime).

## Infrastructure & Testing

- **Containerization**: Docker (application runs in containers)
- **CI/CD**: Jenkins (automated builds triggered by pushes to external repo)
- **Testing**: 
  - Playwright (end-to-end UI tests)
  - Postman/Newman (API tests)

## Application layout (scaffolded)

- **Language**: plain JavaScript (Node ESM), not TypeScript.
- **npm workspace (monorepo):** the root `package.json` declares the workspaces
  `app/server`, `app/client`, `app/tests`. One `npm install` at the root installs
  all three (shared `node_modules/` + one `package-lock.json`), and the root
  scripts are `npm --workspace <path> run <script>` shortcuts into each package —
  run everything from the repo root.
- The runnable product lives under `app/`; the process/spec layer stays at the
  repo root (`.kilo/`, `spec/`, docs) because Kilo discovers `.kilo/` and
  `AGENTS.md` by walking up from the working directory.
- `app/server/` — Express API; `src/index.js` (app), `src/db.js` (`pg` Pool),
  `src/migrate.js`; SQL migrations in `app/server/migrations/` (raw SQL, no ORM).
- `app/client/` — React via Vite; `src/App.jsx`.
- `app/tests/` — `e2e/` (Playwright), `api/` (Postman collection run by Newman).
- `app/docker/`, `app/jenkins/` — infrastructure.
- No product features implemented yet; `GET /health` is the only endpoint.
  Extra conventions (error envelope, session cookie name, folder structure) must
  be confirmed before an agent invents them.

## Specs

Specs have three layers, all written from the user's plain-language input:

- **Rules:** `spec/domains/<domain>/requirements.md` — canonical numbered
  requirements (`REQ-001`, …) in EARS form. Source of truth for business rules.
- **Examples:** `spec/features/<domain>/<feature-slug>.feature` — executable
  Gherkin scenarios, each tagged `@req:<domain>#REQ-nnn` to the rule it proves.
- **Design (looks):** `spec/domains/<domain>/ui/<screen>.ui.md` — low-fidelity
  UI notes. Visual/layout only; never the behavioural source of truth.

A `.feature` file is frozen once gathered; only the `spec-analyst` agent, in
revise mode, may edit it afterwards.

**Auth domain** (15 scenarios):
- `register.feature` — user registration (9 scenarios)
- `login-logout.feature` — user login and logout (6 scenarios)

**Novels domain** (52 scenarios):
- `create-novel.feature` — create a novel (21 scenarios)
- `view-novels.feature` — list, filter, preview, enlarge picture (16 scenarios)
- `edit-novel.feature` — edit a novel, mark/unmark favourite (11 scenarios)
- `delete-novel.feature` — delete a novel (4 scenarios)

**Resolved decisions** (no open `@todo` remain):
- Emails are case-insensitive (normalized on registration and login).
- Author-surname filter is a case-insensitive substring match.
- Genre is one or more values from a predefined dropdown. Current list:
  Fantasy, Science Fiction, Horror, Thriller, Mystery, Crime, Romance,
  Historical, Adventure, Literary, Drama, Poetry, Non-fiction, Biography,
  Other (revisable).
- Picture uploads: JPEG/PNG/WebP/GIF, max 5 MB.
- No separate details view: the list shows all fields for every novel. The
  description shows as a short inline preview (~first 10 words) plus a "See
  more" control that opens a scrollable pop-up with the full text.
- The same book may exist in multiple users' collections as separate entries;
  access isolation is per entry, not per book title. Users can only CRUD their
  own entries.
- A novel can be marked as a favourite (shown with an asterisk) — both when
  creating it and when editing it; the list can be filtered to favourites only.
- Clicking a novel's picture in the list opens a larger view.
- A valid 4-digit year is between 1000 and 9999.

## Agents

AI agents live in `.kilo/agent/`, ordered by pipeline stage. Order:
gather → critique → design → test → implement → review → document.

1. `spec-analyst` — requirements + Gherkin (owns `requirements.md` and
   `.feature`, revise mode for changes).
2. `spec-critic` — reviews a feature's scenarios and their backing
   requirements; always writes `spec/features/<domain>/<feature-slug>.review.md`
   (Blocking issues, Warnings, Edge cases missed, Coverage gaps, Suggested
   scenarios; verdict `Approved for design` / `Changes required`); the review
   file gates design.
3. `spec-architect` — turns an `Approved for design` feature into
   `.design.md` (API contract, PostgreSQL data model, UI plan, test plan) and
   maintains `spec/domains/<domain>/data-model.md`.
4. `spec-test-author` — writes tests: Playwright (UI) under `app/tests/e2e/`,
   Newman/Postman (API) under `app/tests/api/`; red phase.
5. `spec-implementer` — scaffolds and writes `app/server/` (Express +
   PostgreSQL), `app/client/` (React), `app/docker/`, `app/jenkins/` until tests
   pass.

Stages 6 (review) and 7 (document) are not created yet.

Commands live in `.kilo/command/`: `spec-gather`, `spec-critique`,
`spec-design`, `spec-test`, `spec-implement`. Each is a thin wrapper that runs
its agent with the argument you pass.

**Design docs:** `spec/features/<domain>/<feature-slug>.design.md`. **Shared
data models:** `spec/domains/<domain>/data-model.md` (auth: `users`/`sessions`;
novels: `novels`/`novel_genres`). **Review files:**
`spec/features/<domain>/<feature-slug>.review.md`.

**Suspended (reference only):** the "automatic driver / foreman"
(`spec-orchestrator`) is intentionally kept OUTSIDE `.kilo/agent/` at
`.kilo/suspended-agents/spec-orchestrator.md` so it is not loaded. We drive the
pipeline manually, step by step. See `.kilo/rules/core.md` for the future
option.

## Key rules of the flow

1. **Specs are frozen after gather** — only the analyst (via `--revise`) may
   change a `.feature` file.
2. **Each stage reads the previous stage's outputs** — the chain is:
   `.feature` → `.review.md` → `.design.md` → tests → code.
3. **No agent edits another agent's domain:**
   - Analyst: owns `requirements.md` + `.feature`
   - Critic: only reads, writes `.review.md`
   - Architect: only reads specs, writes `.design.md` + `data-model.md`
   - Test-author: only writes `app/tests/`, never `app/server/` or `app/client/`
   - Implementer: only writes `app/`, never `spec/`
4. **The user controls the pace** — one stage at a time, review the output, then
   run the next.
5. **Continuity** — keep the "Current status" section of this file current so any
   session can resume.

## Local tooling note

- Known Kilo 7.8.8 bug: the write-time config validator crashes ("No context
  found for instance") on Markdown config files — even the documented example.
  Harmless noise unless agents fail to register after a session restart.

Note: this file grows as the repository takes shape.
