# Analyst assumptions:
# [REVISE] delete-novel.feature — split from novel-crud.feature by
#   user-directed revise on 2026-10-23. The DELETE scenarios below were
#   gathered 2026-10-23 from the user prompt describing Novel CRUD operations
#   (CREATE, READ, UPDATE, DELETE) for logged-in users managing their novel
#   collections, in new-feature mode. They are preserved verbatim: content
#   unchanged; the tags now point to the canonical ids `@req:novels#REQ-nnn`.
#   Creating, viewing, and editing now
#   live in the sibling features create-novel.feature, view-novels.feature,
#   and edit-novel.feature.
# Domain matched: novels (new domain; these specs cover novel DELETE only —
#   creating, viewing, and editing live in the sibling features).
# Intent (from the original prompt): a logged-in user deletes a novel from
#   their personal collection when they no longer want to track it.
# [DERIVED] Deleting a novel removes it permanently; no soft-delete or undo
#   is assumed (implementation may add undo later).
# [SECURITY] Deleting a novel requires the user to be logged in; an anonymous
#   visitor cannot access the delete page/endpoint.
# [SECURITY] Users can only delete their own novels — no cross-user access.
#   Attempting to delete another user's novel (e.g., by guessing an ID) fails
#   with "not found" or "access denied".
# [SCOPE-OUT] Sharing novels with other users, making novels public, or
#   collaborative editing — the prompt specifies users "can only view, edit,
#   and delete their own novels".
# [SCOPE-OUT] Bulk operations (bulk delete, bulk edit) — not mentioned in the
#   prompt.
# [DECIDED] The same book may exist in multiple users' collections as separate
#   entries; access isolation is by entry ownership, not by book title. Users
#   can only delete their own entries.

Feature: Delete a novel
  As a logged-in user of NovelTracker,
  I want to delete novels from my collection,
  So that I can remove books I no longer want to track.

  Background:
    Given the user database is empty
    And a user account exists with email "reader@example.com" and password "correct-horse"
    And the user is signed in as "reader@example.com"

  @req:novels#REQ-031
  Scenario: Delete a novel from the collection
    Given the user has the following novels in their collection:
      | Author            | Polish title       | Original title    | Year | Genre   |
      | J.R.R. Tolkien    | Władca Pierścieni  | The Lord of Rings | 1954 | Fantasy |
      | Andrzej Sapkowski | Wiedźmin           | The Witcher       | 1990 | Fantasy |
    When the user deletes the novel "Władca Pierścieni"
    Then the novel is deleted successfully
    And the user sees 1 novel in their collection
    And the user sees the novel "Wiedźmin"
    But the user does not see the novel "Władca Pierścieni"

  @req:novels#REQ-031
  Scenario: Delete the last novel in the collection
    Given the user has the following novels in their collection:
      | Author            | Polish title | Original title | Year | Genre          |
      | Stanisław Lem     | Solaris      | Solaris        | 1961 | Science Fiction|
    When the user deletes the novel "Solaris"
    Then the novel is deleted successfully
    And the user sees an empty list
    And the user sees a message "You have no novels yet"

  @req:novels#REQ-032
  Scenario: Anonymous user cannot delete a novel
    Given the user has the following novels in their collection:
      | Author            | Polish title       | Original title    | Year | Genre   |
      | J.R.R. Tolkien    | Władca Pierścieni  | The Lord of Rings | 1954 | Fantasy |
    And the user logs out
    When the anonymous user tries to delete the novel "Władca Pierścieni"
    Then the deletion is rejected
    And the anonymous user sees an error that login is required
    And the app shows the login screen

  @req:novels#REQ-033
  Scenario: User cannot delete another user's novel
    Given a user account exists with email "another@example.com" and password "another-pass"
    And the user is signed in as "another@example.com"
    And the user has the following novels in their collection:
      | Author         | Polish title | Original title | Year | Genre  |
      | Stephen King   | Lśnienie     | The Shining    | 1977 | Horror |
    And the user logs out
    And the user is signed in as "reader@example.com"
    And the user has the following novels in their collection:
      | Author         | Polish title | Original title | Year | Genre  |
      | Stephen King   | Lśnienie     | The Shining    | 1977 | Horror |
    When the user tries to delete the novel "Lśnienie" owned by another user
    Then the deletion is rejected
    And the user sees an error that the novel was not found
    And the other user still has the novel "Lśnienie" in their collection
    And the user still has their own copy of the novel "Lśnienie" in their collection
