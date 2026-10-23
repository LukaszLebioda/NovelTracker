# Critique — auth / login-logout

**Feature:** `spec/features/auth/login-logout.feature` (6 scenarios)
**Backing rules:** `spec/domains/auth/requirements.md` (REQ-001 … REQ-012)
**Reviewed:** 2026-10-23

Mechanical checks: every scenario carries a valid `@req:auth#REQ-nnn` tag
(REQ-007 … REQ-012), each tag points at an existing requirement, and every
login/logout rule this feature owns is proven by at least one scenario. *Log in
with the wrong password* (REQ-009) and *Log in with an email that has no
account* (REQ-010) both assert the same generic error, correctly upholding the
anti-enumeration rule; neither contradicts the other.

## Blocking issues

None. The previously flagged issue is resolved: *Log out while already signed
out* is now observable — it asserts "the user is still signed out" and "the app
shows the login screen with no error message", giving the REQ-012 idempotency
check a concrete outcome.

## Warnings

- **REQ-012 trigger is still abstract.** The revised scenario makes the outcome
  observable, but `When the user tries to log out` still has no performable UI
  trigger when signed out (REQ-011 leaves only the login screen, with no log out
  action). If the step stays declarative, state the mechanism (a direct logout
  request, or a stale-session logout) so it can be automated.
- **Generic-error wording drift.** REQ-009/REQ-010 say the error is "the email
  or password is invalid"; the scenarios say "the email or password was
  invalid". The two scenarios are mutually consistent, but if the wording is
  asserted verbatim it should match the requirement exactly so enumeration
  cannot leak through message differences.
- **Stale `[DERIVED]` markers.** The header still marks as `[DERIVED]` items now
  codified: session established/ended → REQ-008/REQ-011, no auto sign-in →
  REQ-001, generic error → REQ-009/REQ-010, idempotent logout → REQ-012.
  Cosmetic only — the `.feature` is frozen.
- **No `@todo` remaining** (checked both this feature and its sibling).

## Edge cases missed

- **Empty login credentials.** No scenario (and no requirement) covers logging
  in with an empty email or an empty password; it is undefined whether this
  yields the generic invalid-credentials error or a "required" error. The
  registration side covers its empties (REQ-005/REQ-006); login has no analog.
- **Whitespace-only email/password at login** (e.g. `"   "`) — unproven, and it
  interacts with case-insensitive normalization (REQ-007).
- **Session really ended by logout.** *Log out of an active session* asserts
  "signed out" plus the login screen, but no previously protected page is shown
  to now fail — the session termination of REQ-011 is only indirectly shown.
- **Re-login after logout** — not tested; unclear whether a full login cycle
  after logout restores access to the same account.
- **Password exactly 8 vs 7 — not applicable here.** Login compares against the
  stored value; there is no length rule on login, so that boundary belongs to
  `register.feature` only.
- **Covered well:** case-insensitive login (REQ-007) and logout idempotency
  (REQ-012) both have dedicated scenarios.

## Coverage gaps

- **REQ-001 … REQ-006 are registration rules** owned by the sibling feature
  `register.feature`. Out of this feature's scope; listed for completeness, not
  a gap here.
- **REQ-007 is split across features.** This feature proves the login bullet
  (logging in with a differently-cased spelling of the registered email and the
  correct password succeeds); the registration bullet is proven in
  `register.feature`. Expected split, not a gap here.
- **No requirement covers missing login credentials**, so there is no rule for a
  login-empty-inputs scenario — a rule gap, not a scenario defect.
- All requirements this feature owns (REQ-007 login bullet, REQ-008 … REQ-012)
  are covered.

## Suggested scenarios

- `@req:auth#REQ-011` — After logging out, attempt a protected action (e.g.
  view novels) → redirected to the login screen (proves the session ended).
- `@req:auth#REQ-008` — Log in with an empty or whitespace-only password →
  assert the expected outcome once a login "required" rule (or the
  generic-error rule) is chosen.
- `@req:auth#REQ-009` — Log in with a whitespace-only email → generic
  invalid-credentials error, user stays signed out.
- `@req:auth#REQ-008` — Re-login with the same account after logout → signed in
  and the log out action is visible.

**Verdict:** Approved for design
