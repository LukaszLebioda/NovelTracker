# AGENTS.md — NovelTracker

> **Resuming work? Read `STATUS.md` first** — it is the single source of truth
> for the current stage and the exact next action. Update it before you finish.

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
- `server/` — Express API; `src/index.js` (app), `src/db.js` (`pg` Pool),
  `src/migrate.js`; SQL migrations in `server/migrations/` (raw SQL, no ORM).
- `client/` — React via Vite; `src/App.jsx`.
- `tests/` — `e2e/` (Playwright), `api/` (Postman collection run by Newman).
- `docker/`, `jenkins/` — infrastructure.
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

AI agents live in `.kilo/agent/`, numbered by pipeline stage. Order:
gather → critique → design → test → implement → review → document.

1. `01-spec-analyst` — requirements + Gherkin (owns `requirements.md` and
   `.feature`, revise mode for changes).
2. `02-spec-critic` — reviews a feature's scenarios and their backing
   requirements; always writes `spec/features/<domain>/<feature-slug>.review.md`
   (Blocking issues, Warnings, Edge cases missed, Coverage gaps, Suggested
   scenarios; verdict `Approved for design` / `Changes required`); the review
   file gates design.
3. `03-spec-architect` — turns an `Approved for design` feature into
   `.design.md` (API contract, PostgreSQL data model, UI plan, test plan) and
   maintains `spec/domains/<domain>/data-model.md`.
4. `04-spec-test-author` — writes tests: Playwright (UI) under `tests/e2e/`,
   Newman/Postman (API) under `tests/api/`; red phase.
5. `05-spec-implementer` — scaffolds and writes `server/` (Express +
   PostgreSQL), `client/` (React), `docker/`, `jenkins/` until tests pass.

Stages 6 (review) and 7 (document) are not created yet.

Commands live in `.kilo/command/`: `spec-gather`, `spec-critique`,
`spec-design`, `spec-test`, `spec-implement`. Each is a thin wrapper that runs
its numbered agent with the argument you pass.

**Design docs:** `spec/features/<domain>/<feature-slug>.design.md`. **Shared
data models:** `spec/domains/<domain>/data-model.md` (auth: `users`/`sessions`;
novels: `novels`/`novel_genres`). **Review files:**
`spec/features/<domain>/<feature-slug>.review.md`.

**Suspended (reference only):** the "automatic driver / foreman"
(`spec-orchestrator`) is intentionally kept OUTSIDE `.kilo/agent/` at
`.kilo/suspended-agents/spec-orchestrator.md` so it is not loaded. We drive the
pipeline manually, step by step. See `.kilo/rules/core.md` for the future
option.

Note: this file grows as the repository takes shape.
