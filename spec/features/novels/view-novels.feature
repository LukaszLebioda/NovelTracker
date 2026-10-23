# Analyst assumptions:
# [REVISE] view-novels.feature — split from novel-crud.feature by
#   user-directed revise on 2026-10-23. The READ scenarios below were
#   gathered 2026-10-23 from the user prompt describing Novel CRUD operations
#   (CREATE, READ, UPDATE, DELETE) for logged-in users managing their novel
#   collections, in new-feature mode. They are preserved verbatim: content
#   unchanged; the tags now point to the canonical ids `@req:novels#REQ-nnn`.
#   Creating, editing, and deleting now
#   live in the sibling features create-novel.feature, edit-novel.feature,
#   and delete-novel.feature.
# Domain matched: novels (new domain; these specs cover novel READ only —
#   a list view with sorting/filtering that shows all fields inline. Creating,
#   editing, and deleting live in the sibling features).
# Intent (from the original prompt): a logged-in user browses their personal
#   novel collection, sorts and filters it, and sees all fields for every
#   novel inline in the list, while seeing only their own novels.
# [DERIVED] The default list sorting is A-Z by Polish title (ascending
#   alphabetical order).
# [DERIVED] Filters are OR-based: the user filters by author surname, OR by
#   Polish title, OR by year — not combined. Multi-filter combinations are
#   scope-out until the user requests them.
# [DERIVED] "Author surname" filter matches the surname part of the Author
#   field (e.g., "Tolkien" from "J.R.R. Tolkien"); exact substring matching is
#   assumed (case-insensitive).
# [DERIVED] Polish title filter is a case-insensitive substring match.
# [DERIVED] Year filter is an exact match (e.g., "2024" matches only novels
#   published in 2024, not "2025").
# [DECIDED] There is NO separate single-novel details view. The list view
#   shows all fields for every novel at once (author, Polish title, original
#   title, year, genre, picture or default icon, and the description preview).
# [DECIDED] The description is shown in the list as a short inline preview
#   (about the first 10 words, ending with an ellipsis); the exact preview
#   length is implementation-tunable. A "See more" control opens a scrollable
#   pop-up showing the full description.
# [DERIVED] A default book icon is displayed when no picture is uploaded
#   (picture is optional).
# [DERIVED] Description is optional; when empty, the app displays the text
#   "no description yet" (verbatim from the prompt).
# [SECURITY] All operations require the user to be logged in; an anonymous
#   visitor cannot access novel CRUD pages/endpoints.
# [SECURITY] Users can only view their own novels — no cross-user access.
#   Attempting to access another user's novel (e.g., by guessing an ID) fails
#   with "not found" or "access denied".
# [SCOPE-OUT] Sharing novels with other users, making novels public, or
#   collaborative editing — the prompt specifies users "can only view, edit,
#   and delete their own novels".
# [SCOPE-OUT] Advanced filtering (combined filters, genre filter, date range,
#   search across multiple fields) — the prompt lists three single-field OR
#   filters only.
# [SCOPE-OUT] Pagination or infinite scroll for large collections — assumed
#   for implementation when needed.
# [SCOPE-OUT] ISBN, publisher, translator, edition, page count, language, or
#   any other fields — only the fields listed in the prompt are in scope.
# [SCOPE-OUT] Rating, reading status (e.g., "to read", "reading", "finished"),
#   or reading dates — out of scope for this CRUD feature.
# [DECIDED] The author filter is a case-insensitive substring match against the
#   Author field (e.g. "tolkien" matches "J.R.R. Tolkien"; "King" matches
#   "Stephen King").
# [DECIDED] The same book may exist in multiple users' collections as separate
#   entries; access isolation is by entry ownership, not by book title. Users
#   can only view their own entries.
# [DECIDED] The list can be filtered to favourites only; only the signed-in
#   user's own novels marked with an asterisk are shown, and clearing the
#   filter restores the full list.
# [DECIDED] A novel's picture is shown as a thumbnail in the list; clicking it
#   opens a larger view of the same picture.

Feature: View novels
  As a logged-in user of NovelTracker,
  I want to browse and view the novels in my collection,
  So that I can find and inspect the books I own and read.

  Background:
    Given the user database is empty
    And a user account exists with email "reader@example.com" and password "correct-horse"
    And the user is signed in as "reader@example.com"

  @req:novels#REQ-014
  Scenario: View an empty novel collection
    When the user views their novel collection
    Then the user sees an empty list
    And the user sees a message "You have no novels yet"

  @req:novels#REQ-013
  Scenario: View novels sorted A-Z by Polish title (default)
    Given the user has the following novels in their collection:
      | Author            | Polish title       | Original title     | Year | Genre          |
      | J.R.R. Tolkien    | Władca Pierścieni  | The Lord of Rings  | 1954 | Fantasy        |
      | Andrzej Sapkowski | Wiedźmin           | The Witcher        | 1990 | Fantasy        |
      | Stanisław Lem     | Solaris            | Solaris            | 1961 | Science Fiction|
      | Adam Mickiewicz   | Pan Tadeusz        | Pan Tadeusz        | 1834 | Poetry         |
    When the user views their novel collection
    Then the novels are displayed in the following order:
      | Polish title       |
      | Pan Tadeusz        |
      | Solaris            |
      | Wiedźmin           |
      | Władca Pierścieni  |

  @req:novels#REQ-025
  Scenario: User sees only their own novels, not other users' novels
    Given a user account exists with email "another@example.com" and password "another-pass"
    And the user is signed in as "another@example.com"
    And the user has the following novels in their collection:
      | Author         | Polish title | Original title | Year | Genre   |
      | Stephen King   | Lśnienie     | The Shining    | 1977 | Horror  |
    And the user logs out
    And the user is signed in as "reader@example.com"
    And the user has the following novels in their collection:
      | Author         | Polish title | Original title | Year | Genre   |
      | Stephen King   | Lśnienie     | The Shining    | 1977 | Horror  |
    When the user views their novel collection
    Then the user sees 1 novel in their collection
    And the user sees their own copy of the novel "Lśnienie"
    But the user does not see the other user's copy of the novel "Lśnienie"

  @req:novels#REQ-015
  Scenario: Filter novels by author surname
    Given the user has the following novels in their collection:
      | Author            | Polish title       | Original title    | Year | Genre          |
      | J.R.R. Tolkien    | Władca Pierścieni  | The Lord of Rings | 1954 | Fantasy        |
      | J.R.R. Tolkien    | Hobbit             | The Hobbit        | 1937 | Fantasy        |
      | Andrzej Sapkowski | Wiedźmin           | The Witcher       | 1990 | Fantasy        |
      | Stanisław Lem     | Solaris            | Solaris           | 1961 | Science Fiction|
    When the user filters the collection by author surname "Tolkien"
    Then the user sees 2 novels in the filtered results
    And the user sees the novel "Władca Pierścieni"
    And the user sees the novel "Hobbit"
    But the user does not see the novel "Wiedźmin"
    And the user does not see the novel "Solaris"

  @req:novels#REQ-016
  Scenario: Filter novels by Polish title
    Given the user has the following novels in their collection:
      | Author            | Polish title       | Original title    | Year | Genre          |
      | J.R.R. Tolkien    | Władca Pierścieni  | The Lord of Rings | 1954 | Fantasy        |
      | Andrzej Sapkowski | Wiedźmin           | The Witcher       | 1990 | Fantasy        |
      | Stanisław Lem     | Solaris            | Solaris           | 1961 | Science Fiction|
    When the user filters the collection by Polish title "Solaris"
    Then the user sees 1 novel in the filtered results
    And the user sees the novel "Solaris"
    But the user does not see the novel "Władca Pierścieni"
    And the user does not see the novel "Wiedźmin"

  @req:novels#REQ-017
  Scenario: Filter novels by year of publishing
    Given the user has the following novels in their collection:
      | Author            | Polish title       | Original title    | Year | Genre          |
      | J.R.R. Tolkien    | Władca Pierścieni  | The Lord of Rings | 1954 | Fantasy        |
      | J.R.R. Tolkien    | Hobbit             | The Hobbit        | 1937 | Fantasy        |
      | Andrzej Sapkowski | Wiedźmin           | The Witcher       | 1990 | Fantasy        |
      | Stanisław Lem     | Solaris            | Solaris           | 1961 | Science Fiction|
    When the user filters the collection by year "1954"
    Then the user sees 1 novel in the filtered results
    And the user sees the novel "Władca Pierścieni"
    But the user does not see the novel "Hobbit"
    And the user does not see the novel "Wiedźmin"
    And the user does not see the novel "Solaris"

  @req:novels#REQ-018
  Scenario: Filter returns no results when no novels match
    Given the user has the following novels in their collection:
      | Author            | Polish title       | Original title    | Year | Genre   |
      | J.R.R. Tolkien    | Władca Pierścieni  | The Lord of Rings | 1954 | Fantasy |
    When the user filters the collection by author surname "Rowling"
    Then the user sees an empty list
    And the user sees a message "No novels match your filter"

  @req:novels#REQ-019
  Scenario: List view shows all fields for each novel
    Given the user has the following novels in their collection:
      | Author            | Polish title       | Original title    | Year | Genre   | Description                    | Picture        |
      | J.R.R. Tolkien    | Władca Pierścieni  | The Lord of Rings | 1954 | Fantasy | An epic high fantasy adventure | lotr-cover.jpg |
    When the user views their novel collection
    Then the user sees the novel "Władca Pierścieni" in the list with the following fields:
      | Author         | J.R.R. Tolkien                 |
      | Polish title   | Władca Pierścieni              |
      | Original title | The Lord of Rings              |
      | Year           | 1954                           |
      | Genre          | Fantasy                        |
      | Description    | An epic high fantasy adventure |
    And the novel displays the uploaded picture "lotr-cover.jpg"

  @req:novels#REQ-020
  Scenario: Long description is truncated to a short inline preview
    Given the user has the following novels in their collection:
      | Author            | Polish title       | Original title    | Year | Genre   | Description                                                                                                   |
      | J.R.R. Tolkien    | Władca Pierścieni  | The Lord of Rings | 1954 | Fantasy | A hobbit named Frodo Baggins sets out on a perilous quest to destroy the One Ring in the fires of Mount Doom |
    When the user views their novel collection
    Then the novel "Władca Pierścieni" shows an inline description preview of about the first 10 words ending with an ellipsis
    And the novel "Władca Pierścieni" shows a "See more" control
    And the full description is not shown inline

  @req:novels#REQ-021
  Scenario: See more opens a pop-up with the full description
    Given the user has the following novels in their collection:
      | Author            | Polish title       | Original title    | Year | Genre   | Description                                                                                                   |
      | J.R.R. Tolkien    | Władca Pierścieni  | The Lord of Rings | 1954 | Fantasy | A hobbit named Frodo Baggins sets out on a perilous quest to destroy the One Ring in the fires of Mount Doom |
    When the user views their novel collection
    And the user clicks "See more" on the novel "Władca Pierścieni"
    Then a pop-up opens showing the full description of the novel "Władca Pierścieni"
    And the pop-up content scrolls when the description is long

  @req:novels#REQ-022
  Scenario: Short description is shown in full without a See more control
    Given the user has the following novels in their collection:
      | Author            | Polish title       | Original title    | Year | Genre   | Description                    |
      | J.R.R. Tolkien    | Władca Pierścieni  | The Lord of Rings | 1954 | Fantasy | An epic high fantasy adventure |
    When the user views their novel collection
    Then the novel "Władca Pierścieni" shows the description "An epic high fantasy adventure" in full
    And the description has no ellipsis
    But the novel "Władca Pierścieni" does not show a "See more" control

  @req:novels#REQ-011
  Scenario: Novel with no description shows a placeholder
    Given the user has the following novels in their collection:
      | Author            | Polish title | Original title | Year | Genre          |
      | Stanisław Lem     | Solaris      | Solaris        | 1961 | Science Fiction|
    When the user views their novel collection
    Then the novel "Solaris" shows "no description yet"
    But the novel "Solaris" does not show a "See more" control

  @req:novels#REQ-023
  Scenario: Novel with no picture shows the default book icon in the list
    Given the user has the following novels in their collection:
      | Author            | Polish title | Original title | Year | Genre          |
      | Stanisław Lem     | Solaris      | Solaris        | 1961 | Science Fiction|
    When the user views their novel collection
    Then the novel "Solaris" displays a default book icon in the list

  @req:novels#REQ-035
  Scenario: Filter the collection to favourites only
    Given the user has the following novels in their collection:
      | Author            | Polish title       | Original title    | Year | Genre          |
      | J.R.R. Tolkien    | Władca Pierścieni  | The Lord of Rings | 1954 | Fantasy        |
      | Stanisław Lem     | Solaris            | Solaris           | 1961 | Science Fiction|
      | Andrzej Sapkowski | Wiedźmin           | The Witcher       | 1990 | Fantasy        |
    And the novel "Władca Pierścieni" is marked as a favourite
    And the novel "Wiedźmin" is marked as a favourite
    When the user filters the collection to favourites only
    Then the user sees 2 novels in the filtered results
    And the user sees the novel "Władca Pierścieni"
    And the user sees the novel "Wiedźmin"
    But the user does not see the novel "Solaris"
    When the user clears the favourites filter
    Then the user sees 3 novels in their collection

  @req:novels#REQ-036
  Scenario: Clicking a picture opens a larger view
    Given the user has the following novels in their collection:
      | Author            | Polish title       | Original title    | Year | Genre   | Picture        |
      | J.R.R. Tolkien    | Władca Pierścieni  | The Lord of Rings | 1954 | Fantasy | lotr-cover.jpg |
    And the novel "Władca Pierścieni" shows the picture "lotr-cover.jpg" as a thumbnail
    When the user clicks the picture of the novel "Władca Pierścieni"
    Then a larger view of the picture "lotr-cover.jpg" opens

  @req:novels#REQ-024
  Scenario: Anonymous user cannot view novel collections
    Given the user logs out
    When the anonymous user tries to view the novel collection
    Then the view is rejected
    And the anonymous user sees an error that login is required
    And the app shows the login screen

