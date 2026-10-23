---
name: frontend-conventions
description: Load when implementing or reviewing pam-ui — feature folders, ky/TQ patterns, i18n, routes, co-location. Cascade from add-frontend-feature or after task-preflight for UI work.
---

# Frontend conventions (pam-ui)

Prereq: `task-preflight` passed. After UI changes, load `test-frontend`.

## Stack

| Purpose | Library |
|---|---|
| HTTP | `ky` via `apiClient` from `@/api/client` |
| Server state | TanStack Query (`useSuspenseQuery`) |
| Tables | TanStack Table |
| Routing | TanStack Router — never edit `routeTree.gen.ts` |
| Forms | RHF + Zod (form schema co-located; DTOs in contracts) |
| UI / CSS / icons / toasts | shadcn `@/components/ui`, Tailwind v4, `lucide-react`, `sonner` |

Never call `apiClient` (or `fetch`) from components — only via query/mutation hooks. Prefer shadcn over custom UI. Style with Tailwind + `cn()` only; no custom CSS.

## Components

Named function declarations:

```ts
export function AdminsTable(props: AdminsTableProps) { ... }
```

Arrow functions are acceptable for non-component factories/utilities and the required `createFileRoute` export.

## Feature layout

Domain logic belongs under `src/features/<domain>/`; shared resources stay at top-level `src/` folders:

```text
src/features/<domain>/
  <domain>.api.ts
  <domain>.query-keys.ts
  <component>/
    <component>.tsx
    use-<x>-query.ts          # co-located with consumer
src/api/paths.ts              # all paths centralized
src/mocks/<domain>.handlers.ts
src/routes/...                # routing only
```

Co-location: one component → same folder; multi-component feature → feature root; multi-feature → `src/hooks/`. Do not add a `components/` layer or feature `index.ts` barrels. Query keys always live at the feature root.

## API paths and routes

```ts
// paths.ts
admins: { list: 'admins', detail: (id: string) => `admins/${id}` }
```

Query params via ky `searchParams` + `toSearchParams()` — never embed in path strings. Routes live under `src/routes/`, import feature components directly, and use `validateSearch`, `loaderDeps`, and query prefetching where applicable.

## i18n

Always **en** and **pl**. Use `common` for shared labels and a feature namespace per domain; register new namespaces in `src/i18n/index.ts`. Use `t('ns:key')`. Pass `i18n.language` into locale-aware formatters. Keep JSON keys concise, nested, and camelCase.

## TanStack Query

```ts
// api
export const getAdmins = (filters?) =>
  apiClient.get(apiPaths.admins.list, { searchParams: toSearchParams(filters) }).json(AdminListResponseSchema);

// keys
export const adminsKeys = {
  all: ['admins'] as const,
  lists: (params?: object) => ['admins', 'list', params] as const,
};

// options + hook
export const adminsQueryOptions = (params = {}) =>
  queryOptions({
    queryKey: adminsKeys.lists(params),
    queryFn: () => getAdmins(params),
    staleTime: 5 * 60 * 1000,
  });
export const useAdminsQuery = (params = {}) => useSuspenseQuery(adminsQueryOptions(params));

// mutation
onSuccess: () => queryClient.invalidateQueries({ queryKey: adminsKeys.all })
```

| Data | staleTime |
|---|---|
| lists, profile, config | 5 min |
| balances, live | 0 |

Use `enabled` for conditional queries. Mutations invalidate the relevant key root; logout clears the query client (`queryClient.clear()`). Retry network errors only, not HTTP 4xx/5xx:

```ts
retry: (failureCount, error) => {
  if (isHTTPError(error)) return false;
  return failureCount < 3;
},
```

## Cascade next

- Scaffold feature → `add-frontend-feature` (contracts first if needed)
- Tests → `test-frontend`
