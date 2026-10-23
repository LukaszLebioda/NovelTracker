# Frontend invariants (pam-ui)

Full patterns → skill `frontend-conventions`. Tests → skill `test-frontend`.

## Stack (mandatory)

| Concern | Use |
|---|---|
| HTTP | `ky` via `apiClient` — never raw `fetch` |
| Server state | TanStack Query (`useSuspenseQuery`); never call `apiClient` from components |
| Tables / routing / forms | TanStack Table / TanStack Router / RHF+Zod |
| UI / style / icons / toasts | shadcn `@/components/ui`, Tailwind v4, `lucide-react`, `sonner` |

Never edit `routeTree.gen.ts`. Paths only via `src/api/paths.ts`. shadcn before custom components.

## Layout

- Feature code: `src/features/<domain>/` (`*.api.ts`, `*.query-keys.ts`, component folders — no feature barrels)
- Shared: top-level `src/components`, `src/hooks`, `src/api`, …
- Components: **named function declarations** (not `const X = () =>`)
- i18n: **en + pl** always; feature namespaces; register both in `src/i18n/index.ts`

## Query invariants

- Hierarchical keys in `*.query-keys.ts`; mutations invalidate them
- staleTime: lists/config ~5m; live balances `0`
- No retry on HTTP 4xx/5xx
