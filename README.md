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

| Component            | Technology                                     |
| -------------------- | ---------------------------------------------- |
| **Database**         | PostgreSQL                                     |
| **Backend**          | Express.js (Node.js)                           |
| **Frontend**         | React                                          |
| **Containerization** | Docker                                         |
| **CI/CD**            | Jenkins (triggered by pushes to external repo) |
| **E2E Testing**      | Playwright                                     |
| **API Testing**      | Postman/Newman                                 |

## Repository layout

```text
NovelTracker/
├── AGENTS.md        auto-loaded by the AI agents (incl. Current status)
├── README.md        this file — human documentation + history
├── .kilo/           AI config: agents, commands, rules, permissions
├── spec/            the specifications (what the product must do)
│   ├── domains/<domain>/    requirements.md, data-model.md, ui/ notes
│   └── features/<domain>/   *.feature, *.review.md, *.design.md
├── app/             the runnable product
│   ├── server/      Express API (src/, migrations/)
│   ├── client/      React UI (Vite)
│   ├── tests/       Playwright (e2e/) + Postman/Newman (api/)
│   ├── docker/      Dockerfiles + docker-compose
│   └── jenkins/     Jenkinsfile pipeline
└── PAM/             reference project (not part of NovelTracker)
```

Two layers: **process at the root** (`.kilo/`, `spec/`, `AGENTS.md`, `README.md`)
and **product under `app/`** (all code and infrastructure).

- **`.kilo/`** holds all AI config (agents, commands, rules, permissions) and
  must stay at the root — Kilo discovers it (and `AGENTS.md`) by walking up from
  the working directory.
- **`spec/`** has two parts:
  - `domains/<domain>/` — `requirements.md`, the numbered rules of record
    (`REQ-001`…, each written as one "When …, the system must …" EARS sentence),
    plus the shared `data-model.md` and low-fidelity `ui/` notes.
  - `features/<domain>/` — the frozen `*.feature` scenarios, each with its
    `*.review.md` verdict and `*.design.md` design.
- **`app/`** is an npm workspace with `server`, `client`, `tests`, `docker`, and
  `jenkins`; all application code and infrastructure live here.
- **`PAM/`** is a separate reference project kept as a model — NovelTracker does
  not use it at runtime.

## How to run locally

The repo is an npm **workspace** (monorepo): a single root `npm install`
installs `app/server`, `app/client`, and `app/tests` together (one shared
`node_modules/` and lockfile), and the commands below are root shortcuts into
those packages (`npm --workspace <path> run <script>`).

From the repository root: `npm install` → `cp .env.example .env` →
`npm run migrate` → `npm run dev:server` (:3000) + `npm run dev:client` (:5173);
`npm run test:api` (Newman) and `npm run test:e2e` (Playwright);
`docker compose -f app/docker/docker-compose.yml up --build`.

## Project status

The current stage, the exact next action, the pipeline stage table, and the
pending conventions live in **`AGENTS.md` → "Current status"** — the file the AI
agents load automatically, and the single source of truth. This README is for
humans: what the project is, how to run it, how the pipeline works, and the
history log.

## Workflow: From Plain English to Running Code

**Example scenario:** You want users to be able to save memorable quotes from their novels.

---

### Your Plain-English Input (what you type)

```
/spec-gather Users should be able to save memorable quotes from their novels —
the quote text plus an optional page number. A quote is at most 500 characters.
Only the owner can see or edit their quotes.
```

### Why two documents (requirements + features)

For every feature the analyst writes **two** files from the same plain-English
input. They do different jobs:

|            | `requirements.md`                         | `*.feature`                              |
| ---------- | ----------------------------------------- | ---------------------------------------- |
| What it is | the **rules** — what must be true         | **examples** — a rule in action          |
| Looks like | numbered plain-English sentences (EARS)   | Given/When/Then scenarios with real data |
| Read by    | you / the business                        | the test-writer and the implementer      |
| Its job    | the **rules of record** (source of truth) | the **executable contract** (frozen)     |
| Answers    | "what must the system do?"                | "how would we _see_ it doing that?"      |

In one line: the rules say **what must be true**; the scenarios **show it
happening**.

**Why not just one?** A rule states the intent, but it rarely contains the cases.
`REQ-001` ("save a quote — up to 500 characters, optional page, private to the
owner") says nothing about what happens _at_ the boundary. Pinning that down takes
two more scenarios:

- exactly 500 characters → accepted
- 501 characters → rejected

So one rule maps to one or more scenarios. The whole quotes feature is a single
rule with five scenarios:

| Rule | Scenario that proves it |
| --- | --- |
| `REQ-001` — save a quote (up to 500 chars, optional page, private to owner) | Save a quote |
| `REQ-001` | Save without a page number |
| `REQ-001` | Quotes are private to their owner |
| `REQ-001` | Exactly 500 characters → accepted |
| `REQ-001` | 501 characters → rejected |

The rules give the intent and a readable summary; the scenarios give the
concrete, testable detail. You need both.

**Why the `REQ-nnn` ids.** They let everything point at one rule without quoting
it:

- a scenario tags the rule it proves — `@req:quotes#REQ-001`;
- the test inherits that tag, so a failure names the rule;
- the critic checks every rule has a scenario and every scenario traces to a rule;
- you can say "change REQ-001" unambiguously.

Ids are never renumbered or reused, so the wording can be refined while the
anchor stays put.

**Order:** rules first, then scenarios — each scenario must trace to a rule that
already exists.

### Stage 1: Gather (spec-analyst)

**You run:** `/spec-gather Users should be able to save memorable quotes from their novels`

**What happens:**

1. Kilo loads `.kilo/agent/spec-analyst.md` (the only agent allowed to touch specs)
2. Agent loads `AGENTS.md` + `.kilo/rules/core.md` (always-on briefing + rules)
3. Agent checks whether the `quotes` domain already exists — it does not, so this is a **brand-new domain**: there is nothing to read and it starts from scratch. (If the domain existed, it would read its `requirements.md` first to continue the numbering.)
4. Agent may ask you clarifying questions (e.g., "Page number optional? Max length? Private per user?")
5. Agent **creates** `spec/domains/quotes/requirements.md` — the first rule, REQ-001, in EARS form ("When a user saves a quote for a novel they own, the system must …")
6. Agent **creates** `spec/features/quotes/add-quote.feature` — Gherkin scenarios (Given/When/Then), each tagged `@req:quotes#REQ-001` pointing back to the rule
7. Agent prints `[STATUS] quotes/add-quote gathered done`
8. **You review and approve** — the `.feature` file is now **frozen**; future changes go only through the analyst in `--revise` mode

**Files created/updated:**

- ➕ `spec/domains/quotes/requirements.md` (new — REQ-001)
- ➕ `spec/features/quotes/add-quote.feature` (new)

**Example output — `spec/domains/quotes/requirements.md` (excerpt):**

```markdown
### REQ-001 — Save a quote from a novel | must | draft

**Requirement:** When a user saves a quote for a novel they own, the system must
store the quote text (up to 500 characters) and an optional page number with
that novel.
**Why it matters:** Readers want to keep the lines they loved.
```

**Example output — `spec/features/quotes/add-quote.feature`:**

```gherkin
Feature: Novel quotes
  As a reader
  I want to save memorable quotes from my novels
  So I can revisit the lines I loved

# Analyst assumptions:
# - [INFERRED] A quote belongs to a novel the user owns (per-entry isolation)
# - [DECIDED] Maximum 500 characters (from the prompt)
# - [INFERRED] The page number is optional
# - [SCOPE-OUT] Editing / deleting a quote (a separate feature)
# - [SCOPE-OUT] Sharing quotes

Background:
  Given the database is empty
  And user "reader@example.com" is registered and logged in

Scenario: Save a quote
  @req:quotes#REQ-001
  Given the user owns a novel "Dune"
  When the user saves the quote "Fear is the mind-killer." on page 12
  Then the quote is saved
  And when the user views the novel, they see the quote "Fear is the mind-killer."

Scenario: Save a quote without a page number
  @req:quotes#REQ-001
  Given the user owns a novel "Dune"
  When the user saves the quote "Fear is the mind-killer."
  Then the quote is saved with no page number

Scenario: Quotes are private to their owner
  @req:quotes#REQ-001
  Given user "alice@example.com" owns a novel "Dune" with the quote "Alice's line"
  And user "bob@example.com" owns a novel "Dune"
  When Bob views his copy of "Dune"
  Then Bob sees no quotes
  And Alice's quote remains unchanged

Scenario: Quote within 500 characters is accepted
  @req:quotes#REQ-001
  Given the user owns a novel "Dune"
  When the user saves a quote of exactly 500 characters
  Then the quote is saved

Scenario: Quote exceeding 500 characters is rejected
  @req:quotes#REQ-001
  Given the user owns a novel "Dune"
  When the user saves a quote of 501 characters
  Then the system shows the error "The quote must be 500 characters or fewer."
  And the quote is not saved
```

---

### Stage 2: Critique (spec-critic)

**You run:** `/spec-critique quotes/add-quote`

**What happens:**

1. Kilo loads `.kilo/agent/spec-critic.md`
2. Agent **reads** `spec/features/quotes/add-quote.feature` (the scenarios you just froze)
3. Agent **reads** `spec/domains/quotes/requirements.md` (checks every scenario traces to a rule)
4. Agent checks: correctness, completeness, coverage, edge cases, contradictions
5. Agent **writes** `spec/features/quotes/add-quote.review.md` with verdict:
   - **"Approved for design"** → you can continue
   - **"Changes required"** (blocking issues) → run `/spec-gather quotes/add-quote --revise` to fix the spec first
6. Agent prints `[STATUS] quotes/add-quote critiqued done`

**Files created:**

- ➕ `spec/features/quotes/add-quote.review.md` (verdict + warnings)

**Example output — `spec/features/quotes/add-quote.review.md`:**

```markdown
# Feature Review: Novel Quotes

**Feature:** `quotes/add-quote`
**Date:** 2026-10-26
**Reviewer:** spec-critic
**Verdict:** ✅ **Approved for design**

## Summary

The feature spec defines 5 scenarios covering saving a quote with/without a page
number, per-owner privacy, and the 500-character limit. All scenarios trace
cleanly to REQ-001.

## Blocking Issues

None.

## Warnings

1. **Edge case:** What happens if a user saves a quote for a novel they don't
   own? The spec doesn't state it explicitly. Recommendation: rely on the novels
   domain's ownership checks — document the assumption.

## Coverage Gaps

None — the 500-character boundary is tested (exactly 500 = pass, 501 = fail).

## Suggested Scenarios (optional)

- **Whitespace-only quote:** Should a quote containing only spaces be rejected?
  (Low priority — can defer.)

## Traceability

| Scenario                           | Requirement |
| ---------------------------------- | ----------- |
| Save a quote                       | REQ-001     |
| Save a quote without a page number | REQ-001     |
| Quotes are private to their owner  | REQ-001     |
| Quote within 500 characters        | REQ-001     |
| Quote exceeding 500 characters     | REQ-001     |

All scenarios covered. ✅
```

---

### Stage 3: Design (spec-architect)

**You run:** `/spec-design quotes/add-quote`

**What happens:**

1. Kilo loads `.kilo/agent/spec-architect.md`
2. Agent **reads** `spec/features/quotes/add-quote.feature`, `add-quote.review.md`, `spec/domains/quotes/requirements.md`
3. Agent **checks** `spec/domains/quotes/data-model.md` — it does not exist yet, so it plans a new data model for the domain
4. Agent decides:
   - Database change: a new `quotes` table (`id`, `user_id`, `novel_id`, `text`, `page` nullable) with a foreign key to `novels` → writes migration plan
   - API: `POST /api/novels/:id/quotes` accepts `{ text, page? }` → writes contract
   - UI: a "Quotes" section on the novel row with an add control → writes component plan
   - Tests: which scenarios are API-only, which are UI → writes test plan
5. Agent **writes** `spec/features/quotes/add-quote.design.md` (complete technical design)
6. Agent **creates** `spec/domains/quotes/data-model.md` (the new `quotes` table)
7. Agent prints `[STATUS] quotes/add-quote designed done`

**Files created/updated:**

- ➕ `spec/features/quotes/add-quote.design.md` (new)
- ➕ `spec/domains/quotes/data-model.md` (new)

---

### Stage 4: Test (spec-test-author) — Red Phase

**You run:** `/spec-test quotes/add-quote`

**What happens:**

1. Kilo loads `.kilo/agent/spec-test-author.md`
2. Agent **reads** `spec/features/quotes/add-quote.feature`, `.design.md`, `data-model.md`
3. Agent **reads** existing test helpers in `app/tests/e2e/auth/helpers.js` (to reuse the login patterns)
4. Agent **writes** `app/tests/e2e/quotes/add-quote.spec.js` (Playwright browser tests — one `test()` per Gherkin scenario, each carrying the `@req:quotes#REQ-001` tag in the test name or a comment)
5. Agent **creates** `app/tests/api/quotes.postman_collection.json` (Newman API tests for the new endpoint)
6. Agent runs the tests → they **fail** (red phase) because the feature doesn't exist yet
7. Agent prints `[STATUS] quotes/add-quote tested-red done`

**Files created/updated:**

- ➕ `app/tests/e2e/quotes/add-quote.spec.js` (new Playwright tests)
- ➕ `app/tests/api/quotes.postman_collection.json` (new API collection)
- ✏️ `app/tests/package.json` (wired the new collection into `test:api`)

---

### Stage 5: Implement (spec-implementer) — Green Phase

**You run:** `/spec-implement quotes/add-quote`

**What happens:**

1. Kilo loads `.kilo/agent/spec-implementer.md`
2. Agent **reads** `spec/features/quotes/add-quote.feature`, `.design.md`, `data-model.md`, and the new tests in `app/tests/`
3. Agent **writes** `app/server/migrations/0004_add_quotes_table.sql` (creates the `quotes` table — next free migration number)
4. Agent **creates** `app/server/src/routes/quotes.js` — the `POST /api/novels/:id/quotes` handler (validates length, checks ownership, inserts)
5. Agent **creates** `app/client/src/components/QuoteForm.jsx` — the add-quote control and quote list
6. Agent **wires** the new route in `app/server/src/index.js`
7. Agent runs the tests → they **pass** (green phase)
8. Agent prints `[STATUS] quotes/add-quote implemented done`

**Files created/updated:**

- ➕ `app/server/migrations/0004_add_quotes_table.sql` (new migration)
- ➕ `app/server/src/routes/quotes.js` (new endpoint)
- ➕ `app/client/src/components/QuoteForm.jsx` (new component)
- ✏️ `app/server/src/index.js` (route wiring)

---

### Stages 6 & 7 (not yet created)

- **Stage 6: Review** — would verify implementation matches spec and run full test suite
- **Stage 7: Document** — would generate user/operator/dev docs from the feature

---

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
  `@req:auth#REQ-nnn` / `@req:novels#REQ-nnn` (56 tag lines; `novel-create-success`
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
- 2026-10-23 — Consolidated `.gitignore`: removed the nested `.kilo/.gitignore`
  and folded its rules into the single root `.gitignore` (Kilo state files:
  `.kilo/agent-manager.json` and `.kilo/` lockfiles; `node_modules` was already
  covered globally).
- 2026-10-23 — Created `REPO_GUIDE.md` (root): a plain-language, file-by-file
  explanation of every file in the repo — what it is, what it does, where it
  comes from, and whether it is essential/reference/mergeable — written for the
  project owner. Lists optional tidy-ups: delete `.DS_Store`, de-duplicate
  `.env.example` (root vs `server/`), fold `tests/api/README.md` into this
  README, and decide whether to archive the large reference-only `PAM/` folder.
  No product code touched.
- 2026-10-23 — Repository reorganized into "product" vs "process". Moved
  `server/`, `client/`, `tests/`, `docker/`, `jenkins/` and `.dockerignore` into
  a new `app/` folder (via `git mv`, history preserved); the process/spec layer
  (`.kilo/`, `spec/`, `README.md`, `STATUS.md`, `AGENTS.md`) stays at the root
  because Kilo discovers `.kilo/` and `AGENTS.md` by walking up from the working
  directory — they cannot be nested. Updated all dependent references: root
  `package.json` workspaces/scripts, `app/jenkins/Jenkinsfile`,
  `app/docker/Dockerfile.{server,client}` comments (build context is now `app/`),
  `app/tests/api/README.md`, the Kilo agent permission globs and prompts
  (`04-spec-test-author`, `05-spec-implementer`, both commands, `rules/core.md`,
  the suspended orchestrator), and the docs (`README.md`, `AGENTS.md`,
  `STATUS.md`, `REPO_GUIDE.md`). No behaviour change; Docker/Compose/Jenkins
  paths still line up.
- 2026-10-23 — Removed the separate status file. The status briefly lived at
  `.kilo/rules/status.md` (and before that at the repo root as `STATUS.md`); it is
  now folded into this README as the **"Current status — resume here"** section
  (stage table, next action, pending conventions, how to run, where the details
  live). One human document for the owner; `AGENTS.md` keeps the durable
  decisions. Deleted `STATUS.md`/`status.md`; updated the Continuity and
  "Done means documented" rules in `.kilo/rules/core.md`, the resume pointer in
  `AGENTS.md`, the README layout table, and `REPO_GUIDE.md`.
- 2026-10-26 — Documented the npm workspace (monorepo) model: added a
  "Workspaces — how the app/ folders are wired together" subsection to
  `REPO_GUIDE.md` (what workspaces are, the shared install/lockfile, and a
  root-command → package table) and a matching bullet to `AGENTS.md`.
- 2026-10-26 — Split the two docs by audience. All agent-facing content moved out
  of README into `AGENTS.md` (auto-loaded): the **"Current status (resume here)"**
  section (pipeline + stage table + next action + pending conventions + where the
  details live), the **"Key rules of the flow"**, and the Kilo tooling note.
  README is now for humans only — what it is, tech stack, repository layout, how
  to run locally, the pipeline walkthrough, and this history log — with a short
  "Project status" pointer to `AGENTS.md`. Removed README's duplicated "How we
  work" bullets (they were already covered by `.kilo/rules/core.md`). Updated the
  Continuity / Documentation-sync / "Done means documented" rules in
  `.kilo/rules/core.md` to point at `AGENTS.md`'s "Current status" instead of
  README.
- 2026-10-26 — Dropped the numeric prefixes from the agent names: `.kilo/agent/`
  now holds `spec-analyst.md`, `spec-critic.md`, `spec-architect.md`,
  `spec-test-author.md`, `spec-implementer.md` (renamed via `git mv`). Updated
  the `agent:` fields in all five `.kilo/command/*.md` files, the stage→agent
  table in the suspended orchestrator, the roster in `AGENTS.md`, the agent paths
  in the README walkthrough, and removed the leading "4."/"5." from the test and
  implementer agent descriptions. Pipeline order is unchanged.
- 2026-10-26 — Rewrote the README walkthrough around a **brand-new domain** so
  the flow reads naturally: the example is now the new `quotes` domain
  (feature `quotes/add-quote`, rules REQ-001/REQ-002), where the analyst
  **creates** `requirements.md` from scratch instead of reading an existing one.
  Updated every stage (gather/critique/design/test/implement) and the example
  outputs (requirements, Gherkin, review) to `quotes`, including a brand-new
  `spec/domains/quotes/data-model.md` and a new `quotes` table. Replaced the
  previous notes-in-novels example.
- 2026-10-26 — Added a "Why two documents (requirements + features)" box to the
  README walkthrough (before Stage 1): the roles of `requirements.md` vs
  `*.feature`, why one rule needs several scenarios (with the `REQ-001`/`REQ-002`
  mapping from the quotes example), and why the `REQ-nnn` ids exist
  (traceability, coverage checks, stable references).
- 2026-10-26 — Dropped "Acceptance criteria" from the requirements layer (it
  duplicated the scenarios). Removed all 12 blocks from
  `spec/domains/auth/requirements.md` and the 5 from
  `spec/domains/novels/requirements.md`; requirements are now one EARS rule plus
  a short "Why it matters" line only. Non-user-observable constraints stay in the
  design/data model (e.g. "passwords hashed, never plain text" is already in
  `spec/domains/auth/data-model.md`). Also normalized the missing blank line
  after `### REQ-nnn` headings in the novels file. Updated the convention text in
  `.kilo/rules/core.md` and the `spec-analyst` agent instructions (write rules,
  not acceptance criteria; the analyst writes the rule sentence + why), and the
  README walkthrough example. REQ ids, numbering, and traceability unchanged.
- 2026-10-26 — README example tidy-up: removed `REQ-002` (quote length limit)
  from the walkthrough — the 500-character limit now lives inside `REQ-001`'s
  rule and is proven only by the two boundary scenarios, so the quotes feature is
  a single rule with five scenarios. Updated the "Why two documents" box, the
  example requirements excerpt, the Gherkin tags (`@req:quotes#REQ-001`), and the
  review's summary/traceability accordingly. (Real spec files — auth, novels —
  are unchanged: this was the README example only.)
- 2026-10-26 — Renamed the assumption tag `[DERIVED]` → `[INFERRED]` (plainer
  wording, same meaning) across the repo: 42 occurrences in the six `.feature`
  files, the six `.review.md` files, the `spec-analyst`/`spec-critic` agent
  instructions, and the README example. The vocabulary is a convention declared
  in the agent prompts, not enforced in code — see `.kilo/agent/spec-analyst.md`.
