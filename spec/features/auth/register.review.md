# Critique — auth / register

**Feature:** `spec/features/auth/register.feature` (9 scenarios)
**Backing rules:** `spec/domains/auth/requirements.md` (REQ-001 … REQ-012)
**Reviewed:** 2026-10-23

Mechanical checks: every scenario carries a valid `@req:auth#REQ-nnn` tag
(REQ-001 … REQ-007), each tag points at an existing requirement, and every
registration rule this feature owns is proven by at least one scenario.

## Blocking issues

None. All registration rules (REQ-001 … REQ-007, registration bullet) are
proven. The two previously suggested boundary scenarios are now present and
backed by rules: *Register with a password of exactly 8 characters* (REQ-004)
and *Register with a whitespace-only email* (REQ-003, now codified by its
acceptance criterion "An email consisting only of whitespace is not valid").

## Warnings

- **REQ-001 acceptance criterion "The password is never stored in plain text"
  is unproven.** *Register with a new email and a valid password* asserts only
  confirmation, not-signed-in, and the login screen. The feature header
  deliberately scopes security internals out (lines 19–20). Decide whether that
  AC belongs in REQ-001 or moves to a security/design note; it cannot be
  observed from a Gherkin step as written.
- **Error precedence for duplicate + invalid password is unspecified.** REQ-002
  and REQ-004 do not say which error wins when a duplicate email is submitted
  with a too-short password; both duplicate scenarios use valid-length
  passwords, so the combination is never exercised. (The whitespace-vs-missing
  precedence for email is now settled by REQ-003 and the new scenario.)
- **Stale `[DERIVED]` markers.** The header still marks as `[DERIVED]` items now
  codified in requirements: 8-character minimum → REQ-004, valid and unique
  email → REQ-002/REQ-003, no auto sign-in → REQ-001. Cosmetic only — the
  `.feature` is frozen.
- **No `@todo` remaining** (checked both this feature and its sibling).

## Edge cases missed

- **Whitespace-only password.** Eight spaces satisfy a length count but are not
  meaningful; REQ-004 says nothing. (Whitespace-only *email* is now covered.)
- **Normalization scope for REQ-007.** Whether registration trims surrounding
  whitespace in addition to lowercasing (e.g. `" Reader@Example.com "`) is not
  proven.
- **Leading/trailing spaces around an otherwise valid email** at registration.
- **Validation ordering** when several inputs are invalid at once (see
  Warnings).

## Coverage gaps

- **REQ-007 is split across features.** This feature proves the registration
  bullet (differently-cased spelling of an existing email is rejected as a
  duplicate); the login bullet is proven in `login-logout.feature`. Expected
  split, not a gap here.
- **REQ-008 … REQ-012 belong to the sibling feature `login-logout.feature`.**
  Out of this feature's scope; listed for completeness, not a gap here.
- **REQ-001 AC "password is never stored in plain text"** still has no scenario
  anywhere.
- No rule covers **whitespace-only passwords**, so a scenario cannot be traced
  there yet.

## Suggested scenarios

- `@req:auth#REQ-002` — Register a duplicate email with a short password →
  assert which error is shown (precedence).
- `@req:auth#REQ-006` — Register with a whitespace-only password → clarify and
  assert the expected outcome.
- `@req:auth#REQ-007` — Register with `" Reader@Example.com "` (casing plus
  surrounding spaces) → rejected as a duplicate if trimming is part of
  normalization.

**Verdict:** Approved for design
