# NovelTracker

PERN-stack web application for tracking novels, built spec-driven.

## What this is

Users register and log in, then create, view, edit, and delete novel entries
with the following fields:

**Required:**
- Author
- Polish title
- Original title
- Year of publishing (4-digit year)
- Genre (predefined dropdown)

**Optional:**
- Picture (uploaded from local file system; JPEG/PNG/WebP/GIF, max 5 MB;
  default book icon shown if not provided)
- Description (shown as a short list preview, ~first 10 words, with a "See
  more" pop-up for the full scrollable text; "no description yet" if empty)

Users can only manage their own novels. The novel list is sorted A-Z by default
and can be filtered by author surname (case-insensitive substring), Polish
title, or year of publishing. Emails are treated case-insensitively. There is
no separate details view — the list shows every field. The same book may exist
in several users' collections as separate entries; isolation is per entry.

## Technology Stack

| Component | Technology |
|---|---|
| **Database** | PostgreSQL |
| **Backend** | Express.js (Node.js) |
| **Frontend** | React |
| **Containerization** | Docker |
| **CI/CD** | Jenkins (triggered by pushes to external repo) |
| **E2E Testing** | Playwright |
| **API Testing** | Postman/Newman |

## Repository layout

| Path | Purpose |
|---|---|
| `AGENTS.md` | always-loaded baseline for AI agents (project description, stack, spec layout) |
| `README.md` | this file: human-friendly log of what we do and why |
| `spec/features/<domain>/` | frozen Gherkin specs (auth: register.feature, login-logout.feature; novels: create-novel.feature, view-novels.feature, edit-novel.feature, delete-novel.feature) |
| `spec/domains/<domain>/` | `requirements.md` (numbered EARS rules) and `ui/` (low-fidelity UI notes) |
| `.kilo/agent/` | AI agent definitions (spec-analyst.md, spec-critic.md) |
| `.kilo/suspended-agents/` | reference-only agents not loaded (spec-orchestrator.md — future "foreman") |
| `.kilo/rules/` | always-on rules every agent session loads (core.md) |
| `.kilo/command/` | slash commands (not yet created) |
| `.kilo/kilo.json` | project permissions (allow read/edit/bash/task/skill/question/todowrite) |
| `PAM/` | reference SDD project (agents, commands, rules, skills, guide) |
| `server/` | Express.js API server (`src/index.js` health endpoint, `src/db.js` pg pool, `src/migrate.js`, `migrations/`) |
| `client/` | React UI (Vite; `src/App.jsx`) |
| `tests/` | Playwright config + `e2e/`, Postman collection + Newman in `api/` |
| `docker/` | `Dockerfile.server`, `Dockerfile.client`, `docker-compose.yml` |
| `jenkins/` | `Jenkinsfile` pipeline |

All Kilo config (agents, rules, commands, permissions) lives inside `.kilo/`.
Specs live in `spec/features/<domain>/` per Gherkin convention. Application
code, Docker, and Jenkins configurations not yet created.

## How we work

- PAM (`PAM/`, `COMPLETE_PAM_AGENT_GUIDE.md`) is always consulted and
  referred to, but the user decides the style: PAM-style or an alternative
  the agent suggests.
- New files are proposed first (content shown) and created only after the
  user approves.
- Rules are live: during any interaction the agent watches for conventions,
  decisions, or recurring corrections and proposes rule updates to
  `.kilo/rules/core.md` (applied only after approval).
- Spec-driven loop: the user states requirements in plain language in chat →
  the agent may ask questions or suggest improvements → the `spec-analyst`
  agent converts them to Gherkin → the user reviews and freezes the file.
  The agent does not invent feature descriptions.
- Known Kilo 7.8.8 bug: write-time config validator crashes ("No context
  found for instance") on Markdown config files — even the documented
  example. Harmless noise unless agents fail to register after a session
  restart.

## Current state

**The current stage and the exact next action live in `STATUS.md`** (project
root) — read it first, in any session, in any window. This README is the
**history log**: dated entries below record what we did and why, newest last.

Durable decisions and structure live in `AGENTS.md`; the always-on working rules
live in `.kilo/rules/core.md`. Nothing needed to resume should exist only in a
chat window.

## Manual: how a feature becomes a spec (the gather stage)

What we did on 2026-10-12, recorded so it can be repeated for any feature:

1. **The user describes the feature in plain language in the chat window** —
   e.g. "Users register with email and password, log in, and log out".
   **CRITICAL: The user MUST provide the feature description. The agent does NOT
   invent or create feature descriptions on its own.**
2. That description is handed to the spec-analyst agent
   (`.kilo/agent/spec-analyst.md`), which may ask clarifying questions in
   plain chat before writing anything.
3. The analyst converts the description into Gherkin (Given/When/Then
   scenarios) and writes `spec/features/<domain>/<feature-slug>.feature`,
   listing every judgment call in a leading `# Analyst assumptions:`
   comment block.
4. The user reviews the file (the review gate). Once approved, the file is
   frozen: later changes go only through the analyst in revise mode.

## Progress log

- 2026-10-09 — Started the project. Analyzed PAM's spec-driven development
  (SDD) setup. Created `AGENTS.md` (minimal: project overview + MERN stack)
  and this README as the journal.
- 2026-10-09 — Every task must begin by checking whether `AGENTS.md` and
  this README need updating; recorded as an always-on rule in
  `.kilo/rules/core.md`.
- 2026-10-09 — Created first agent: `.kilo/agent/spec-analyst.md`
  (requirements → Gherkin feature files). Tried PAM-style root folders
  (agent/, rules/) bridged into `.kilo/` by symlinks; user chose
  everything-in-`.kilo/` instead — reverted, real files live in `.kilo/`
  now. Added rule: PAM is always consulted, but the user explicitly decides
  the style. Verification same day: `spec-analyst` registered and answered a
  probe correctly — agents load from `.kilo/agent/`; the write-time
  validator error is confirmed harmless noise.
- 2026-10-12 — Gathered the first feature spec:
  `spec/features/auth/register-login-logout.feature` (auth domain — user
  registration, login, logout; 11 scenarios, new-feature mode with
  `@req:new#…` tags since no domain docs exist yet). Key analyst assumptions
  awaiting critique: minimum password length 8, no auto-login after
  registering, one generic "invalid email or password" login error
  (anti-enumeration), idempotent logout. Out of scope per prompt: email
  verification, password reset, remember-me, social login, roles. One open
  `@todo`: email case-sensitivity. The `.feature` file is now frozen —
  later changes go through spec-analyst revise mode.
- 2026-10-19 — User-directed revise (spec-analyst): split the combined
  `spec/features/auth/register-login-logout.feature` into two narrower
  features — `spec/features/auth/register.feature` (6 registration
  scenarios) and `spec/features/auth/login-logout.feature` (5 login/logout
  scenarios) — and deleted the original. All scenario content, tags, and
  `@req:new#` ids are preserved byte-identical; the Background (empty user
  database) lives in both files; each file got a `# Analyst assumptions:`
  block adapted to its scope (cross-file scope-outs point at the sibling
  feature). Both files are frozen like any `.feature` file — changes go
   through spec-analyst revise mode.
- 2026-10-19 — Continuity verified: spawned a fresh general-agent subagent
  with zero conversation memory and asked it to report project status from
  files alone. It correctly identified: what the project is, current stage
  (gather phase complete, two frozen specs), open decisions (email
  case-sensitivity, doc-edit keep/revert), proposed next steps (implementer
  agent), and all working rules. Proof: everything a future agent needs
  lives in durable files (`AGENTS.md`, `.kilo/rules/core.md`, this README,
  the spec files). Created `.kilo/kilo.json` with blanket allow permissions
  (no more prompts for read/edit/bash/external-directory in this project).
- 2026-10-22 — Stack change: MERN → PERN (PostgreSQL replaces MongoDB). 
  Novel entry fields expanded: author, title, date of publishing, genre, 
  language, summary. Infrastructure requirements added: Docker for 
  containerization, Jenkins for CI/CD (triggered by pushes to external repo), 
  Playwright for E2E tests, Postman/Newman for API tests. Documentation 
  updated: `AGENTS.md` and `README.md` now reflect PERN stack and new 
  requirements. Repository layout extended with planned `docker/` and 
  `jenkins/` directories.
- 2026-10-23 — Updated interaction workflow rules in `.kilo/rules/core.md`:
  agents must check `.kilo/kilo.json` at session start for permissions, user
  provides feature descriptions (agents don't invent them), spec-analyst
  converts requirements to Gherkin. Novel fields finalized: required (author,
  Polish title, original title, year, genre), optional (picture from local
  upload with default book icon, description with "no description yet" default).
  Gathered novels domain specs: `spec/features/novels/novel-crud.feature`
  (36 scenarios covering CREATE, READ, UPDATE, DELETE with authentication,
  user isolation, validation, filtering by author/title/year, A-Z default
  sorting). The novels feature was frozen — changes go through spec-analyst
  revise mode.
- 2026-10-23 — Added a "Live rules" section to `.kilo/rules/core.md`: during
  any interaction the agent watches for conventions/decisions/recurring
  corrections and proposes rule updates (applied only after approval).
- 2026-10-23 — Split `spec/features/novels/novel-crud.feature` into four
  narrower feature files via spec-analyst revise mode: `create-novel.feature`
  (12), `view-novels.feature` (12), `edit-novel.feature` (8),
  `delete-novel.feature` (4); deleted the combined file. Scenarios preserved
  verbatim, each file given a scope-adapted `# Analyst assumptions:` block.
- 2026-10-23 — Resolved all open decisions and applied them to the specs
  (spec-analyst revise mode). No `@todo` remain:
  - Emails are case-insensitive; added `@req:new#register-email-case-insensitive`
    and `@req:new#login-email-case-insensitive` scenarios.
  - Author-surname filter is a case-insensitive substring match (assumption
    updated; scenarios unchanged).
  - Genre is a predefined dropdown (list recorded in assumptions); example
    genre values normalized to valid list entries; added
    `@req:new#novel-create-invalid-genre`.
  - Picture uploads limited to JPEG/PNG/WebP/GIF, max 5 MB; added
    `@req:new#novel-create-picture-invalid-format` and
    `@req:new#novel-create-picture-too-large`.
  A regression during the revise (the `logout-when-signed-out` scenario was
  dropped from `login-logout.feature`) was caught and restored. Final spec
  totals: 52 scenarios across 6 files (auth 13, novels 39).
- 2026-10-23 — Two user-directed spec revisions (spec-analyst revise mode):
  1. Removed the separate details view. The list shows all fields for every
     novel; the description is a short inline preview (~first 10 words) plus a
     "See more" control opening a scrollable pop-up with the full text.
     `view-novels.feature` dropped the 4 `novel-view-single-*` scenarios and
     gained 6 list scenarios (all-fields, preview-truncated, see-more-popup,
     short-description, no-description, no-picture-default-icon).
  2. Clarified per-entry (not per-book) isolation: the same book can exist in
     several users' collections as separate entries. The cross-user scenarios
     `novel-list-only-own-novels`, `novel-update-other-user-novel-denied`, and
     `novel-delete-other-user-novel-denied` were rewritten so both users own a
     copy of the same book and one user's action never touches another's entry.
  Final spec totals: 54 scenarios across 6 files (auth 13, novels 41).
- 2026-10-23 — Added a "Design inputs" rule to `.kilo/rules/core.md`: written
  requirements/spec docs are gather-stage inputs (converted to `.feature` by
  the spec-analyst); UI designs/wireframes are client-implementation inputs
  (stored under `spec/domains/<domain>/ui/` when kept in-repo). Neither
  overrides a frozen `.feature`. Removed the now-redundant "READ scenarios
  (list view)" separator comment from `view-novels.feature`.
- 2026-10-23 — Decided to adopt a PAM-inspired multi-agent pipeline (PAM
  option C) instead of a single do-everything implementer: agents for
  specific stages (critique, design, test-authoring, implementation, review,
  documentation) plus an orchestrator. Roster proposed; agents to be created
  one at a time.
- 2026-10-23 — Introduced the PAM-style requirements layer. Added
  `spec/domains/<domain>/requirements.md` (numbered EARS rules, English) as
  the source of truth for business rules, with `.feature` scenarios tracing to
  `@req:<domain>#REQ-nnn`. Created `spec/domains/auth/requirements.md`
  (REQ-001…REQ-012). Recorded the "automatic driver / foreman" (PAM
  orchestrator + chain command) in `.kilo/rules/core.md` as a documented
  FUTURE option — not adopted yet; we keep manual step-by-step control.
  Novels requirements drafted and awaiting approval before creation; tags not
  yet re-pointed.
- 2026-10-23 — Requirements layer completed and tags re-pointed. Created
  `spec/domains/novels/requirements.md` (REQ-001…REQ-033). Wrote the two-layer
  model into `.kilo/rules/core.md` and `AGENTS.md` (requirements = rules of
  record; `.feature` = examples tracing to them), and drafted the flow: the
  user provides plain-English input → spec-analyst writes/updates the numbered
  requirements → the user approves → spec-analyst writes the tagged Gherkin →
  the user freezes it. Gave the `spec-analyst` scope over
  `spec/domains/**/requirements.md` (so it owns both layers) and updated its
  description. Re-pointed all 54 scenario tags from `@req:new#…` to canonical
  `@req:auth#REQ-nnn` /   `@req:novels#REQ-nnn` (56 tag lines; `novel-create-success`
  carries three). No `@req:new#` remains in `spec/features/`.
- 2026-10-23 — Step 1 of UI refinement: updated
  `spec/domains/novels/requirements.md` — genre is now one-or-more
  (REQ-001/006/008 reworded), and added REQ-034 (mark a novel as a favourite,
  shown with an asterisk), REQ-035 (filter to favourites only), REQ-036
  (clicking a picture opens a larger view). Gherkin scenarios for the three
  new rules follow in a later step (not yet written). Presentation-only wishes
  (plain text boxes, numeric year field, thumbnail picture, growing
  description box) are deferred to a UI design note, not Gherkin.
- 2026-10-23 — Step 2: wrote the Gherkin examples for the new rules (spec-analyst
  revise mode). `create-novel.feature`: +1 "more than one genre" scenario and
  the "no genre selected" wording (16 total). `edit-novel.feature`: +3 favourite
  scenarios — mark, unmark, and favourite-belongs-to-owner (11 total).
  `view-novels.feature`: +2 scenarios — favourites-only filter and
  click-picture-opens-larger-view (16 total). Updated the traceability table in
  `spec/domains/novels/requirements.md` (REQ-001, REQ-008, REQ-034, REQ-035,
  REQ-036). Final spec totals: 60 scenarios across 6 files (auth 13, novels 47).
- 2026-10-23 — Step 3: captured the presentation-only wishes as UI design
  notes (proposed and approved before creation). Created
  `spec/domains/novels/ui/novel-form.ui.md` (field controls: text boxes for
  author/both titles, numeric year field with spinner, multi-select genre,
  thumbnail picture, auto-growing description box, favourite toggle) and
  `spec/domains/novels/ui/novel-list.ui.md` (filter bar, favourites filter,
  per-row thumbnail + preview, Edit/Delete actions). Both are marked
  visual-only, not the behavioural source of truth. `AGENTS.md` now documents
  the third spec layer (`ui/`).
- 2026-10-23 — Step 4: started the PAM-inspired pipeline (option C), one agent
  at a time. Created the active `spec-critic` agent (`.kilo/agent/spec-critic.md`)
  — PAM-exact: always writes a per-feature
  `spec/features/<domain>/<feature-slug>.review.md` (Blocking issues, Warnings,
  Edge cases missed, Coverage gaps, Suggested scenarios; verdict
  `Approved for design` / `Changes required`); never edits specs; the review
  file gates the design stage. Added the SUSPENDED
  orchestrator ("foreman") at `.kilo/suspended-agents/spec-orchestrator.md` —
  deliberately outside `.kilo/agent/` so Kilo does not load it. Documented the
  agent roster and pipeline in `AGENTS.md`. Next pipeline agents to create:
  architect, test-author, implementer, reviewer, documenter.
- 2026-10-23 — Step 5: created the slash commands for the existing agents
  (`.kilo/command/spec-gather.md`, `.kilo/command/spec-critique.md`) — this is
  the normal way stages run (`/spec-critique <domain>/<feature-slug>`). Ran the
  critic on all six features, producing per-feature review files:
  `register.review.md`, `login-logout.review.md` (both Approved for design, 0
  blocking), `create-novel.review.md` (**Changes required**, 1 blocking),
  `view-novels.review.md`, `edit-novel.review.md`, `delete-novel.review.md`
  (Approved for design). Blocking issue: the create form UI note adds a
  favourite control with no backing rule/scenario. Awaiting decision.
- 2026-10-23 — Resolved the critique. Decision: mark a novel as a favourite at
  creation is allowed (option A). Routed fixes through the spec-analyst:
  novels requirements gained REQ-037 (favourite at creation), REQ-038 (valid
  picture stored/shown), REQ-039 (provided description stored/shown), and
  REQ-007 was made explicit (4-digit year 1000–9999). Added scenarios:
  create-novel favourite-at-creation, boundary-year outline (1000/9999),
  exactly-5 MB picture, mixed allowed+disallowed genres, whitespace-only author;
  re-tagged picture/description success scenarios; aligned genre and year
  error messages. Auth: added exactly-8-character password and whitespace-only
  email scenarios; made logout-when-signed-out observable. UI note fixed
  (favourite backed by REQ-037; removed list-only enlarge from the form; Cancel
  marked as navigation). Final totals: 67 scenarios (auth 15, novels 52); 39
  novels REQs + 12 auth REQs. Re-ran the critic on the four changed features —
  `create-novel`, `edit-novel`, `register`, `login-logout` — all now
  **Approved for design**, 0 blocking; only minor warnings remain.
- 2026-10-23 — Step 6: created the design stage. Added the `spec-architect`
  agent (`.kilo/agent/spec-architect.md`) and the `spec-design` command. The
  architect turns an `Approved for design` feature into
  `spec/features/<domain>/<feature-slug>.design.md` (API contract, PostgreSQL
  data model, UI plan, test plan, traceability) and maintains
  `spec/domains/<domain>/data-model.md`; it never edits specs or code. Reviewed
  answers on workflow: describe the domain broadly first then per feature;
  critique is per feature (PAM); `--revise` is the analyst's "change a frozen
  spec" mode; the orchestrator would normally chain stages automatically but we
  trigger commands manually; PAM accepts a large documentation set by design.
- 2026-10-23 — Step 7: ran the design stage (spec-architect) on both domains.
  Wrote per-feature design docs — `spec/features/auth/{register,login-logout}.design.md`
  and `spec/features/novels/{create-novel,view-novels,edit-novel,delete-novel}.design.md`
  — plus shared data models `spec/domains/auth/data-model.md` and
  `spec/domains/novels/data-model.md`. Auth: `users` + `sessions` (hashed
  password, case-insensitive email), endpoints register/login/logout/me, httpOnly
  session cookie, single generic login error. Novels: `novels` (FK to user,
  year check 1000–9999, favourite flag, picture ref) + `novel_genres` join table
  (chosen over a Postgres array), endpoints list/create/get/patch/delete/picture/
  genres, per-entry ownership scoping, indexes for A-Z, year, favourites, and
  author/title search. No spec-change blockers.
- 2026-10-23 — Numbered the agents by pipeline stage and added stages 4–5.
  Renamed `.kilo/agent/spec-analyst.md` → `01-spec-analyst.md`,
  `spec-critic.md` → `02-spec-critic.md`, `spec-architect.md` →
  `03-spec-architect.md`; created `04-spec-test-author.md` and
  `05-spec-implementer.md`. Added commands `spec-test`, `spec-implement` and
  updated the existing commands' `agent:` fields. Stage 6 (review) and 7
  (document) still to come.
- 2026-10-23 — Step 9: scaffolded the project (spec-implementer). Created a
  minimal runnable PERN skeleton in plain JavaScript: root workspace
  `package.json`, `.gitignore`, `.env.example`, `.dockerignore`; `server/`
  (Express + `pg` + cookie-parser, `GET /health`, `src/migrate.js`, empty
  `migrations/0001_init.sql`); `client/` (Vite + React, health check); `tests/`
  (Playwright config + `e2e/`, Postman collection + Newman in `api/`); `docker/`
  (server/client Dockerfiles + compose with postgres:16); `jenkins/Jenkinsfile`.
  Defaults chosen (flagged): JavaScript not TypeScript; raw SQL migrations with
  `node-postgres`, no ORM. No product features implemented yet; `/health` is the
  only endpoint. `npm install`/test runs not executed here (no registry access);
  run locally to confirm.
- 2026-10-23 — Project moved from `MyStudy/NovelTracker` to
  `Desktop/Private/NovelTracker`; all specs, agents, commands, and scaffold
  verified intact.
- 2026-10-23 — Added a continuity guarantee so any session/window can resume.
  Created `STATUS.md` (root) as the single source of truth: how to resume, a
  per-feature stage table (gather→critique→design→test→implement), the exact
  next action, pending conventions, run commands, and where details live. Added
  a "Continuity" rule to `.kilo/rules/core.md` requiring every session to read
  `STATUS.md` first and update it before finishing; pointed `AGENTS.md` and this
  README at it.
- 2026-10-23 — Applied the PAM state/log split (option A): `STATUS.md` is the
  single state snapshot (stage table + next action + conventions + run
  commands); README's duplicated "Current state" block was replaced by a short
  pointer, so this file is purely the history log. Resolved product decisions
  remain in `AGENTS.md`. One state source, one log — no drift.
- 2026-10-23 — Step 10: ran the test stage (04-spec-test-author) for the auth
  domain. Wrote API tests `tests/api/auth.postman_collection.json` (22 requests,
  each tagged `@req:auth#REQ-nnn`) + `auth.postman_environment.json`, and
  Playwright UI tests `tests/e2e/auth/register.spec.js` (10) and
  `login-logout.spec.js` (6) with a shared `helpers.js`. Tests drive the real UI
  via the design's `data-testid` hooks (no API mocking) and are expected to fail
  red until the implementer builds the auth endpoints/UI. Updated
  `tests/package.json` `test:api` to run both collections.
