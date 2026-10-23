# Analyst assumptions:
# [REVISE] edit-novel.feature — split from novel-crud.feature by
#   user-directed revise on 2026-10-23. The UPDATE scenarios below were
#   gathered 2026-10-23 from the user prompt describing Novel CRUD operations
#   (CREATE, READ, UPDATE, DELETE) for logged-in users managing their novel
#   collections, in new-feature mode. They are preserved verbatim: content
#   unchanged; the tags now point to the canonical ids `@req:novels#REQ-nnn`.
#   Creating, viewing, and deleting now
#   live in the sibling features create-novel.feature, view-novels.feature,
#   and delete-novel.feature.
# Domain matched: novels (new domain; these specs cover novel UPDATE only —
#   creating, viewing, and deleting live in the sibling features).
# Intent (from the original prompt): a logged-in user edits a novel in their
#   personal collection — changing any field or picture — so their records
#   stay accurate.
# [DERIVED] Required fields (Author, Polish title, Original title, Year,
#   Genre) must all be provided and non-empty.
# [DERIVED] Year of publishing must be a 4-digit number (e.g., 2024); years
#   before 1000 or after 9999 are invalid.
# [DERIVED] Picture upload accepts common image formats (JPEG, PNG, WebP, GIF);
#   implementation chooses accepted formats and file size limits.
# [DERIVED] A default book icon is displayed when no picture is uploaded
#   (picture is optional).
# [DERIVED] Description is optional; when empty, the app displays the text
#   "no description yet" (verbatim from the prompt).
# [DERIVED] Editing a novel pre-fills all current values; the user changes
#   any fields and saves; validation rules match CREATE.
# [SECURITY] Editing a novel requires the user to be logged in; an anonymous
#   visitor cannot access the edit page/endpoint.
# [SECURITY] Users can only edit their own novels — no cross-user access.
#   Attempting to edit another user's novel (e.g., by guessing an ID) fails
#   with "not found" or "access denied".
# [SCOPE-OUT] Sharing novels with other users, making novels public, or
#   collaborative editing — the prompt specifies users "can only view, edit,
#   and delete their own novels".
# [SCOPE-OUT] Bulk operations (bulk delete, bulk edit) — not mentioned in the
#   prompt.
# [SCOPE-OUT] Cover image editing/cropping, multiple pictures per novel, or
#   external picture URLs — the prompt says "uploaded from local file system".
# [SCOPE-OUT] ISBN, publisher, translator, edition, page count, language, or
#   any other fields — only the fields listed in the prompt are in scope.
# [SCOPE-OUT] Rating, reading status (e.g., "to read", "reading", "finished"),
#   or reading dates — out of scope for this CRUD feature.
# [DECIDED] Genre is chosen from a predefined dropdown list, not freeform text.
#   The current dropdown list (revisable later; same list as
#   create-novel.feature) is: Fantasy, Science Fiction, Horror, Thriller,
#   Mystery, Crime, Romance, Historical, Adventure, Literary, Drama, Poetry,
#   Non-fiction, Biography, Other.
# [DECIDED] Picture uploads must be JPEG, PNG, WebP, or GIF and no larger than
#   5 MB.
# [DECIDED] The same book may exist in multiple users' collections as separate
#   entries; access isolation is by entry ownership, not by book title. Users
#   can only edit their own entries.
# [DECIDED] A novel can be marked or unmarked as a favourite, shown with an
#   asterisk; the favourite flag belongs to the owner's own entry.

Feature: Edit a novel
  As a logged-in user of NovelTracker,
  I want to edit the novels in my collection,
  So that I can keep my records accurate and up to date.

  Background:
    Given the user database is empty
    And a user account exists with email "reader@example.com" and password "correct-horse"
    And the user is signed in as "reader@example.com"

  @req:novels#REQ-026
  Scenario: Edit a single field of an existing novel
    Given the user has the following novels in their collection:
      | Author            | Polish title       | Original title    | Year | Genre   |
      | J.R.R. Tolkien    | Władca Pierścieni  | The Lord of Rings | 1954 | Fantasy |
    When the user edits the novel "Władca Pierścieni" and changes the following:
      | Original title | The Lord of the Rings |
    Then the novel is updated successfully
    And the novel "Władca Pierścieni" now has the original title "The Lord of the Rings"
    And all other fields remain unchanged

  @req:novels#REQ-026
  Scenario: Edit multiple fields of an existing novel
    Given the user has the following novels in their collection:
      | Author            | Polish title | Original title | Year | Genre          |
      | Stanisław Lem     | Solaris      | Solaris        | 1961 | Science Fiction|
    When the user edits the novel "Solaris" and changes the following:
      | Description | A psychological novel exploring human limitations |
      | Genre       | Science Fiction                                   |
    Then the novel is updated successfully
    And the novel "Solaris" now has the description "A psychological novel exploring human limitations"
    And the novel "Solaris" now has the genre "Science Fiction"

  @req:novels#REQ-028
  Scenario: Add a picture to a novel that had none
    Given the user has the following novels in their collection:
      | Author            | Polish title | Original title | Year | Genre          |
      | Stanisław Lem     | Solaris      | Solaris        | 1961 | Science Fiction|
    And the novel "Solaris" displays a default book icon
    When the user edits the novel "Solaris" and uploads a picture "solaris-cover.jpg"
    Then the novel is updated successfully
    And the novel displays the uploaded picture "solaris-cover.jpg"

  @req:novels#REQ-028
  Scenario: Replace an existing picture with a new one
    Given the user has the following novels in their collection:
      | Author            | Polish title       | Original title    | Year | Genre   | Picture        |
      | J.R.R. Tolkien    | Władca Pierścieni  | The Lord of Rings | 1954 | Fantasy | old-cover.jpg  |
    When the user edits the novel "Władca Pierścieni" and uploads a picture "new-cover.jpg"
    Then the novel is updated successfully
    And the novel displays the uploaded picture "new-cover.jpg"

  @req:novels#REQ-027
  Scenario: Attempt to edit a novel by removing a required field
    Given the user has the following novels in their collection:
      | Author            | Polish title       | Original title    | Year | Genre   |
      | J.R.R. Tolkien    | Władca Pierścieni  | The Lord of Rings | 1954 | Fantasy |
    When the user tries to edit the novel "Władca Pierścieni" and changes the following:
      | Author | |
    Then the novel update fails
    And the user sees an error that the author is required
    And the novel "Władca Pierścieni" remains unchanged

  @req:novels#REQ-027
  Scenario: Attempt to edit a novel with an invalid year
    Given the user has the following novels in their collection:
      | Author            | Polish title | Original title | Year | Genre          |
      | Stanisław Lem     | Solaris      | Solaris        | 1961 | Science Fiction|
    When the user tries to edit the novel "Solaris" and changes the following:
      | Year | 61 |
    Then the novel update fails
    And the user sees an error that the year must be a valid 4-digit number
    And the novel "Solaris" remains unchanged

  @req:novels#REQ-029
  Scenario: Anonymous user cannot edit a novel
    Given the user has the following novels in their collection:
      | Author            | Polish title       | Original title    | Year | Genre   |
      | J.R.R. Tolkien    | Władca Pierścieni  | The Lord of Rings | 1954 | Fantasy |
    And the user logs out
    When the anonymous user tries to edit the novel "Władca Pierścieni"
    Then the edit is rejected
    And the anonymous user sees an error that login is required
    And the app shows the login screen

  @req:novels#REQ-030
  Scenario: User cannot edit another user's novel
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
    When the user tries to edit the novel "Lśnienie" owned by another user
    Then the edit is rejected
    And the user sees an error that the novel was not found
    And the novel "Lśnienie" remains unchanged for the other user
    And the user's own copy of the novel "Lśnienie" is unaffected
    And the user can still edit their own copy of the novel "Lśnienie"

  @req:novels#REQ-034
  Scenario: Mark a novel as a favourite
    Given the user has the following novels in their collection:
      | Author            | Polish title | Original title | Year | Genre          |
      | Stanisław Lem     | Solaris      | Solaris        | 1961 | Science Fiction|
    When the user marks the novel "Solaris" as a favourite
    Then the novel is updated successfully
    And the novel "Solaris" is shown with an asterisk

  @req:novels#REQ-034
  Scenario: Unmark a favourite
    Given the user has the following novels in their collection:
      | Author            | Polish title | Original title | Year | Genre          |
      | Stanisław Lem     | Solaris      | Solaris        | 1961 | Science Fiction|
    And the user's novel "Solaris" is marked as a favourite
    When the user unmarks the novel "Solaris" as a favourite
    Then the asterisk is removed from the novel "Solaris"

  @req:novels#REQ-034
  @req:novels#REQ-025
  Scenario: A favourite belongs only to the owner's own entry
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
    When the user marks the novel "Lśnienie" as a favourite
    Then the user's own copy of the novel "Lśnienie" is shown with an asterisk
    But the other user's copy of the novel "Lśnienie" is not marked as a favourite
