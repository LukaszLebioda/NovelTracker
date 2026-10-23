# Analyst assumptions:
# [REVISE] login-logout.feature — split from register-login-logout.feature
#   by user-directed revise on 2026-10-19. The scenarios below were gathered
#   2026-10-12 from the user prompt ("Users register with email and password,
#   log in, and log out") in new-feature mode and are preserved verbatim:
#   content unchanged; the tags now point to the canonical ids
#   `@req:auth#REQ-nnn`. The registration scenarios now live in
#   register.feature.
# Domain matched: auth (novels has no docs yet and is out of scope;
#   registration behavior lives in the sibling register.feature).
# Intent (from the original prompt): a user who has registered signs in with
#   their email and password and can sign out again, so their novel entries
#   stay private.
# [DERIVED] Logging in establishes a signed-in session; logging out ends it
#   and returns the user to the signed-out state (login screen).
# [DERIVED] Nobody is signed in until they explicitly log in — registering
#   does not sign the user in automatically (see register.feature).
# [DERIVED] Failed logins show one generic "invalid email or password" error
#   that never reveals whether the email exists (anti-enumeration).
# [DERIVED] Logging out while already signed out shows no error (logout is
#   idempotent).
# [DERIVED] Security internals (session/token format) are implementation
#   details and deliberately not specified as scenarios.
# [SCOPE-OUT] Registration (account creation, email/password validation,
#   duplicate-email handling) — specified in register.feature.
# [SCOPE-OUT per prompt] Email verification, password reset/recovery, and
#   remember-me — the prompt covers only registration, login, and logout.
# [SCOPE-OUT per prompt] Social/OAuth or any other non-email login — the
#   prompt says "email and password".
# [SCOPE-OUT per prompt] Roles, admin users, and any novels CRUD behavior —
#   the prompt has a single user actor; novels are a separate future feature.
# [DECIDED] Emails are treated case-insensitively: they are normalized (for
#   example, lowercased) on registration and login, so "Reader@Example.com"
#   and "reader@example.com" are the same account.

Feature: User login and logout
  As a registered reader using NovelTracker,
  I want to log in with my email and password, and log out afterwards,
  So that my novel collection and my notes stay private to me.

  Background:
    Given the user database is empty

  @req:auth#REQ-008
  Scenario: Log in with the registered email and the correct password
    Given a user account exists with email "reader@example.com" and password "correct-horse"
    When the user logs in with email "reader@example.com" and password "correct-horse"
    Then the user is signed in
    And the user sees a log out action in the app

  @req:auth#REQ-009
  Scenario: Log in with the wrong password
    Given a user account exists with email "reader@example.com" and password "correct-horse"
    When the user tries to log in with email "reader@example.com" and password "wrong-horse"
    Then the login fails
    And the user sees an error that the email or password was invalid
    And the user remains signed out

  @req:auth#REQ-010
  Scenario: Log in with an email that has no account
    Given no user account exists with email "ghost@example.com"
    When the user tries to log in with email "ghost@example.com" and password "whatever-pass"
    Then the login fails
    And the user sees an error that the email or password was invalid
    And the user remains signed out

  @req:auth#REQ-011
  Scenario: Log out of an active session
    Given a user account exists with email "reader@example.com" and password "correct-horse"
    And the user is signed in as "reader@example.com"
    When the user logs out
    Then the user is signed out
    And the app shows the login screen

  @req:auth#REQ-007
  Scenario: Log in with a differently-cased email and the correct password
    Given a user account exists with email "reader@example.com" and password "correct-horse"
    When the user logs in with email "Reader@Example.com" and password "correct-horse"
    Then the user is signed in
    And the user sees a log out action in the app

  @req:auth#REQ-012
  Scenario: Log out while already signed out
    Given no user is signed in
    When the user tries to log out
    Then the user is still signed out
    And the app shows the login screen with no error message
