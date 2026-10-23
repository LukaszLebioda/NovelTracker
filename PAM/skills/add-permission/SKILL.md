---
name: add-permission
description: Use when asked to add a new permission to the RBAC registry — registers a new permission key in PERMISSION_KEYS and propagates it to all dependent locations (seed, mocks, decorators, guards) so it passes the PERMISSION_KEY_REGEX convention and type-safety checks.
---

# Add a Permission

Registers a new permission key in the canonical `PERMISSION_KEYS` registry and
propagates it to **every** dependent location so that `yarn check-types` and the
permissions tests stay green.

Two placeholders:
- `<SCREAMING_SNAKE_KEY>` — the object key in `PERMISSION_KEYS`, UPPER_SNAKE_CASE
- `<value>` — the permission key string, must satisfy `PERMISSION_KEY_REGEX`

## 1. Choose the key — naming rules

The value must match `PERMISSION_KEY_REGEX` (defined in `permissions.ts`):

```
/^[a-z][a-z0-9_]*(?::[a-z][a-z0-9_]*)+$|^[A-Z][A-Z_]+$/
```

Two accepted shapes — pick based on the permission's nature:

| Shape | When to use | Example |
|---|---|---|
| `resource:action` | CRUD-style access to a resource (read/create/update/delete) | `players:read` |
| `resource:subresource:action` | nested resource access | `players:documents:read` |
| `RESOURCE_ACTION` (SCREAMING_SNAKE) | admin-action permission that does NOT follow the resource:action CRUD pattern (e.g. reset, set, send) | `players:reset_password` |

Rules:
- All lowercase segments joined by `:` — segments start with a letter, then `[a-z0-9_]`
- OR a single UPPER_SNAKE token (no `:`) — starts with uppercase, then `[A-Z_]`
- No whitespace anywhere, no mixed case within a segment
- Must be unique across all existing `PERMISSION_KEYS` values

## 2. Register the key (source of truth)

Edit `packages/contracts/src/permissions/permissions.ts` — add one entry to
`PERMISSION_KEYS`, keeping the object roughly grouped by resource:

```ts
export const PERMISSION_KEYS = {
  // ... existing keys ...
  <SCREAMING_SNAKE_KEY>: '<value>',
} as const;
```

The object key is the canonical identifier used in code (`PERMISSION_KEYS.<SCREAMING_SNAKE_KEY>`).
The string value is what's stored in the DB `permissions.key` column and sent
over the API.

## 3. Add the seed description (type-forced)

Edit `packages/db/src/seeds/permissions.seed.ts`. The
`PERMISSION_DESCRIPTIONS` map is typed `Record<PermissionKey, string>` — **a
missing key is a `tsc` error**, so you must add it or `yarn check-types`
fails:

```ts
const PERMISSION_DESCRIPTIONS: Record<PermissionKey, string> = {
  // ... existing entries ...
  [PERMISSION_KEYS.<SCREAMING_SNAKE_KEY>]: '<human-readable description>',
};
```

Keep descriptions concise, user-facing, and in English. This is the text shown
in the permission picker UI.

## 4. Add the mock description (type-forced)

Edit `packages/contracts/src/permissions/permissions.mock.ts`. The
`MOCK_PERMISSION_DESCRIPTIONS` map is typed `Record<PermissionKey, string>` —
**a missing key is a `tsc` error** (this is the type-safety hardening — the
mock previously used `Record<string, string>` which let missing keys pass):

```ts
const MOCK_PERMISSION_DESCRIPTIONS: Record<PermissionKey, string> = {
  // ... existing entries ...
  [PERMISSION_KEYS.<SCREAMING_SNAKE_KEY>]: '<fixture description>',
};
```

The fixture description can differ slightly from the seed description — it's
test data only.

`MOCK_PERMISSIONS` is derived from `Object.values(PERMISSION_KEYS)` — **no edit
needed**, the new permission gets a mock row automatically.

## 5. Wire enforcement (optional, per use case)

The new key is now available. Only touch these files if the feature needs to
enforce the permission on a specific route:

- **Protect a route** — add `@RequirePermissions(PERMISSION_KEYS.<SCREAMING_SNAKE_KEY>)`
  to the controller method in `apps/pam-api/src/modules/<domain>/`. Combine with
  other keys in the same decorator if the route is reachable via multiple roles.
- **Grant in a test/e2e scenario** — use the `grantPermission('admin-id',
  PERMISSION_KEYS.<SCREAMING_SNAKE_KEY>, '<description>')` helper.

Do NOT edit:
- `packages/contracts/src/enforcement/enforcement.ts` — `z.enum(PERMISSION_KEYS)`
  auto-derives from the registry, no edit needed.
- `packages/contracts/src/permissions/permissions.spec.ts` — the regex test
  (`permissions.spec.ts:18`) validates every value against
  `PERMISSION_KEY_REGEX` automatically. If you added a malformed value, this
  test fails — fix the value, not the test.

## 6. Rebuild contracts

Both `pam-api` and `pam-ui` import from `@ultima/contracts` — rebuild is
required for them to see the new export:

```bash
yarn workspace @ultima/contracts build
```

## 7. Verify

```bash
yarn turbo run check-types --filter=@ultima/contracts
yarn turbo run check-types --filter=pam-api
yarn turbo run check-types --filter=pam-ui
yarn workspace @ultima/contracts test
```

## Checklist

- [ ] Key value matches `PERMISSION_KEY_REGEX` (resource:action OR SCREAMING_SNAKE)
- [ ] Entry added to `PERMISSION_KEYS` in `permissions.ts`
- [ ] Entry added to `PERMISSION_DESCRIPTIONS` in `permissions.seed.ts`
- [ ] Entry added to `MOCK_PERMISSION_DESCRIPTIONS` in `permissions.mock.ts`
- [ ] `yarn check-types` passes for contracts, pam-api, pam-ui
- [ ] `permissions.spec.ts` passes (regex + uniqueness + mock validation)
- [ ] Contracts rebuilt (`yarn workspace @ultima/contracts build`)
