# Analyst assumptions:
# [REVISE] create-novel.feature — narrowed on 2026-10-27 to the create feature
#   only. Authentication (login) and per-user ownership are DEFERRED: the
#   "signed in" background and the "anonymous cannot add" scenario were removed,
#   and the success assertions were changed from list-rendering to stored state
#   because the collection view does not exist yet. Scenario content otherwise
#   preserved. Tags point to the canonical ids `@req:novels#REQ-nnn`.
# Domain matched: novels (only the CREATE feature is currently specified).
# Intent (from the original prompt): a user adds a novel to their collection by
#   providing its details, optionally uploading a picture, so they can keep track
#   of the books they own and read.
# [INFERRED] Required fields (Author, Polish title, Original title, Year,
#   Genre) must all be provided and non-empty.
# [INFERRED] Year of publishing must be a 4-digit number (e.g., 2024); years
#   before 1000 or after 9999 are invalid.
# [INFERRED] Picture upload accepts common image formats (JPEG, PNG, WebP, GIF);
#   implementation chooses accepted formats and file size limits.
# [INFERRED] A default book icon is displayed when no picture is uploaded
#   (picture is optional).
# [INFERRED] Description is optional; when empty, the app displays the text
#   "no description yet" (verbatim from the prompt).
# [SCOPE-OUT] Authentication and per-user ownership — deferred to a later
#   login/logout feature; for now creating a novel needs no sign-in.
# [SCOPE-OUT] Viewing/listing/filtering novels, editing, and deleting are
#   separate features and not specified here.
# [SCOPE-OUT] Sharing novels with other users, public books, or collaborative
#   editing.
# [SCOPE-OUT] Cover image editing/cropping, multiple pictures per novel, or
#   external picture URLs — the prompt says "uploaded from local file system".
# [SCOPE-OUT] ISBN, publisher, translator, edition, page count, language, or
#   any other fields — only the fields listed in the prompt are in scope.
# [SCOPE-OUT] Rating, reading status, or reading dates.
# [DECIDED] Genre is chosen from a predefined dropdown list, not freeform text.
#   The current dropdown list (revisable later) is: Fantasy, Science Fiction,
#   Horror, Thriller, Mystery, Crime, Romance, Historical, Adventure, Literary,
#   Drama, Poetry, Non-fiction, Biography, Other.
# [DECIDED] Picture uploads must be JPEG, PNG, WebP, or GIF and no larger than
#   5 MB.
# [DECIDED] A novel may have one or more genres; at least one genre is required;
#   every selected genre must be from the allowed list.
# [DECIDED] A novel may be marked as a favourite at creation (REQ-037).
# [DECIDED] A valid 4-digit year is between 1000 and 9999.

Feature: Create a novel
  As a user of NovelTracker,
  I want to add novels to my collection,
  So that I can keep track of the books I own and read.

  Background:
    Given the novel collection is empty

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
    And the novel has no picture
    And the novel has no description

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
    And the novel is stored with the genres "Fantasy" and "Adventure"

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
    And the novel is stored as a favourite

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
    And the novel is stored with the uploaded picture "witcher-cover.jpg"
    And the novel has no description

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
    And the novel is stored with the description "A psychological novel exploring human limitations"

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
    And the novel is stored with the uploaded picture "exactly-5mb.png"

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
