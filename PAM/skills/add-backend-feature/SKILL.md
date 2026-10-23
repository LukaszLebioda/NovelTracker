---
name: add-backend-feature
description: Use when asked to add a new backend feature, endpoint, or capability to pam-api. Cascades task-preflight, contracts, module scaffold, backend-conventions, and test-backend. Use add-backend-module first if the Nest module does not exist.
---

# Add a Backend Feature

## Cascade (in order)

1. `task-preflight` — stop if incomplete
2. `backend-conventions` — patterns for this work
3. `add-backend-module` — if `apps/pam-api/src/modules/<domain_cluster>/` missing
4. `add-contracts-feature` — if contracts/mocks missing or need new schemas
5. Implement steps below
6. `test-backend` — required before done

Placeholders:
- `<domain_cluster>` — Nest module folder (`admin`, `player`, …)
- `<name>` — service/controller name (cluster primary or sub-feature e.g. `kyc`)

## 0. Exists check

```bash
ls apps/pam-api/src/modules/<domain_cluster>/
ls packages/contracts/src/<domain_cluster>/
```

Skip steps already satisfied.

## 1. Contracts

Missing folder → `add-contracts-feature`. Else extend schemas as needed.

## 2. DB (if needed)

Edit `packages/db/src/schema/<domain_cluster>.ts`, export from schema index.

```bash
yarn db:generate --name <descriptive_name>
```

After generating, read the SQL file at `packages/db/migrations/<NNNN>_<descriptive_name>.sql`, show its contents to the user, and ask for confirmation before proceeding. Only run the migration after explicit approval:

```bash
yarn db:migrate
```

If the feature only adds new columns to an existing table, alter the schema and generate a migration with a descriptive name (e.g. `add_kyc_status_to_players`).

See `backend-conventions` → Drizzle section for DB conventions.

## 3. DTOs

`apps/pam-api/src/modules/<domain_cluster>/<name>.dto.ts`:

```ts
import { createZodDto } from 'nestjs-zod';
import { <Name>SomeRequestSchema, <Name>SomeResponseSchema } from '@ultima/contracts';

export class <Name>SomeRequestDto extends createZodDto(<Name>SomeRequestSchema) {}
export class <Name>SomeResponseDto extends createZodDto(<Name>SomeResponseSchema) {}
```

Thin wrappers only — one DTO per HTTP-exposed contracts schema.

## 4. Service

```bash
# from apps/pam-api if file missing
nest g service modules/<domain_cluster>/<name> --flat --no-spec
```

Inject `DATABASE`. Lists: `Promise.all` + `getOrderFn`; dates via `.toISOString()`.

```ts
async someAction(params: <Name>SomeParams): Promise<<Name>SomeResponse> {
  // Drizzle query here
  // For list endpoints with pagination see backend-conventions → offset pagination
  // For sorting use getOrderFn from @/common/drizzle.utils
}
```

Key rules:
- `DbModule` is `@Global()` — inject `DATABASE` token directly, no need to import `DbModule`
- For list + count: use `Promise.all` for a single round trip

## 5. Controller endpoint

If `apps/pam-api/src/modules/<domain_cluster>/<name>.controller.ts` doesn't exist yet, generate it from `apps/pam-api/`:

```bash
nest g controller modules/<domain_cluster>/<name> --flat --no-spec
```

Every method: `@ApiOperation`, `@ApiOkResponse({ type })`, auth error decorator if guarded, `@ApiQuery`/`@ApiParam`/`@ApiBody` as needed. Explicit `AdminGuard` / `PlayerGuard`.

## 6. Tests + verify

Load `test-backend`. Run unit/integration/e2e and `check-types` for pam-api.
