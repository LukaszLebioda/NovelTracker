---
name: test-backend
description: Use when writing or updating pam-api tests — controller supertest, PGlite service integration, unit guards/utils, and feature e2e. Cascade after add-backend-feature or any backend behaviour change. Required before claiming backend work done.
---

# Backend testing (pam-api)

Prereq: implementation path known. Use contracts `MOCK_*` fixtures; if missing, load `add-contracts-feature` first.

## Stack

- Jest + `@swc/jest` (strip types only; types via `yarn check-types`)
- Colocated: `*.spec.ts` next to source
- Feature e2e: `apps/pam-api/src/test/features/<domain>/`
- `clearMocks: true` globally — no manual `clearAllMocks` in every `beforeEach`
- Prefer `as unknown as T` / `Partial<T>` over `as any`

## Controllers — supertest (not isolated unit)

Real `INestApplication` + supertest. Mock services; override guards.

```ts
async function createApp() {
  const findAll = jest.fn().mockResolvedValue(MOCK_LIST_RESPONSE);
  const module = await Test.createTestingModule({
    controllers: [XController],
    providers: [{ provide: XService, useValue: { findAll } }],
  })
    .overrideGuard(AdminGuard)
    .useValue({ canActivate: () => true })
    .compile();

  const app = module.createNestApplication();
  app.useGlobalPipes(new ZodValidationPipe()); // mirror main.ts
  await app.init();
  return { app, findAll };
}
// afterAll(() => app.close())
```

## Services — PGlite integration

No DB mocks. `createTestDb()` from `@/testing/db`.

```ts
beforeAll(async () => {
  testDb = await createTestDb();
  const module = await Test.createTestingModule({
    providers: [XService, { provide: DATABASE, useValue: testDb.db }],
  }).compile();
  service = module.get(XService);
});
afterAll(() => testDb?.close());
beforeEach(async () => { await testDb.db.delete(table); /* seed */ });
```

PGlite specs: jest project `integration`, `yarn test:integration` (`maxWorkers=1`). Unit: `yarn test:unit`. Never put PGlite specs in the unit project.

## Guards / filters / utils — unit

`Test.createTestingModule` + `useValue` mocks. Minimal `ExecutionContext` / `ArgumentsHost` factories.

Side-effectful imports: `jest.mock('...', () => ...)` **before** importing the SUT.

## Feature e2e (Gherkin mirror)

Plain Jest under `apps/pam-api/src/test/features/<domain>/` — one `describe`/`it` per Feature/Scenario. Shared helpers: `apps/pam-api/src/test/features/mocks/`.

## Mutation-style coverage (behaviour edges)

For each endpoint/use-case, cover at least:

| Case | Expect |
|---|---|
| Happy path | 2xx + body shape |
| Validation fail | 400 |
| Unauthenticated / forbidden | 401/403 when guarded |
| Not found / domain error | correct status + `API_ERROR_CODES` |
| List pagination/sort | items, total, hasNext |

Prefer real HTTP + PGlite over mocking business logic away.

## Commands

```bash
yarn workspace pam-api test:unit
yarn workspace pam-api test:integration
yarn turbo run test:e2e check-types --filter=pam-api
```

## Done gate

Backend task incomplete until applicable layers above are green for the changed code.
