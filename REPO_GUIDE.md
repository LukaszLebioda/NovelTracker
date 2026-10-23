# NovelTracker — Repository Files

## Root

| File | What it is | What it does | Important? |
|---|---|---|---|
| `.dockerignore` | Container build ignore list | Tells Docker which files to exclude when building images (secrets, node_modules, build artifacts) | Yes — keeps images small and secure |
| `.env.example` | Environment variables template | Sample showing required settings (DATABASE_URL, PORT, SESSION_SECRET). Copy to `.env` locally. | Yes — but duplicated in `server/.env.example` |
| `.gitignore` | Git ignore list | Tells git which files not to track (secrets, node_modules, build output, Kilo state) | Yes — prevents secrets leaking |
| `AGENTS.md` | AI agent briefing | Always-loaded project overview: stack (PERN), spec layout, agent roster, resolved decisions | Yes — AI sessions need this |
| `package.json` | Workspace manifest | Declares npm workspaces (server, client, tests) and top-level commands (dev:server, test:api, migrate) | Yes — the switchboard |
| `README.md` | Project journal | Human-facing: what the project is, stack, layout, dated progress log of decisions and work done | Yes — the history book |
| `REPO_GUIDE.md` | This file | File-by-file guide for the project owner | Reference |
| `STATUS.md` | Current state snapshot | Stage table, exact next action, pending decisions, how to run. Read this first in any session. | Yes — the resume point |

## .kilo/

AI workflow configuration. Defines who does what, in what order, with what permissions.

| File | What it is | What it does | Important? |
|---|---|---|---|
| `kilo.json` | Permissions config | What AI may do without asking (read/edit allowed, rm denied, mv asks, etc.) | Yes — the guardrails |
| **agent/** | | | |
| `01-spec-analyst.md` | Requirements → Gherkin agent | Turns plain-language descriptions into numbered requirements and executable scenarios. Only agent allowed to edit specs. | Yes |
| `02-spec-critic.md` | Spec review agent | Critiques specs for correctness/completeness. Writes `.review.md` verdict. Never edits specs. | Yes |
| `03-spec-architect.md` | Design agent | Turns approved features into technical designs (API contract, DB schema, UI plan, test plan). Never edits specs or code. | Yes |
| `04-spec-test-author.md` | Test authoring agent | Writes automated tests (Playwright UI + Postman API) before the feature exists (red phase) | Yes |
| `05-spec-implementer.md` | Implementation agent | Writes application code until tests pass (green phase) | Yes |
| **command/** | | | |
| `spec-gather.md` | Slash command | Runs 01-spec-analyst | Yes |
| `spec-critique.md` | Slash command | Runs 02-spec-critic | Yes |
| `spec-design.md` | Slash command | Runs 03-spec-architect | Yes |
| `spec-test.md` | Slash command | Runs 04-spec-test-author | Yes |
| `spec-implement.md` | Slash command | Runs 05-spec-implementer | Yes |
| **rules/** | | | |
| `core.md` | Always-on rules | Session-start checks, continuity duties, spec-driven workflow, live rules. Loaded by every AI session. | Yes |
| **suspended-agents/** | | | |
| `spec-orchestrator.md` | Automatic pipeline driver (switched off) | Would run whole pipeline stage-to-stage automatically. Kept as future option, deliberately not loaded. | Reference |

## spec/

The specifications — what the product must do.

### spec/domains/

| File | What it is | What it does | Important? |
|---|---|---|---|
| `auth/requirements.md` | Auth business rules | 12 numbered requirements (REQ-001 to REQ-012) for registration, login, logout | Yes — source of truth |
| `auth/data-model.md` | Auth database model | Describes `users` and `sessions` tables | Yes |
| `novels/requirements.md` | Novels business rules | 39 numbered requirements (REQ-001 to REQ-039) for novel CRUD, validation, filtering, favourites | Yes — source of truth |
| `novels/data-model.md` | Novels database model | Describes `novels` and `novel_genres` tables | Yes |
| `novels/ui/novel-form.ui.md` | Form screen layout | Visual notes for create/edit form (text boxes, numeric year, multi-select genre, thumbnail, growing description) | Yes — UI reference |
| `novels/ui/novel-list.ui.md` | List screen layout | Visual notes for list (filter bar, favourites filter, per-row thumbnail + preview, Edit/Delete) | Yes — UI reference |

### spec/features/

Each feature has 3 files: `.feature` (scenarios), `.review.md` (critic verdict), `.design.md` (technical design).

| File | What it is | Scenarios | Important? |
|---|---|---|---|
| `auth/register.feature` | Registration scenarios (Given/When/Then) | 9 | Yes — frozen spec |
| `auth/register.review.md` | Registration review verdict | — | Yes — gates design |
| `auth/register.design.md` | Registration technical design | — | Yes |
| `auth/login-logout.feature` | Login/logout scenarios | 6 | Yes — frozen spec |
| `auth/login-logout.review.md` | Login/logout review verdict | — | Yes — gates design |
| `auth/login-logout.design.md` | Login/logout technical design | — | Yes |
| `novels/create-novel.feature` | Create novel scenarios | 21 | Yes — frozen spec |
| `novels/create-novel.review.md` | Create novel review verdict | — | Yes — gates design |
| `novels/create-novel.design.md` | Create novel technical design | — | Yes |
| `novels/view-novels.feature` | View/filter novels scenarios | 16 | Yes — frozen spec |
| `novels/view-novels.review.md` | View novels review verdict | — | Yes — gates design |
| `novels/view-novels.design.md` | View novels technical design | — | Yes |
| `novels/edit-novel.feature` | Edit novel scenarios | 11 | Yes — frozen spec |
| `novels/edit-novel.review.md` | Edit novel review verdict | — | Yes — gates design |
| `novels/edit-novel.design.md` | Edit novel technical design | — | Yes |
| `novels/delete-novel.feature` | Delete novel scenarios | 4 | Yes — frozen spec |
| `novels/delete-novel.review.md` | Delete novel review verdict | — | Yes — gates design |
| `novels/delete-novel.design.md` | Delete novel technical design | — | Yes |

**Total: 67 scenarios across 6 features (auth 15, novels 52)**

## server/

The backend — Express.js API on Node.js, talking to PostgreSQL.

| File | What it is | What it does | Important? |
|---|---|---|---|
| `package.json` | Backend manifest | Dependencies (express, pg, cookie-parser, bcryptjs) and scripts (dev, start, migrate) | Yes |
| `.env.example` | Backend settings template | Same as root `.env.example` | Duplicate — remove one |
| `src/index.js` | Server entry point | Starts web server, wires JSON parsing + cookies. Only endpoint today: GET /health | Yes |
| `src/db.js` | Database connection | Creates shared PostgreSQL connection pool | Yes |
| `src/migrate.js` | Migration runner | Finds SQL files in migrations/ and applies them in order | Yes |
| `migrations/0001_init.sql` | First migration | Empty placeholder. Real tables come later when features are implemented. | Placeholder — keeps convention |

## client/

The frontend — React app via Vite. Currently a shell showing API health.

| File | What it is | What it does | Important? |
|---|---|---|---|
| `package.json` | Frontend manifest | React + Vite dependencies and scripts (dev, build, preview) | Yes |
| `index.html` | The web page | Browser starting point. Contains `<div id="root">` for React | Yes |
| `vite.config.js` | Build tool config | Dev port (5173), proxies /api and /health calls to backend (port 3000) | Yes |
| `src/main.jsx` | React bootstrap | Mounts React app into the page | Yes |
| `src/App.jsx` | Root component | Shows "NovelTracker" and API health status. Will host screens (register, login, novel list, forms) | Yes |

## tests/

Automated tests — UI (Playwright) and API (Postman/Newman).

| File | What it is | What it does | Important? |
|---|---|---|---|
| `package.json` | Test workspace manifest | Playwright + Newman dependencies and scripts (test:api, test:e2e) | Yes |
| `playwright.config.js` | Playwright settings | Browser test config (port 5173, trace on retry) | Yes |
| `api/README.md` | API test instructions | How to run API tests | Could merge into root README |
| `api/noveltracker.postman_collection.json` | Baseline API test | Minimal collection: checks GET /health | Yes — smoke test |
| `api/auth.postman_collection.json` | Auth API tests | 22 requests for registration/login/logout, each traced to REQ-nnn | Yes |
| `api/auth.postman_environment.json` | API test settings | Variables like baseUrl | Yes |
| `e2e/.gitkeep` | Empty folder placeholder | Keeps e2e/ folder in git | Standard practice |
| `e2e/auth/helpers.js` | Shared test utilities | Reusable helpers (register/login via API, unique emails, UI wording constants) | Yes |
| `e2e/auth/register.spec.js` | Registration UI tests | 10 browser scenarios for registration screen | Yes |
| `e2e/auth/login-logout.spec.js` | Login/logout UI tests | 6 browser scenarios for sign in/out | Yes |

## docker/

Containerization setup.

| File | What it is | What it does | Important? |
|---|---|---|---|
| `Dockerfile.server` | Backend container recipe | How to package API into a runnable image | Yes |
| `Dockerfile.client` | Frontend container recipe | How to package UI into a runnable image | Yes |
| `docker-compose.yml` | Local multi-service launcher | Starts whole system locally: PostgreSQL 16 + backend + frontend, wired together | Yes |

## jenkins/

CI/CD pipeline.

| File | What it is | What it does | Important? |
|---|---|---|---|
| `Jenkinsfile` | Automated build pipeline | When code is pushed: install deps, run tests, build container images | Yes |

## Summary

- **Total files (excluding PAM):** 72
- **Essential:** 69
- **Duplicates to merge:** 2 (`.env.example` root vs server, `tests/api/README.md`)
- **Placeholders:** 2 (`.gitkeep`, empty migration)
