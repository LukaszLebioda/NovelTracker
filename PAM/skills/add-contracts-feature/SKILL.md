---
name: add-contracts-feature
description: Use when adding or updating shared Zod schemas, types, and MOCK_* fixtures in packages/contracts. Source of truth for pam-api and pam-ui — run before backend/frontend feature skills when contracts are missing.
---

# Add Contracts for a Feature

Cascade: often after `task-preflight`; before `add-backend-feature` / `add-frontend-feature`. Mocks required for `test-backend` / `test-frontend`. Shared contracts are the single source of truth. Load `backend-conventions` when the contracts are for pam-api or an API feature; in particular, use ISO datetime strings in public schemas and convert Drizzle `Date` values in services.

Replace `<feature>` with singular kebab-case (`player`, `wallet`).

## 1. Folder

```
packages/contracts/src/<feature>/
  <feature>.ts
  <feature>.mock.ts
  index.ts
```

## 2. Schema — `<feature>.ts`

```ts
import { z } from 'zod';

export const <Feature>Schema = z.object({
  id: z.number(), // z.string() UUID when Better Auth owns the table
  createdAt: z.iso.datetime(),
  updatedAt: z.iso.datetime(),
});
export type <Feature> = z.infer<typeof <Feature>Schema>;
```

Lists:

```ts
import { createOffsetPaginatedSchema, OffsetPaginationParamsSchema } from '../offset-pagination';
import { createSortParamsSchema, SORT_ORDER } from '../sort';

export const <feature>SortFields = ['createdAt', 'updatedAt'] as const;
export const <Feature>SortFieldSchema = z.enum(<feature>SortFields);

export const <Feature>ListQueryParamsSchema = OffsetPaginationParamsSchema.extend({
  ...createSortParamsSchema(<feature>SortFields, {
    sortBy: 'createdAt',
    sortOrder: SORT_ORDER.DESC,
  }).shape,
});
export const <Feature>ListResponseSchema = createOffsetPaginatedSchema(<Feature>Schema);
export type <Feature>ListQueryParams = z.infer<typeof <Feature>ListQueryParamsSchema>;
export type <Feature>ListResponse = z.infer<typeof <Feature>ListResponseSchema>;
```

Add create/update request schemas as needed. Types only via `z.infer`.

## 3. Mocks — `<feature>.mock.ts`

≥2 list items. Use ISO **strings** for datetime fields matching schemas.

```ts
export const MOCK_<FEATURE>_1: <Feature> = { /* ... */ };
export const MOCK_<FEATURE>_2: <Feature> = { /* ... */ };
export const MOCK_<FEATURE>S = [MOCK_<FEATURE>_1, MOCK_<FEATURE>_2];
export const MOCK_<FEATURE>_LIST_RESPONSE: <Feature>ListResponse = {
  items: MOCK_<FEATURE>S,
  total: 2,
  page: 1,
  limit: 10,
  hasNext: false,
};
```

## 4. Barrels

Domain `index.ts`: export schema + mock. Root `packages/contracts/src/index.ts`: `export * from './<feature>'`.

## 5. Rebuild

```bash
yarn workspace @ultima/contracts build
```
