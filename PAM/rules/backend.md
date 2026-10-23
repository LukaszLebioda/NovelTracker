# Backend invariants (pam-api)

Full patterns → skill `backend-conventions`. Tests → skill `test-backend`.

## Boundaries

- DB schema: `packages/db/src/schema/` only
- Shared DTOs: `packages/contracts` only
- Domain code: `apps/pam-api/src/modules/<cluster>/` (cluster = future microservice; **no cross-cluster SQL joins** — use services)
- Infra outside modules: `auth/`, `db/`, `common/`, `config/`, `health/`

## Hard rules

- Drizzle only; `DATABASE` token (DbModule is global)
- DB columns snake_case; schema fields camelCase; default PK identity int (UUID only if external system requires)
- API dates: contracts use `z.iso.datetime()`; services return `.toISOString()`
- Migrations: `yarn db:generate --name <descriptive>`; never edit committed migrations; migrate only after user OK
- Guards explicit per endpoint: `AdminGuard` / `PlayerGuard` — no global auth guard
- Every endpoint: `@ApiTags`, `@ApiOperation`, `@ApiOkResponse({ type: Dto })`, auth error decorators when guarded
- Lists: offset pagination envelope `{ items, total, page, limit, hasNext }` — never `data`
- Errors: codes from `packages/contracts` `API_ERROR_CODES` only
