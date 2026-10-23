# Design — auth / login-logout

**Feature:** `spec/features/auth/login-logout.feature` (6 scenarios)
**Rules:** `spec/domains/auth/requirements.md` (REQ-007 login bullet, REQ-008 … REQ-012)
**Reviewed:** `login-logout.review.md` — verdict *Approved for design*
**Shared model:** `spec/domains/auth/data-model.md`
**Date:** 2026-10-23
**Stack:** PostgreSQL · Express.js (`server/`) · React (`client/`) · Playwright (E2E) · Postman/Newman (API)

> Design only — no application code yet. UI notes for auth do not exist
> (`spec/domains/auth/ui/` is absent); the UI plan is derived from the scenarios
> and requirements.

## Decisions encoded

| Decision | Source | Where it lands |
|---|---|---|
| Login errors are **one** generic message; wrong password and unknown email are indistinguishable | REQ-009, REQ-010 | `401 invalid_credentials`, identical `code` and `message`, identical response for both cases |
| Login is case-insensitive | REQ-007 | Same `trim + toLowerCase` canonicalization as registration; lookup on `users.email` |
| A successful login establishes a server session and shows a log out action | REQ-008 | `POST /api/auth/login` sets an httpOnly cookie; `GET /api/auth/me` hydrates `AuthProvider`; header shows `LogoutButton` |
| Logout ends the session and returns to the login screen | REQ-011 | `POST /api/auth/logout` deletes the session row and clears the cookie; client routes to `/login` |
| Logout is idempotent — no error when already signed out | REQ-012 | `POST /api/auth/logout` is `204` in every case, including no/invalid cookie |

## API contract

Base path `/api/auth`. JSON in/out. Error envelope:

```json
{ "error": { "code": "snake_case_code", "message": "Human-readable sentence." } }
```

### POST /api/auth/login

- **Auth required:** no (anonymous).
- **Serves:** `login-success`, `login-wrong-password`, `login-unknown-email`, `login-email-case-insensitive`.
- **Request body:**

  ```json
  { "email": "Reader@Example.com", "password": "correct-horse" }
  ```

  `email` and `password` are `string`s; the server trims and lowercases the
  email, never the password.

- **Success — `200 OK`**, and a session cookie is set:

  ```json
  { "user": { "id": "9f0c…", "email": "reader@example.com" } }
  ```

  ```http
  Set-Cookie: nt_session=<opaque-token>; HttpOnly; SameSite=Lax; Path=/; Secure (prod); Max-Age=604800
  ```

  The cookie holds a 32-byte random token; only `SHA-256(token)` is stored in
  `sessions.token_hash`. The raw token never touches the database or logs.

- **Errors:**

  | Status | `code` | `message` (verbatim) | Rule |
  |---|---|---|---|
  | 401 | `invalid_credentials` | The email or password is invalid. | REQ-009, REQ-010 |
  | 500 | `internal_error` | Something went wrong. | — |

  **Anti-enumeration contract** (REQ-009/REQ-010): wrong password, unknown
  email, whitespace-only email, and a non-existent account all produce the same
  `401`, the same `code`, and the same `message` body — no `details`, no
  field name, no timing shortcut. Unknown-email requests still run a dummy
  password-verify against a fixed hash so response timing does not reveal
  existence.
- **Missing/empty credentials:** no rule covers this (the review lists it as a
  rule gap). Design choice: treat it exactly like any failed authentication —
  `401 invalid_credentials`, the same body. This avoids introducing a second
  login error message that could be used to probe behaviour. Recorded here,
  not added to requirements.
- **Message wording** follows the requirements ("is invalid", not "was
  invalid"). The review's wording-drift warning is resolved by making this
  string the single source rendered by both API and UI; Playwright asserts it
  verbatim in both failure scenarios, so `REQ-009` and `REQ-010` cannot diverge.
- **Expiry:** sessions expire after 7 days (`expires_at`); the cookie `Max-Age`
  matches. Expired sessions are treated as absent (401 on `/me`, 204 on logout).

### GET /api/auth/me

- **Auth required:** yes (session cookie).
- **Serves:** UI state for `login-success` (log out action visible), the
  signed-out check in `logout-success`, and page reloads.
- **Success — `200 OK`:** `{ "user": { "id": "9f0c…", "email": "reader@example.com" } }`
- **Errors:** `401 unauthenticated` — `{ "error": { "code": "unauthenticated", "message": "You are not signed in." } }`. No cookie is cleared on a 401; the client just moves to anonymous state.

### POST /api/auth/logout

- **Auth required:** no — deliberately optional (idempotency, REQ-012).
- **Serves:** `logout-success`, `logout-when-signed-out`.
- **Request body:** none. Cookie is read if present.
- **Success — `204 No Content`** in all cases:
  - valid session → delete the matching `sessions` row, clear the cookie;
  - unknown/expired/already-deleted cookie → no-op, still clear the cookie;
  - no cookie at all → no-op, still `204`.
- **Errors:** `500 internal_error` only. Never `401`, never `404` — an error
  here would itself leak whether a session existed (REQ-012 requires "no
  error").
- **Double-submit safety:** logout is a no-op on repeat; the DELETE is keyed by
  `token_hash`, so replaying it after the row is gone affects zero rows and
  still returns `204`.

### POST /api/auth/register

Serves the sibling feature `register.feature`; specified in
`register.design.md`. Not used by these scenarios except as a seeding step.

## Data model

Uses the shared auth model — full definition in
`spec/domains/auth/data-model.md`. This feature reads `users` and reads/writes
`sessions`.

**`users` (read only here)**

| Column | Type | Constraints |
|---|---|---|
| `id` | `uuid` | PK |
| `email` | `text` | `NOT NULL`, canonical lowercase, `UNIQUE` |
| `password_hash` | `text` | `NOT NULL` — compared with the password verifier, never selected into a response |

Lookup: `SELECT id, email, password_hash FROM users WHERE email = $1` on
`users_email_key` (REQ-007 canonicalization).

**`sessions` (read/write here)**

| Column | Type | Constraints |
|---|---|---|
| `id` | `uuid` | PK, `DEFAULT gen_random_uuid()` |
| `user_id` | `uuid` | `NOT NULL REFERENCES users(id) ON DELETE CASCADE` |
| `token_hash` | `text` | `NOT NULL`, `UNIQUE` — SHA-256 hex of the cookie token |
| `created_at` | `timestamptz` | `NOT NULL DEFAULT now()` |
| `expires_at` | `timestamptz` | `NOT NULL` — now() + 7 days |
| `last_seen_at` | `timestamptz` | `NULL` — optional touch on authenticated reads |

Indexes:

- `sessions_token_hash_key` — `UNIQUE (token_hash)`: every authenticated request
  resolves the cookie in one index lookup; also the logout `DELETE` key.
- `sessions_user_id_idx` — `(user_id)`: future "log out everywhere"/cleanup and
  FK checks.
- `sessions_expires_at_idx` — `(expires_at)`: periodic purge of dead rows.

Deleting a user cascades to their sessions; logout deletes exactly the one row
for the presented token, so other devices stay signed in (not specified by any
rule — noted, not designed).

No schema change is required by these scenarios beyond creating the shared
tables.

## UI plan

**Routes**

| Route | Component | Access |
|---|---|---|
| `/login` | `LoginPage` | public; if authenticated, redirect to `/` |
| `/` (home shell) | `AppShell` / home placeholder | protected — novels domain will mount here |
| `/logout` | `LogoutRoute` | performs logout on entry, then redirects to `/login` |

`/logout` exists so that "the user tries to log out" (REQ-012) has a
performable trigger while signed out: navigating there issues
`POST /api/auth/logout` and always lands on `/login` with no error. This is an
implementation route, not a new user-visible action — REQ-011's "no log out
action when signed out" still holds because no button is rendered; the header
`LogoutButton` is only shown when `user !== null`.

**Components and state**

| Component | Responsibility | State |
|---|---|---|
| `AuthProvider` (context) | Single source of truth for the session; bootstraps from `GET /api/auth/me` | `user: User \| null`, `status: 'loading' \| 'authenticated' \| 'anonymous'` |
| `LoginPage` | Login form | `email`, `password`, `formError`, `submitting` |
| `ProtectedRoute` | Redirects anonymous users to `/login` when `status === 'anonymous'` | reads context |
| `AppShell` | Header; renders `LogoutButton` only when authenticated | reads context |
| `LogoutButton` | Calls `logout()` from context | `pending` (disabled while in flight) |
| `LogoutRoute` | Calls `logout()` on mount, then `navigate('/login')` | none |
| `useAuth()` | `{ user, status, login(email, password), logout() }` | — |

**Flow — login (`login-success`, `login-email-case-insensitive`)**

1. Submit → `POST /api/auth/login` with the typed email (case preserved in the
   field; the server canonicalizes).
2. `200` → context stores `user`, `status = 'authenticated'`; navigate to `/`;
   `AppShell` renders `LogoutButton` (REQ-008).
3. `401` → `formError` set to the server `message` verbatim; `user` stays
   `null`; remain on `/login` (REQ-009/REQ-010). The password field is cleared;
   the email stays.
4. Reload on any protected route → `AuthProvider` calls `/me`; `401` means
   anonymous, `200` restores the header state.

**Flow — logout (`logout-success`)**

1. `LogoutButton` (or `/logout` entry) → `logout()`: `POST /api/auth/logout`,
   ignore the response body.
2. On `204` → clear context (`user = null`, `status = 'anonymous'`) and
   navigate to `/login` (REQ-011).
3. No toast, no error banner — including when the call had no session
   (REQ-012). A `5xx` is the only case that shows an error, and it leaves the
   user on `AppShell` with their state intact.

**Selectors for Playwright**

| `data-testid` | Element |
|---|---|
| `login-form`, `login-email`, `login-password`, `login-submit` | login form |
| `login-error` | form-level generic error |
| `app-header` | shell header |
| `logout-button` | log out action |
| `logout-route` | marker rendered by `/logout` (helps assert the trigger ran) |

No auth `ui/*.ui.md` exists, so no layout is prescribed; the login card must be
usable at the viewports the novels UI notes target, and it must not display any
account-existence hint.

## Test plan

Each test starts from the feature `Background` (empty user database). Seed
accounts with `POST /api/auth/register` at the API level.

### Playwright — E2E (UI behaviour)

| Scenario | What is driven | Assertions |
|---|---|---|
| `login-success` | seed, fill `/login`, submit | lands on `/`; `logout-button` visible; `/me` returns the account |
| `login-wrong-password` | seed, submit wrong password | stays on `/login`; `login-error` text exactly "The email or password is invalid."; `logout-button` never appears; `/me` is 401 |
| `login-unknown-email` | submit unknown email | same exact error text and same screen as above; no hint of existence; still signed out |
| `login-email-case-insensitive` | seed `reader@example.com`, submit `Reader@Example.com` | signed in; `logout-button` visible |
| `logout-success` | sign in through the UI, click `logout-button` | redirected to `/login`; `logout-button` gone; `/api/auth/me` in the page context is 401 (session really ended) |
| `logout-when-signed-out` | navigate to `/logout` with no session | redirected to `/login`; no error element/text; no `logout-button`; repeat navigation still error-free |

Cross-check for the anti-enumeration rule: `login-wrong-password` and
`login-unknown-email` must assert the *same* string constant (imported from a
shared fixture) so a wording change cannot silently break only one of them.
`logout-success` additionally requests a protected route after logout and
expects the `/login` redirect (closes the review's "session really ended"
gap without a new scenario).

### Newman / Postman — API

Folder `auth/login-logout`, run after a DB reset:

1. Seed a user, `POST /login` correct credentials → `200`, body has `user.id`
   and canonical lowercase `user.email`; response has `Set-Cookie` with
   `HttpOnly` and `SameSite`; **no** `password`/`password_hash` in the body.
2. `POST /login` with the same email differently cased → `200` (REQ-007).
3. Wrong password → `401 invalid_credentials`; assert `message` **matches the
   exact string** and no `Set-Cookie`.
4. Unknown email → `401 invalid_credentials`; deep-equal the entire JSON body
   against the response from (3) — proves REQ-009 and REQ-010 are
   indistinguishable.
5. Whitespace-only email → `401 invalid_credentials` (design choice; documents
   the gap rather than inventing a rule).
6. Missing/empty password → `401 invalid_credentials`, same body (design
   choice for the uncovered rule gap).
7. `GET /me` with the session cookie → `200`; without cookie → `401`.
8. `POST /logout` with cookie → `204`; cookie-clearing `Set-Cookie` present.
   `GET /me` reusing the old cookie → `401` (REQ-011).
9. `POST /logout` again with the same (now dead) cookie → `204`, empty body, no
   error (REQ-012).
10. `POST /logout` with no cookie at all → `204`, empty body (REQ-012).
11. Tampered token (`nt_session=abc`) → `/me` 401, `/logout` 204.

### Not covered here

Registration, email normalization at write time, and the hashing invariant
belong to `register.design.md`. Login-empty behaviour has no scenario and no
rule; the two Newman checks above are regression guards for the documented
design choice only.

## Traceability

| Scenario | Rule | Endpoint | UI component | Primary test layer |
|---|---|---|---|---|
| `login-success` | REQ-008 | `POST /api/auth/login`, `GET /api/auth/me` | `LoginPage`, `AuthProvider`, `LogoutButton` | Playwright + Newman |
| `login-wrong-password` | REQ-009 | `POST /api/auth/login` (401) | `LoginPage` `formError` | Playwright + Newman |
| `login-unknown-email` | REQ-010 | `POST /api/auth/login` (401, identical body) | `LoginPage` `formError` | Playwright + Newman |
| `logout-success` | REQ-011 | `POST /api/auth/logout`, `GET /api/auth/me` | `LogoutButton`, `AuthProvider` | Playwright + Newman |
| `login-email-case-insensitive` | REQ-007 | `POST /api/auth/login` (canonical lookup) | `LoginPage` | Playwright + Newman |
| `logout-when-signed-out` | REQ-012 | `POST /api/auth/logout` (204 always) | `LogoutRoute`, `AuthProvider` | Playwright + Newman |

## Anti-enumeration checklist (design invariant)

- One status, one code, one message for every failed login path.
- No email-existence check before password verification; dummy verify on unknown email.
- No distinct validation error for malformed login emails (unlike registration).
- `logout` never reveals whether a session existed (`204` always).
- Response bodies never contain `password_hash`; logs never contain tokens or
  passwords; the cookie is `HttpOnly` (not readable by client JS).

## Open design notes (non-blocking)

- **`/logout` route** is the concrete trigger the review asked for; it is a
  routing mechanism for REQ-012, not a new user-facing control.
- **Missing/empty login credentials** return the generic 401 by design choice;
  no requirement covers them. If a distinct "required" UX is wanted, that is a
  requirements change.
- **Single-session vs multi-device** is not specified; the model deletes only
  the presented session, which is the conservative reading of REQ-011.
- **Session expiry (7 days)** is not specified by any rule; it is an
  implementation parameter recorded in `data-model.md` and is not asserted by
  the scenarios.

```text
[STATUS] auth/login-logout designed done
```
