---
name: backend-conventions
description: Load when implementing or reviewing pam-api NestJS/Drizzle code — module layout, auth guards, Swagger, offset pagination, dates, errors. Cascade from add-backend-feature or after task-preflight for API work.
---

# Backend conventions (pam-api)

Prereq: `task-preflight` passed. After code changes, load `test-backend`.

## Package boundaries

- DB schema always belongs in `packages/db/src/schema/<feature>.ts`, never inline in app code.
- Shared API request/response schemas and types belong in `packages/contracts/src/<feature>/`, exported from the package index.
- App-internal DTOs belong in the feature module under `apps/pam-api/src/modules/<feature>/`.

## Drizzle

- Use Drizzle ORM exclusively. Prefer its query builder; raw SQL is allowed only when the builder is insufficient.
- `DbModule` is global. Inject the `DATABASE` token directly without importing `DbModule` in feature modules.
- Use snake_case database columns and camelCase schema properties.
- Default primary key: `integer('id').primaryKey().generatedAlwaysAsIdentity()`. Use UUID only when required by an external integration such as Better Auth.

## API dates

- Contracts represent dates as ISO datetime strings with `z.iso.datetime()`, never `z.coerce.date()`. Native `Date` cannot be represented in Swagger JSON Schema through `nestjs-zod`.
- Drizzle returns native `Date` values. Convert them before returning API data:

```ts
return {
  ...row,
  createdAt: row.createdAt.toISOString(),
  updatedAt: row.updatedAt.toISOString(),
};
```

Skipping conversion may serialize at runtime, but fails type-checking because the DTO contract expects strings.

## Migrations

- Generate with `yarn db:generate --name <descriptive_name>`.
- Names describe the change, not dates or hashes. Never edit a committed migration.
- Drizzle migration files are `<4-digit-index>_<descriptive_name>.sql`.
- Show the generated SQL to the user; run `yarn db:migrate` only after explicit approval.

## Module layout

```
src/modules/<cluster>/   # business — future microservice boundary
src/auth|common|config|db|health/  # infrastructure
```

- Keep controllers, services, and DTOs for a domain self-contained in the cluster.
- No cross-cluster SQL joins — import the other cluster's service instead; extraction should become RPC without changing the interface.
- Split controllers/services by responsibility when needed. Controllers are named for their resource or route, while services and modules remain singular.
- Scaffold from `apps/pam-api/`:

```bash
nest g module modules/<domain_cluster>
nest g controller modules/<domain_cluster>/<name> --flat --no-spec
nest g service modules/<domain_cluster>/<name> --flat --no-spec
```

## Auth

Guards **per endpoint/controller** — no global guard.

| Surface | Guard |
|---|---|
| Admin | `@UseGuards(AdminGuard)` + `@CurrentAdmin()` |
| Player | `@UseGuards(PlayerGuard)` |

## Swagger (every endpoint)

```ts
@ApiTags('<feature>')
@ApiOperation({ summary: '...' })
@ApiOkResponse({ type: SomeDto, description: '...' })
@ApiUnauthorizedResponse({ description: '...' }) // if guarded
```

DTOs are thin `createZodDto` wrappers around shared contract schemas. Document query, path, and body parameters with `@ApiQuery`, `@ApiParam`, and `@ApiBody`.

## Offset pagination

Envelope: `{ items, total, page, limit, hasNext }` — never `data`. Use the shared helpers from `packages/contracts/src/offset-pagination.ts`.

Contracts:

```ts
export const XListQueryParamsSchema = OffsetPaginationParamsSchema.extend({
  ...createSortParamsSchema(sortFields, { sortBy: 'createdAt', sortOrder: SORT_ORDER.DESC }).shape,
});
export const XListResponseSchema = createOffsetPaginatedSchema(XSchema);
```

Service: `Promise.all` for rows + `count()`; `getOrderFn` for deterministic sort; `hasNext` from `page * limit < total`. Controller: `@ApiQuery` for page/limit/sortBy/sortOrder.

## Errors

Use and extend `API_ERROR_CODES` from `packages/contracts/src/errors.ts`; never hardcode error-code strings. The UI matches these same shared codes.

## Backend tests

Use `@swc/jest` for type-stripping; `yarn check-types` performs type-checking. Tests are colocated as `<name>.spec.ts`.

- Controller tests use a real Nest `INestApplication` and supertest, with `ZodValidationPipe`, mocked services, and overridden guards. Always close the app.
- Database services use PGlite through `createTestDb()` and real migrations, not mocked DB layers. Integration specs run in the dedicated integration Jest project with `--maxWorkers=1`; unit specs run separately.
- Guards, filters, and utilities use `Test.createTestingModule` with `useValue` mocks.
- Mock side-effectful modules before importing them. Do not use `as any`; prefer `as unknown as` or partial factory types. Keep `@/testing/db` outside `src/` and excluded from coverage.

Details and examples: load `test-backend`.

## Cascade next

- Implement feature steps → `add-backend-feature` (and `add-backend-module` / `add-contracts-feature` if needed)
- Write tests → `test-backend`
