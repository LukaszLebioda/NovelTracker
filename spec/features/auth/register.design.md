# Design — auth / register

**Feature:** `spec/features/auth/register.feature` (9 scenarios)
**Rules:** `spec/domains/auth/requirements.md` (REQ-001 … REQ-007, REQ-012 shared)
**Reviewed:** `register.review.md` — verdict *Approved for design*
**Shared model:** `spec/domains/auth/data-model.md`
**Date:** 2026-10-23
**Stack:** PostgreSQL · Express.js (`server/`) · React (`client/`) · Playwright (E2E) · Postman/Newman (API)

> Design only — no application code yet. This document maps existing rules to an
> implementation shape; it does not add behaviour. UI notes for auth do not
> exist (`spec/domains/auth/ui/` is absent), so the UI plan below is derived
> from the scenarios and the requirements alone.

## Decisions encoded

| Decision | Source | Where it lands |
|---|---|---|
| Registration does **not** sign the user in; the login screen is shown with a confirmation | REQ-001, scenario `register-success` | `POST /api/auth/register` returns no `Set-Cookie`; client navigates to `/login` with a flash message |
| Emails are case-insensitive and canonicalized | REQ-007 | Normalize `trim + toLowerCase` on every email path; `users.email` stores only the canonical form; unique index rejects the duplicate |
| Whitespace-only email is invalid, not missing | REQ-003 AC | Raw email absent/`""` → `email_required`; present but empty after trim → `email_invalid` |
| Password minimum is 8 characters, no other complexity | REQ-004 | Checked before uniqueness; no whitespace/complexity rule (see *Open design notes*) |

## API contract

Base path `/api/auth`. JSON in/out. Errors use one envelope:

```json
{ "error": { "code": "snake_case_code", "message": "Human-readable sentence." } }
```

All auth endpoints are unauthenticated in this feature; `POST /api/auth/register`
never establishes a session (REQ-001).

### POST /api/auth/register

- **Auth required:** no (visitor).
- **Serves:** all 9 scenarios.
- **Request body:**

  | Field | Type | Required | Notes |
  |---|---|---|---|
  | `email` | string | yes | Trimmed, lowercased server-side before validation and storage |
  | `password` | string | yes | Never trimmed; counted as-is |

  ```json
  { "email": "Reader@Example.com", "password": "correct-horse" }
  ```

- **Success — `201 Created`** (no `Set-Cookie`, no session row):

  ```json
  { "user": { "id": "9f0c…", "email": "reader@example.com" } }
  ```

- **Errors:**

  | Status | `code` | `message` (verbatim) | Rule |
  |---|---|---|---|
  | 400 | `email_required` | The email is required. | REQ-005 |
  | 400 | `email_invalid` | The email address is not valid. | REQ-003 (incl. whitespace-only) |
  | 400 | `password_required` | The password is required. | REQ-006 |
  | 400 | `password_too_short` | The password must be at least 8 characters long. | REQ-004 |
  | 409 | `email_taken` | The email is already registered. | REQ-002, REQ-007 |
  | 500 | `internal_error` | Something went wrong. | — |

- **Validation order** (deterministic, first failure wins):
  `email` present → email format → `password` present → password length →
  email uniqueness. Rationale: cheap syntactic checks before the DB round-trip,
  and a malformed request never discloses whether an email is taken.
  *This ordering is not exercised by any scenario* (the review flags
  duplicate + short password as unspecified); it is recorded here as a design
  choice, not a rule.
- **Duplicate detection** is a single canonical lookup: normalize, then
  `SELECT … WHERE email = $1` on the unique index. `"Reader@Example.com"` and
  `"reader@example.com"` therefore collide (REQ-007). The DB unique constraint is
  the authority; a `23505` violation is translated to `409 email_taken` so
  concurrent registrations cannot create two rows.
- **Password handling:** hash with bcrypt (cost 12) or argon2id; only the hash is
  written. The plaintext exists only in the request body and the hash call.
  This is the design home for REQ-001's unproven acceptance criterion
  "password is never stored in plain text" — it is an implementation invariant,
  verified by a database/API test (see *Test plan*), not by a Gherkin step.

### POST /api/auth/login

Serves the sibling feature `login-logout.feature`; specified there.

### POST /api/auth/logout

Serves `REQ-012` — idempotent, no error when already signed out; specified in
`login-logout.design.md`.

## Data model

Uses the shared auth model — full definition in
`spec/domains/auth/data-model.md`. Registration touches only `users` and never
`sessions`.

**`users` (read/write here)**

| Column | Type | Constraints |
|---|---|---|
| `id` | `uuid` | PK, `DEFAULT gen_random_uuid()` |
| `email` | `text` | `NOT NULL`, canonical lowercase, `UNIQUE` |
| `password_hash` | `text` | `NOT NULL` |
| `created_at` | `timestamptz` | `NOT NULL DEFAULT now()` |
| `updated_at` | `timestamptz` | `NOT NULL DEFAULT now()` |

Indexes / constraints used by this feature:

- `users_email_key` — `UNIQUE (email)`: duplicate rejection (REQ-002/REQ-007)
  and the canonical lookup. Case-insensitivity comes from normalization on
  write; `CHECK (email = lower(btrim(email)))` makes a non-canonical write fail
  loudly rather than silently creating a near-duplicate.
- No index on `password_hash`; it is never queried.

"Exactly one account" (REQ-002) is guaranteed by the unique index, not by
application logic. No cascade or FK change is made by registration.

## UI plan

**Route:** `/register` → `RegisterPage` (public; redirects to `/login` if
already authenticated).

**Components**

| Component | Responsibility | State |
|---|---|---|
| `RegisterPage` | Owns the form, submits, renders messages | `email`, `password`, `fieldErrors: {email?, password?}`, `formError`, `submitting`, `success` |
| `AuthLayout` | Shared centered card used by `/register` and `/login` | none |
| `FormField` | Label + input + inline error text | props only |
| `FlashMessage` (on `LoginPage`) | Shows the confirmation passed via router state | reads `location.state.flash` |

**Flow**

1. User submits; client sends `POST /api/auth/register`. Client-side `required`
   attributes are a convenience only — the server is authoritative.
2. `201` → **do not** store a user or token. Navigate to `/login` with router
   state `{ flash: "Account created. Please log in." }`. This is how
   `register-success` shows a confirmation while "not signed in yet"
   (REQ-001); `AuthProvider.user` stays `null`.
3. `409 email_taken` → inline error on the email field: "The email is already
   registered." (REQ-002/REQ-007).
4. `400` → map `code` to the email or password field; `password_too_short`
   attaches to the password field (REQ-004).
5. `500`/network → form-level error, form stays filled, nothing is navigated.

**Selectors for Playwright** (stable hooks, not text-only):

| `data-testid` | Element |
|---|---|
| `register-form` | `<form>` |
| `register-email` | email input |
| `register-password` | password input (`type="password"`) |
| `register-submit` | submit button |
| `register-error` | field/form error container |
| `login-flash` | confirmation on `/login` |

No auth `ui/*.ui.md` notes exist, so no layout is prescribed beyond the
existing shared card pattern; visual decisions are deferred and must not
contradict the scenarios.

## Test plan

Test data: each test starts from the empty-account baseline of the feature
`Background`. Seed accounts through `POST /api/auth/register` (API), not the
register UI, except where the UI is the subject.

### Playwright — E2E (UI behaviour)

| Scenario | What is driven | Assertions |
|---|---|---|
| `register-success` | fill `/register`, submit | confirmation visible on `/login`; no logout action; direct `/api/auth/me` from the page context is `401` (not signed in) |
| `register-duplicate-email` | seed via API, register again in UI | "already registered" error; one account remains (confirmed via API login count) |
| `register-invalid-email` | submit `not-an-email` | "email address is not valid"; no account (API login fails) |
| `register-short-password` | submit `short7` | "at least 8 characters long"; no account |
| `register-missing-email` | leave email empty, submit | "email is required"; no account |
| `register-missing-password` | leave password empty, submit | "password is required"; no account |
| `register-email-case-insensitive` | seed `reader@example.com`, submit `Reader@Example.com` | "already registered"; exactly one account |
| `register-exact-8-character-password` | submit `12345678` | success confirmation; login screen; not signed in |
| `register-whitespace-email` | submit `"   "` | "email address is not valid" (not "required"); no account |

Add one non-scenario guard: after a successful registration the network
response carries **no** `Set-Cookie` (protects REQ-001 from regressions).

### Newman / Postman — API

Folder `auth/register`, run after a DB reset:

1. Happy path `201`, body `{user:{id,email}}` with `email === "reader@example.com"` for input `Reader@Example.com` (canonicalization, REQ-007).
2. `email` absent → `400 email_required`; `email: ""` → `400 email_required`.
3. `"   "` → `400 email_invalid` (REQ-003).
4. `password` absent/`""` → `400 password_required`; `"short7"` → `400 password_too_short`; `"12345678"` → `201` (length boundary).
5. Duplicate, same casing → `409 email_taken`; duplicate, different casing → `409 email_taken`; list count stays 1 (assert by a second login attempt or a fixtures read).
6. Response of every success/error contains **no** `password` or `password_hash` field.
7. Security invariant for REQ-001: with DB access available in the Newman
   environment, assert `SELECT password_hash FROM users` is non-plaintext
   (matches the stored hash, not the submitted value). If the runner has no DB
   access, this check moves to an implementation/unit test and is recorded as a
   manual verification — the Gherkin layer deliberately does not assert it.

### Not covered here

`POST /api/auth/login` and `POST /api/auth/logout` belong to
`login-logout.design.md`; login is used above only as an "account exists"
probe.

## Traceability

| Scenario | Rule | Endpoint | UI component | Primary test layer |
|---|---|---|---|---|
| `register-success` | REQ-001 | `POST /api/auth/register` | `RegisterPage` → `/login` flash | Playwright + Newman |
| `register-duplicate-email` | REQ-002 | `POST /api/auth/register` (409) | `RegisterPage` email error | Playwright + Newman |
| `register-invalid-email` | REQ-003 | `POST /api/auth/register` (400 `email_invalid`) | `RegisterPage` email error | Playwright + Newman |
| `register-short-password` | REQ-004 | `POST /api/auth/register` (400 `password_too_short`) | `RegisterPage` password error | Playwright + Newman |
| `register-missing-email` | REQ-005 | `POST /api/auth/register` (400 `email_required`) | `RegisterPage` email error | Playwright + Newman |
| `register-missing-password` | REQ-006 | `POST /api/auth/register` (400 `password_required`) | `RegisterPage` password error | Playwright + Newman |
| `register-email-case-insensitive` | REQ-007 | `POST /api/auth/register` (409 after canonicalization) | `RegisterPage` email error | Playwright + Newman |
| `register-exact-8-character-password` | REQ-004 | `POST /api/auth/register` (201) | `RegisterPage` → `/login` flash | Playwright + Newman |
| `register-whitespace-email` | REQ-003 | `POST /api/auth/register` (400 `email_invalid`) | `RegisterPage` email error | Playwright + Newman |

## Open design notes (non-blocking)

- **Whitespace-only password** (`"        "`, 8 spaces) is accepted by the
  literal reading of REQ-004. No rule forbids it and no scenario exercises it;
  the design does **not** invent a rejection. If the product wants it rejected,
  that is a requirements change, not a design change.
- **Trimming email** is applied consistently on register, login, and lookup.
  REQ-007 only mandates case folding; trimming is the design's normalization
  choice, and it makes `" Reader@Example.com "` collide as a duplicate. No
  scenario asserts this combination (flagged in the review).
- **Error precedence** for multiple simultaneous registration faults is fixed
  as stated under the endpoint. It resolves a gap the review identified as
  unproven; it does not contradict any scenario.
- **Message strings**: the exact sentences above are the contract for UI text
  and API `message`. Playwright asserts them verbatim so future wording drift
  is caught.

```text
[STATUS] auth/register designed done
```
