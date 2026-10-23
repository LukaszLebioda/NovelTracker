# Analyst assumptions:
# [REVISE] create-novel.feature — split from novel-crud.feature by
#   user-directed revise on 2026-10-23. The CREATE scenarios below were
#   gathered 2026-10-23 from the user prompt describing Novel CRUD operations
#   (CREATE, READ, UPDATE, DELETE) for logged-in users managing their novel
#   collections, in new-feature mode. They are preserved verbatim: content
#   unchanged; the tags now point to the canonical ids `@req:novels#REQ-nnn`.
#   Viewing, editing, and deleting now live
#   in the sibling features view-novels.feature, edit-novel.feature, and
#   delete-novel.feature.
# Domain matched: novels (new domain; these specs cover novel CREATE only —
#   reading, editing, and deleting live in the sibling features).
# Intent (from the original prompt): a logged-in user adds a novel to their
#   personal collection by providing its details, optionally uploading a
#   picture, so they can track the books they own and read.
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
# [SECURITY] Creating a novel requires the user to be logged in; an anonymous
#   visitor cannot access the create page/endpoint.
# [SECURITY] A created novel belongs to the signed-in user; users can only
#   see and manage their own novels (see the sibling features).
# [SCOPE-OUT] Sharing novels with other users, making novels public, or
#   collaborative editing — the prompt specifies users "can only view, edit,
#   and delete their own novels".
# [SCOPE-OUT] Cover image editing/cropping, multiple pictures per novel, or
#   external picture URLs — the prompt says "uploaded from local file system".
# [SCOPE-OUT] ISBN, publisher, translator, edition, page count, language, or
#   any other fields — only the fields listed in the prompt are in scope.
# [SCOPE-OUT] Rating, reading status (e.g., "to read", "reading", "finished"),
#   or reading dates — out of scope for this CRUD feature.
# [DECIDED] Genre is chosen from a predefined dropdown list, not freeform text.
#   The current dropdown list (revisable later) is: Fantasy, Science Fiction,
#   Horror, Thriller, Mystery, Crime, Romance, Historical, Adventure, Literary,
#   Drama, Poetry, Non-fiction, Biography, Other.
# [DECIDED] Picture uploads must be JPEG, PNG, WebP, or GIF and no larger than
#   5 MB.
# [DECIDED] A novel may have one or more genres; at least one genre is required;
#   every selected genre must be from the allowed list.
# [DECIDED] A novel may be marked as a favourite at creation (REQ-037).
# [DECIDED] The allowed picture formats are JPEG, PNG, WebP, and GIF, at most
#   5 MB.
# [DECIDED] A valid 4-digit year is between 1000 and 9999.

Feature: Create a novel
  As a logged-in user of NovelTracker,
  I want to add novels to my collection,
  So that I can keep track of the books I own and read.

  Background:
    Given the user database is empty
    And a user account exists with email "reader@example.com" and password "correct-horse"
    And the user is signed in as "reader@example.com"

  @req:novels#REQ-001
  @req:novels#REQ-009
  @req:novels#REQ-011
  Scenario: Add a new novel with all required fields
    When the user creates a novel with the following details:
      | Author         | J.R.R. Tolkien          |
      | Polish title   | Władca Pierścieni       |
      | Original title | The Lord of the Rings   |
      | Year           | 1954                    |
      | Genre          | Fantasy                 |
    Then the novel is created successfully
    And the user sees the novel "Władca Pierścieni" in their collection
    And the novel displays a default book icon
    And the novel description shows "no description yet"

  @req:novels#REQ-001
  @req:novels#REQ-008
  Scenario: Add a novel with more than one genre
    When the user creates a novel with the following details:
      | Author         | J.R.R. Tolkien          |
      | Polish title   | Władca Pierścieni       |
      | Original title | The Lord of the Rings   |
      | Year           | 1954                    |
      | Genre          | Fantasy, Adventure      |
    Then the novel is created successfully
    And the user sees the novel "Władca Pierścieni" in their collection
    And the novel shows the genres "Fantasy" and "Adventure"

  @req:novels#REQ-037
  Scenario: Create a novel marked as a favourite at creation
    When the user creates a novel with the following details:
      | Author         | Andrzej Sapkowski    |
      | Polish title   | Wiedźmin             |
      | Original title | The Witcher          |
      | Year           | 1990                 |
      | Genre          | Fantasy              |
      | Favourite      | yes                  |
    Then the novel is created successfully
    And the novel "Wiedźmin" is shown with an asterisk

  @req:novels#REQ-001
  @req:novels#REQ-038
  Scenario: Add a novel with a picture upload
    When the user creates a novel with the following details:
      | Author         | Andrzej Sapkowski    |
      | Polish title   | Wiedźmin             |
      | Original title | The Witcher          |
      | Year           | 1990                 |
      | Genre          | Fantasy              |
    And the user uploads a picture "witcher-cover.jpg"
    Then the novel is created successfully
    And the novel displays the uploaded picture "witcher-cover.jpg"
    And the novel description shows "no description yet"

  @req:novels#REQ-010
  Scenario: Attempt to add a novel with an unsupported picture format
    When the user tries to create a novel with the following details:
      | Author         | J.R.R. Tolkien       |
      | Polish title   | Hobbit               |
      | Original title | The Hobbit           |
      | Year           | 1937                 |
      | Genre          | Fantasy              |
    And the user uploads a picture "cover.pdf"
    Then the novel creation fails
    And the user sees an error that the picture must be a JPEG, PNG, WebP, or GIF file
    And no novel is created for Polish title "Hobbit"

  @req:novels#REQ-010
  Scenario: Attempt to add a novel with a picture larger than 5 MB
    When the user tries to create a novel with the following details:
      | Author         | J.R.R. Tolkien       |
      | Polish title   | Hobbit               |
      | Original title | The Hobbit           |
      | Year           | 1937                 |
      | Genre          | Fantasy              |
    And the user uploads a picture "huge-cover.png"
    Then the novel creation fails
    And the user sees an error that the picture must be at most 5 MB
    And no novel is created for Polish title "Hobbit"

  @req:novels#REQ-001
  @req:novels#REQ-039
  Scenario: Add a novel with a description
    When the user creates a novel with the following details:
      | Author         | Stanisław Lem            |
      | Polish title   | Solaris                  |
      | Original title | Solaris                  |
      | Year           | 1961                     |
      | Genre          | Science Fiction          |
      | Description    | A psychological novel exploring human limitations |
    Then the novel is created successfully
    And the novel description shows "A psychological novel exploring human limitations"

  @req:novels#REQ-002
  Scenario: Attempt to add a novel without an author
    When the user tries to create a novel with the following details:
      | Author         |                      |
      | Polish title   | Pan Tadeusz          |
      | Original title | Pan Tadeusz          |
      | Year           | 1834                 |
      | Genre          | Poetry               |
    Then the novel creation fails
    And the user sees an error that the author is required
    And no novel is created for Polish title "Pan Tadeusz"

  @req:novels#REQ-003
  Scenario: Attempt to add a novel without a Polish title
    When the user tries to create a novel with the following details:
      | Author         | Adam Mickiewicz      |
      | Polish title   |                      |
      | Original title | Pan Tadeusz          |
      | Year           | 1834                 |
      | Genre          | Poetry               |
    Then the novel creation fails
    And the user sees an error that the Polish title is required
    And no novel is created for author "Adam Mickiewicz"

  @req:novels#REQ-004
  Scenario: Attempt to add a novel without an original title
    When the user tries to create a novel with the following details:
      | Author         | Adam Mickiewicz      |
      | Polish title   | Pan Tadeusz          |
      | Original title |                      |
      | Year           | 1834                 |
      | Genre          | Poetry               |
    Then the novel creation fails
    And the user sees an error that the original title is required
    And no novel is created for Polish title "Pan Tadeusz"

  @req:novels#REQ-005
  Scenario: Attempt to add a novel without a year
    When the user tries to create a novel with the following details:
      | Author         | Adam Mickiewicz      |
      | Polish title   | Pan Tadeusz          |
      | Original title | Pan Tadeusz          |
      | Year           |                      |
      | Genre          | Poetry               |
    Then the novel creation fails
    And the user sees an error that the year is required
    And no novel is created for Polish title "Pan Tadeusz"

  @req:novels#REQ-006
  Scenario: Attempt to add a novel with no genre selected
    When the user tries to create a novel with the following details:
      | Author         | Adam Mickiewicz      |
      | Polish title   | Pan Tadeusz          |
      | Original title | Pan Tadeusz          |
      | Year           | 1834                 |
      | Genre          |                      |
    Then the novel creation fails
    And the user sees an error that at least one genre is required
    And no novel is created for Polish title "Pan Tadeusz"

  @req:novels#REQ-007
  Scenario: Attempt to add a novel with a non-numeric year
    When the user tries to create a novel with the following details:
      | Author         | Adam Mickiewicz      |
      | Polish title   | Pan Tadeusz          |
      | Original title | Pan Tadeusz          |
      | Year           | eighteen-thirty-four |
      | Genre          | Poetry               |
    Then the novel creation fails
    And the user sees an error that the year must be a valid 4-digit year (1000–9999)
    And no novel is created for Polish title "Pan Tadeusz"

  @req:novels#REQ-007
  Scenario: Attempt to add a novel with a 3-digit year
    When the user tries to create a novel with the following details:
      | Author         | Unknown Author       |
      | Polish title   | Ancient Text         |
      | Original title | Ancient Text         |
      | Year           | 999                  |
      | Genre          | Non-fiction          |
    Then the novel creation fails
    And the user sees an error that the year must be a valid 4-digit year (1000–9999)
    And no novel is created for Polish title "Ancient Text"

  @req:novels#REQ-007
  Scenario: Attempt to add a novel with a 5-digit year
    When the user tries to create a novel with the following details:
      | Author         | Future Author        |
      | Polish title   | Future Novel         |
      | Original title | Future Novel         |
      | Year           | 10000                |
      | Genre          | Science Fiction      |
    Then the novel creation fails
    And the user sees an error that the year must be a valid 4-digit year (1000–9999)
    And no novel is created for Polish title "Future Novel"

  @req:novels#REQ-008
  Scenario: Attempt to add a novel with a genre outside the dropdown list
    When the user tries to create a novel with the following details:
      | Author         | Jane Doe             |
      | Polish title   | Zmierzch             |
      | Original title | Twilight             |
      | Year           | 2005                 |
      | Genre          | Vampire Romance      |
    Then the novel creation fails
    And the user sees an error that the genre must be one of the allowed options
    And no novel is created for Polish title "Twilight"

  @req:novels#REQ-007
  Scenario Outline: Boundary years are accepted
    When the user creates a novel with the following details:
      | Author         | Boundary Author      |
      | Polish title   | Boundary Novel       |
      | Original title | Boundary Novel       |
      | Year           | <year>               |
      | Genre          | Poetry               |
    Then the novel is created successfully
    And the user sees the novel "Boundary Novel" in their collection

    Examples:
      | year |
      | 1000 |
      | 9999 |

  @req:novels#REQ-010
  @req:novels#REQ-038
  Scenario: Add a novel with a picture of exactly 5 MB
    When the user creates a novel with the following details:
      | Author         | J.R.R. Tolkien       |
      | Polish title   | Hobbit               |
      | Original title | The Hobbit           |
      | Year           | 1937                 |
      | Genre          | Fantasy              |
    And the user uploads a picture "exactly-5mb.png"
    Then the novel is created successfully
    And the novel displays the uploaded picture "exactly-5mb.png"

  @req:novels#REQ-008
  Scenario: Attempt to add a novel with a mix of allowed and disallowed genres
    When the user tries to create a novel with the following details:
      | Author         | Jane Doe                 |
      | Polish title   | Zmierzch                 |
      | Original title | Twilight                 |
      | Year           | 2005                     |
      | Genre          | Fantasy, Vampire Romance |
    Then the novel creation fails
    And the user sees an error that the genre must be one of the allowed options
    And no novel is created for Polish title "Twilight"

  @req:novels#REQ-002
  Scenario: Attempt to add a novel with a whitespace-only author
    When the user tries to create a novel with a whitespace-only author "   "
    And the user enters the following details:
      | Polish title   | Pan Tadeusz          |
      | Original title | Pan Tadeusz          |
      | Year           | 1834                 |
      | Genre          | Poetry               |
    Then the novel creation fails
    And the user sees an error that the author is required
    And no novel is created for Polish title "Pan Tadeusz"

  @req:novels#REQ-012
  Scenario: Anonymous user cannot add a novel
    Given the user logs out
    When the anonymous user tries to create a novel with the following details:
      | Author         | J.R.R. Tolkien       |
      | Polish title   | Hobbit               |
      | Original title | The Hobbit           |
      | Year           | 1937                 |
      | Genre          | Fantasy              |
    Then the novel creation is rejected
    And the anonymous user sees an error that login is required
    And the app shows the login screen
