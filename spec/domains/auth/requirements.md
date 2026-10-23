# Auth — Requirements

**Status:** draft for review
**Date:** 2026-10-23
**In scope:** registration, login, logout.
**Out of scope:** email verification, password reset/recovery, remember-me,
social/OAuth login, roles and admin users, and novels CRUD (a separate
`novels` domain).
**Domain goal:** Let a reader create a private account with an email and a
password, sign in, and sign out, so their novel collection stays private to
them.

## Terms

| Term | Meaning |
|---|---|
| Account | A stored record tying an email address to a password. |
| Signed in | The user has an active session and acts as that account. |
| Case-insensitive email | "Reader@Example.com" and "reader@example.com" refer to the same account. |

## Requirements

### REQ-001 — Create an account | must | draft

**Requirement:** When a visitor submits a valid email address and a password of
at least 8 characters, the system must create an account for that email.
**Why it matters:** New readers need an account before they can keep a private
collection.
**Acceptance criteria:**
- The visitor sees a confirmation that the account was created.
- The visitor is not signed in automatically; the login screen is shown.
- The password is never stored in plain text.

### REQ-002 — Reject a duplicate email | must | draft

**Requirement:** If the submitted email already has an account, the system must
reject the registration and must not create a second account.
**Acceptance criteria:**
- The visitor sees an error that the email is already registered.
- Exactly one account exists for that email.

### REQ-003 — Reject a malformed email | must | draft

**Requirement:** If the submitted email is not a valid email address, the
system must reject the registration.
**Acceptance criteria:**
- The visitor sees an error that the email address is not valid.
- An email consisting only of whitespace is not valid.
- No account is created.

### REQ-004 — Reject a short password | must | draft

**Requirement:** If the submitted password is shorter than 8 characters, the
system must reject the registration.
**Acceptance criteria:**
- The visitor sees an error that the password must be at least 8 characters.
- No account is created.

### REQ-005 — Email is required | must | draft

**Requirement:** If the email is missing, the system must reject the
registration and report that the email is required.
**Acceptance criteria:**
- The visitor sees an error that the email is required.
- No account is created.

### REQ-006 — Password is required | must | draft

**Requirement:** If the password is missing, the system must reject the
registration and report that the password is required.
**Acceptance criteria:**
- The visitor sees an error that the password is required.
- No account is created.

### REQ-007 — Emails are case-insensitive | must | draft

**Requirement:** The system must treat email addresses case-insensitively when
registering and logging in, so differently-cased spellings refer to the same
account.
**Acceptance criteria:**
- Registering with a differently-cased spelling of an existing email is
  rejected as a duplicate; only one account exists.
- Logging in with a differently-cased spelling of the registered email and the
  correct password succeeds.

### REQ-008 — Log in | must | draft

**Requirement:** When a registered user submits their email and their correct
password, the system must sign them in.
**Acceptance criteria:**
- The user is signed in.
- The user sees a log out action.

### REQ-009 — Reject a wrong password | must | draft

**Requirement:** If the password is wrong, the system must reject the login and
keep the user signed out.
**Acceptance criteria:**
- The user sees a single generic error that the email or password is invalid.
- The user remains signed out.

### REQ-010 — Reject an unknown email | must | draft

**Requirement:** If the email has no account, the system must reject the login
and keep the user signed out.
**Acceptance criteria:**
- The user sees the same generic error as REQ-009, with no hint that the email
  is unknown.
- The user remains signed out.

### REQ-011 — Log out | must | draft

**Requirement:** When a signed-in user logs out, the system must end their
session.
**Acceptance criteria:**
- The user is signed out.
- The app shows the login screen.

### REQ-012 — Logout is idempotent | should | draft

**Requirement:** If a user logs out while already signed out, the system must
show no error.
**Acceptance criteria:**
- The user remains signed out.
- No error is shown.

## Traceability

Every scenario in `spec/features/auth/*.feature` carries an `@req:auth#REQ-nnn`
tag pointing at the requirement above.

| Requirement | Scenarios |
|---|---|
| REQ-001 | `@req:auth#REQ-001` register-success |
| REQ-002 | register-duplicate-email |
| REQ-003 | register-invalid-email, register-whitespace-email |
| REQ-004 | register-short-password, register-exact-8-character-password |
| REQ-005 | register-missing-email |
| REQ-006 | register-missing-password |
| REQ-007 | register-email-case-insensitive, login-email-case-insensitive |
| REQ-008 | login-success |
| REQ-009 | login-wrong-password |
| REQ-010 | login-unknown-email |
| REQ-011 | logout-success |
| REQ-012 | logout-when-signed-out |
