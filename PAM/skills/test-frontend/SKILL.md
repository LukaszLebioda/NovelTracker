---
name: test-frontend
description: Use when writing or updating pam-ui tests — unit helpers, component specs with mocked hooks, MSW integration/user-flow tests, and mock fixtures. Cascade after add-frontend-feature or any UI behaviour change. Required before claiming frontend work done.
---

# Frontend testing (pam-ui)

Prereq: UI surface known. Fixtures from `@ultima/contracts` `MOCK_*`; rebuild contracts after mock changes.

## Stack

Jest 29 + `@swc/jest` + `jest-fixed-jsdom` + RTL + MSW v2 + `@testing-library/user-event`. SWC strips types only; `yarn check-types` handles type-checking. `isolatedModules` is enforced.

## Three layers

| Type | Suffix | Strategy |
|---|---|---|
| Unit | `.spec.tsx` | Pure fns / column defs — no hooks |
| Component | `.spec.tsx` | Mock query hooks (factory mock) |
| Integration / user-flow | `.integration.spec.tsx` | Real hooks + MSW; act like a user |

Feature Gherkin e2e: `apps/pam-ui/src/test/features/<domain>/` per AGENTS.md.

## Unit

Call functions directly. Table `cell` renderers: `as unknown as` typed stub, invoke `cell(...)`.

## Component — factory-mock hooks

```ts
jest.mock('../use-admins-query', () => ({ useAdminsQuery: jest.fn() }));
const mockUseAdminsQuery = jest.mocked(useAdminsQuery);
beforeEach(() => {
  mockUseAdminsQuery.mockReturnValue({ data: MOCK_ADMIN_LIST_RESPONSE } as ReturnType<typeof useAdminsQuery>);
});
```

Never bare `jest.mock(path)` for modules that import `ky` (ESM blow-ups). Type mocks with `jest.mocked()`; use a double cast through `unknown` when the stub does not structurally overlap with the hook return type.

## Integration — MSW + human flow

```ts
import { setupMswHooks } from '@/mocks/setup-msw-hooks';
const server = setupMswHooks(...adminsHandlers);

const wrapper = ({ children }) => (
  <QueryClientProvider client={new QueryClient({ defaultOptions: { queries: { retry: false } } })}>
    <Suspense fallback={<div>Loading...</div>}>{children}</Suspense>
  </QueryClientProvider>
);
```

User-flow rules (e2e-as-human):

- Prefer `userEvent` over `fireEvent`
- Query by role/label/text the user sees (`getByRole`, `findByRole`) — not test IDs unless unavoidable
- Assert visible outcomes (rows, toasts keys, disabled controls), not internals
- Cover: load → empty → error override → primary action happy path → validation fail
- `findBy*` instead of `waitFor(() => getBy*)` (avoids act warnings)
- Drain async after loading-state asserts

Per-test override:

```ts
server.use(http.get(ADMINS_URL, () => HttpResponse.json({ ...MOCK, items: [] })));
```

## MSW handler file

`src/mocks/<domain>.handlers.ts` exports an absolute localhost URL (`DOMAIN_URL`) + `domainHandlers` using contracts mocks and `apiPaths`.

## Mock fixtures

`packages/contracts/src/<domain>/<domain>.mock.ts` — plain constants (≥2 list items). Export via domain `index.ts`.

```bash
yarn workspace @ultima/contracts build
```

## Do not mock

Radix DropdownMenu, Lucide icons. Skip flaky Radix Select open/interaction in jsdom; assert disabled via roles.

## Global (jest.setup) — do not repeat

`react-i18next` (`t` returns key), `matchMedia`, `Request` base URL patch.

## Helpers in specs

Extract repeated `screen.getBy*` calls into helper functions that run after render:

```ts
const getButtons = () => ({
  next: screen.getByRole('button', { name: 'common:table.pagination.next' }),
});
```

## Commands

```bash
yarn workspace pam-ui test
yarn turbo run check-types --filter=pam-ui
```

## Done gate

UI behaviour change incomplete without component specs and, for pages/flows, at least one MSW user-flow integration test.
