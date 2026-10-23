# AGENTS.md — Ultima-4.0 monorepo

This is the always-loaded repository baseline for AI agents. Load the matching
on-demand convention skill before implementing task-specific work:

- Backend changes: `.kilo/skills/backend-conventions/SKILL.md`
- Frontend changes: `.kilo/skills/frontend-conventions/SKILL.md`
- Frontend tests: `.kilo/skills/test-frontend/SKILL.md`
- Commit or release requests: `.kilo/skills/git-commits/SKILL.md`

## Repo layout

- **Monorepo**: Turborepo + Yarn workspaces (`apps/*`, `packages/*`). Use `yarn` exclusively, never npm or pnpm.
- **Apps** (2, post-consolidation): `apps/pam-api` (all backend), `apps/pam-ui` (all UI).
- **Shared packages**: `packages/contracts` owns shared Zod API schemas/types; `packages/db` owns database schemas/migrations; `packages/backend-shared` owns shared backend runtime primitives. Tooling config lives in `packages/eslint-config` and `packages/typescript-config`.
- Core stack: NestJS 11, TypeScript, BetterAuth + Keycloak, React 19, Vite 8, Tailwind v4, shadcn/ui, PostgreSQL, Drizzle ORM.
- Shared types are derived from Zod schemas. Do not duplicate interfaces/types when a schema is the source of truth.
- Database schemas belong in `packages/db`; use Drizzle exclusively.
- **Spec layers** (do not mix):
  - Legacy archive: `spec/legacy/<domain>.md` — read-only historical evidence. It is not shared with stakeholders and is never edited during normal feature work.
  - Stakeholder requirements: `spec/domains/<domain>/requirements.md` — the canonical, plain-language EARS requirements for a domain.
  - UI wireframes: `spec/domains/<domain>/ui/<screen>.ui.md` — low-fidelity Markdown-UI DSL screens; visual layout only, never the behavioural source of truth.
  - Internal traceability: `spec/domains/<domain>/traceability.md` — legacy-to-EARS mapping, not a stakeholder document.
  - Executable specs: `spec/features/<domain>/<feature-slug>.feature`.
  - Scope document: `spec/scope.md`.

## Domain→app mapping

The monorepo has two apps: `pam-api` (all backend) and `pam-ui` (all UI). Consolidation from the legacy four apps is complete. The `spec-architect` agent reads and may extend this mapping.

| Legacy domain | Host app | Notes |
|---|---|---|
| auth-registration, account-kyc | `pam-api` | Player domain. Host cluster: `src/modules/player/` (registration engine in `src/modules/player/registration/`). |
| auth-password | `pam-api` | Feature bucket — password reset link generation and password change. Host cluster: `src/modules/player/password-reset/`. |
| player-authorization | `pam-api` | Player auth domain — admin-initiated reset, session management. Host cluster: `src/modules/player/`. Post-ULT40-56 the forced-revocation retry cron (`ForcedRevocationRetryService`) is **worker-hosted** (`pam-worker` `src/modules/player-auth/` + `src/modules/player-keycloak/`); the API keeps the `@Interval(60000)` cookie-secret reload (`ScheduleModule.forRoot()` in `player.module.ts`) and zero `@Cron` (see `platform-cron-workers` + `oidc-session-revocation.contracts.md`). |
| wallet-ledger, txn-lifecycle | `pam-api` | Finance coupling. Producer half (shared `DomainEventPublisher` port, `@ultima/backend-shared` `src/domain-events/`) lives in the shared backend package. The outbox-relay + janitor workers (non-HTTP pollers) live in `pam-worker` (`src/outbox-relay/`) — see `platform-cron-workers`. |
| player-authorization (OIDC KC realm config) | none (infra) | Keycloak realm config `utils/keycloak-player-init/pam-players-realm-config.json` — `pam-player-oidc` client + WebAuthn browser flow + audience mapper + webOrigins. No app host (like `platform`). |
| wallet-ledger, txn-lifecycle | `pam-api` | Finance coupling. |
| payments | `pam-api` | Outbox required. |
| notifications | `pam-api` | Kafka publisher (internal module within `pam-api`). |
| bonus-account, promo-affiliate-logs, sportmatic | `pam-api` (default) | Revisit per feature. |
| rg-limits | `pam-api` | Operator-config + player limits. Backend host cluster: `src/modules/rg-limits/` (API `/api/v1/rg-limits/...`). Phase 1 (foundation): `global_limits` + `limit_tier_delays` config tables + admin edit screens. UI routes live at top-level `/global-rg-limits` (index + `tier-delays`) in `pam-ui`, NOT under `/administration`. |
| rg-exclusions | `pam-api` | Responsible-gaming exclusions (Phase 1 = activate half: time-out + cooling-off + self-exclusion). Backend host cluster: `src/modules/rg-exclusions/` (sibling of `rg-limits/`, registered in `app.module.ts`). Cross-module wiring: `player/auth` → `rg-exclusions` via `ExclusionLoginPort` (`forwardRef` both ways), `rg-exclusions` → `player/sessions` via revived `PlayerSessionsPort` (no `forwardRef`). Shared table `player_exclusions` in `packages/db`; contracts in `packages/contracts/src/rg-exclusions/`. Admin UI: new "Exclusions" tab in `pam-ui` player-detail. No `pam-worker` (no cron this phase). |
| location | `pam-api` | Reference data. Host cluster: `src/modules/location/`. |
| admin-ui-routes | `pam-ui` | Admin UI surface. |
| platform | none (infra) | No app host — repo-root compose files, `deploy/k8s` Helm chart, `scripts/k8s-deploy.sh`, `docs/devops/platform/`. Feature examples: PgBouncer transaction pooling (ULT40-47). Audited DLQ replay tooling (ULT40-61) ships a repo-root CLI `scripts/dlq-replay.mjs` (`yarn dlq-replay`) + the `event_dlq_replay_audit` table in `packages/db` (Drizzle schema + migration) — no Nest app; tests-only under `pam-api`. |
| platform-cron-workers | `pam-worker` | New non-HTTP NestJS worker app (ULT40-51 shell). Hosts scheduled (`@Cron`) jobs after ULT40-56. Host cluster: `apps/pam-worker/` (app shell) + `deploy/k8s/templates/pam-worker.yaml` + `compose.yml` `pam-worker` service. Shared runtime primitives live in `packages/backend-shared` (`@ultima/backend-shared`). |
| platform-event-bridge | `pam-event-bridge` | New non-HTTP NestJS worker app — RabbitMQ→Kafka relay for the external Archive (D1, modeled 1:1 on `pam-worker`). Consumes `pam.events.main`, maps to the Archive record shape, publishes to Kafka. Host cluster: `apps/pam-event-bridge/` (app shell) + `deploy/k8s/templates/pam-event-bridge.yaml` + `compose.yml` `pam-event-bridge` service + `compose.kafka.yml` Kafka stack. Reuses `@ultima/backend-shared` DATABASE provider/DrizzleHealthIndicator (cron-worker-extraction precedent); `arch_id` sequence table `archive_event_sequence` lives in `packages/db`. |
| `<any future UI domain>` | `pam-ui` | Default UI host. |
| observability | `pam-api` | Runtime metrics exposition. Host cluster: `src/metrics/` (Prometheus /metrics endpoint + HTTP interceptor). |

## Agent context & skills

- Hard session budget: **≤170k tokens**. Keep always-on rules minimal (`.kilo/rules/`); load detailed patterns via `.kilo/skills/*/SKILL.md` on demand.
- **Gates:** load `task-preflight` before non-trivial implementation; refuse coding when inputs are incomplete; split work into atomic responsibilities.
- **Tests ship with code:** backend → `test-backend`; frontend → `test-frontend`; contract mocks when API shape changes. Feature skills cascade child skills as needed.
- Always-on invariants: `.kilo/rules/core.md`, `backend.md`, `frontend.md`.

## Shared test infrastructure

- Per-app feature specs live under `apps/<app>/src/test/features/<domain>/` as plain Jest tests (`<feature-slug>.e2e-spec.ts` / `.spec.tsx`) — one `describe`/`it` per Gherkin `Feature`/`Scenario`, no step-definition binding. No test folder is ever created at the monorepo root.
- Shared test helpers + mock factories live under `apps/<app>/src/test/features/mocks/` (app-local, reusable across feature specs).
- Unit/integration tests are colocated in `src/`, next to the module under test (e.g. `src/app.controller.spec.ts`).
- Feature spec runner: plain Jest; API scenarios use a bootstrapped Nest app + supertest; UI scenarios use Testing Library + jsdom.

## Commands

- `yarn spec:lint -- <domain>/<feature-slug> [--strict]` — Gherkin + contract lint.
- `yarn test:e2e` — all e2e tests across apps via Turbo.
- `yarn turbo run check-types --filter=<app>` — type-check one app.
- `yarn turbo run test:e2e --filter=<app>` — e2e tests for one app.
- `yarn turbo run test:e2e lint check-types build --affected` — affected checks.

## Stack and boundaries

| Layer | Technology |
|---|---|
| Backend | NestJS 11, TypeScript |
| Auth | BetterAuth + Keycloak (OIDC) |
| Frontend | React 19, Vite 8 |
| Styling | Tailwind v4, shadcn/ui |
| Database | PostgreSQL, Drizzle ORM |
| Package manager | Yarn v4 Berry, nodeLinker: node-modules |
| Monorepo | Turborepo |

## Per-app context

- [apps/pam-api/README.md](apps/pam-api/README.md) — NestJS specifics, dev commands, known gotchas

## Spec-driven development

The SDD multi-agent flow is driven by slash commands in `.kilo/command/` and agents in `.kilo/agent/`. Stage order: gather → critique → design → test → implement → review → document. The `.feature` files are **frozen after gather**; only `spec-analyst` (via `/spec-gather --revise`) may edit them. Legacy requirements live in `spec/legacy/`, executable specs in `spec/features/<domain>/`, and the scope document is `spec/scope.md`.

For a migrated domain, Gherkin scenarios trace to `@req:<domain>#REQ-<number>` in `requirements.md`. Existing scenarios may retain legacy `BR-*` / `UC-*` tags until their feature is explicitly revised; do not perform bulk tag rewrites. Use the `convert-legacy-domain-docs`, `markdown-ui-dsl`, and `review-stakeholder-docs` skills for the migration and review workflow.

Documentation is a post-review SDD stage driven automatically by `/spec-flow` and available independently through `/spec-document <domain>/<feature-slug>`. It publishes separate audience documents at `docs/dev/<domain>/<feature-slug>.md`, `docs/devops/<domain>/<feature-slug>.md`, and `docs/operator/<domain>/<feature-slug>.md`. Dev documentation must reflect the current database and API contract schemas; operator documentation is a high-level UI workflow; all documentation diagrams use PlantUML. Material disagreement between the approved feature artifacts and current implementation blocks publication and produces a feature-scoped documentation drift report.
