---
name: add-frontend-feature
description: Use when adding a pam-ui feature, page, or domain resource. Cascades task-preflight, contracts, frontend-conventions, and test-frontend. Covers API layer, query hooks, components, routes, MSW.
---

# Add a Frontend Feature

## Cascade

1. `task-preflight`
2. `frontend-conventions`
3. `add-contracts-feature` if schemas/mocks missing
4. Steps below (only what the feature needs)
5. `test-frontend` before done

`<feature>` = singular kebab-case. Check `src/features/<feature>s/` and contracts first.

## API layer — `src/features/<feature>s/`

**`<feature>s.api.ts`**

```ts
export const get<Feature>s = (params: Partial<<Feature>ListQueryParams> = {}) =>
  apiClient
    .get(apiPaths.<feature>s.list, { searchParams: toSearchParams(params) })
    .json(<Feature>ListResponseSchema);
```

Add paths in `src/api/paths.ts`.

**`<feature>s.query-keys.ts`**

```ts
export const <feature>sKeys = {
  all: ['<feature>s'] as const,
  lists: (params?: object) => ['<feature>s', 'list', params] as const,
};
```

## Query hook (co-located with component)

```ts
export const <feature>sQueryOptions = (params: Partial<<Feature>ListQueryParams> = {}) =>
  queryOptions({
    queryKey: <feature>sKeys.lists(params),
    queryFn: () => get<Feature>s(params),
    staleTime: 5 * 60 * 1000,
  });

export const use<Feature>sQuery = (params = {}) =>
  useSuspenseQuery(<feature>sQueryOptions(params));
```

## Component folder

```
src/features/<feature>s/
  <feature>s.api.ts
  <feature>s.query-keys.ts
  <some-component>/
    <some-component>.tsx
    use-<feature>s-query.ts
```

No barrels. Named function components. i18n en+pl.

## Route

`validateSearch` + `loader`/`prefetchQuery` from TanStack Router. Never edit `routeTree.gen.ts`.

## MSW

`src/mocks/<feature>s.handlers.ts` — URL + handlers from contracts mocks (see `test-frontend`).

## Tests + verify

Load `test-frontend`. Component + user-flow integration as required. `check-types` for pam-ui.
