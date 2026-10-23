# Novels — Requirements

**Status:** draft for review
**Date:** 2026-10-23
**`[REVISE]`** 2026-10-23 — genre changed to one-or-more; added REQ-034 (favourite), REQ-035 (favourites filter), REQ-036 (picture enlarge). Gherkin scenarios for these follow in a later revise.
**`[REVISE]`** 2026-10-23 — after spec critique: REQ-007 year range made explicit (1000–9999); added REQ-037 (favourite at creation), REQ-038 (valid picture stored/shown), REQ-039 (provided description stored/shown); scenarios added.
**In scope:** create, view, filter, edit, and delete a user's own novel entries.
**Out of scope:** sharing novels, public books, collaborative editing; advanced
or combined filters; pagination; bulk operations; ISBN/publisher/translator/
edition/page-count/language fields; reading status, ratings, or reading dates.
**Domain goal:** Let a logged-in reader keep a private, searchable collection
of the novels they own and read, managing only their own entries.

## Terms

| Term | Meaning |
|---|---|
| Novel entry | One user's record of a book (author, titles, year, genre, picture, description). |
| Own entry | An entry created by the signed-in user. |
| Same book, separate entries | Two users may each hold their own entry for the same book; they are independent. |

## Requirements

### REQ-001 — Create a novel | must | draft

**Requirement:** When a logged-in user provides an author, a Polish title, an
original title, a 4-digit year, and one or more genres from the allowed list,
the system must create the novel entry for that user.
**Acceptance criteria:**
- The novel is created and appears in the user's collection.
- The stored entry belongs to the creating user.

### REQ-002 — Author is required | must | draft
**Requirement:** If the author is missing, the system must reject the creation
and report that the author is required.

### REQ-003 — Polish title is required | must | draft
**Requirement:** If the Polish title is missing, the system must reject the
creation and report that the Polish title is required.

### REQ-004 — Original title is required | must | draft
**Requirement:** If the original title is missing, the system must reject the
creation and report that the original title is required.

### REQ-005 — Year is required | must | draft
**Requirement:** If the year is missing, the system must reject the creation
and report that the year is required.

### REQ-006 — Genre is required | must | draft
**Requirement:** If no genre is selected, the system must reject the creation
and report that at least one genre is required.

### REQ-007 — Year must be a 4-digit number | must | draft
**Requirement:** If the year is not a 4-digit number between 1000 and 9999, the
system must reject the creation and report that the year must be a valid 4-digit
year (1000–9999).

### REQ-008 — Genre must be from the allowed list | must | draft
**Requirement:** If any selected genre is not one of the allowed options, the
system must reject the creation and report that each genre must be one of the
allowed options.
At least one genre must be selected; more than one genre may be selected.
**Allowed options:** Fantasy, Science Fiction, Horror, Thriller, Mystery,
Crime, Romance, Historical, Adventure, Literary, Drama, Poetry, Non-fiction,
Biography, Other (revisable).

### REQ-009 — Default picture when none is uploaded | should | draft
**Requirement:** If no picture is uploaded, the system must show a default book
icon for the novel.

### REQ-010 — Picture upload limits | must | draft
**Requirement:** If an uploaded picture is not JPEG, PNG, WebP, or GIF, or is
larger than 5 MB, the system must reject the upload and report why.

### REQ-011 — Placeholder when no description | should | draft
**Requirement:** If no description is provided, the system must show the text
"no description yet".

### REQ-012 — Anonymous cannot create | must | draft
**Requirement:** If an anonymous visitor tries to create a novel, the system
must reject it and show the login screen.

### REQ-013 — List own novels A-Z | must | draft
**Requirement:** When a logged-in user views their collection, the system must
list their novels sorted A-Z by Polish title.

### REQ-014 — Empty collection message | should | draft
**Requirement:** If the collection is empty, the system must show the message
"You have no novels yet".

### REQ-015 — Filter by author surname | must | draft
**Requirement:** When the user filters by author surname, the system must show
the entries whose author matches as a case-insensitive substring.

### REQ-016 — Filter by Polish title | must | draft
**Requirement:** When the user filters by Polish title, the system must show the
matching entries.

### REQ-017 — Filter by year | must | draft
**Requirement:** When the user filters by year, the system must show the entries
published in exactly that year.

### REQ-018 — No matches message | should | draft
**Requirement:** If a filter matches nothing, the system must show the message
"No novels match your filter".

### REQ-019 — List shows all fields | must | draft
**Requirement:** When the user views their collection, the system must show the
author, Polish title, original title, year, genre, picture (or default icon),
and description preview for each novel — without a separate details screen.

### REQ-020 — Description preview | should | draft
**Requirement:** If a description is longer than the preview length, the system
must show a short inline preview (about the first 10 words, ending with an
ellipsis) and a "See more" control, and must not show the full text inline.

### REQ-021 — See more pop-up | should | draft
**Requirement:** When the user clicks "See more", the system must open a pop-up
showing the full description, scrollable when the text is long.

### REQ-022 — Short description shown in full | should | draft
**Requirement:** If a description is within the preview length, the system must
show it in full with no ellipsis and no "See more" control.

### REQ-023 — Default icon in list | should | draft
**Requirement:** If a novel has no picture, the system must show the default
book icon in the list.

### REQ-024 — Anonymous cannot view | must | draft
**Requirement:** If an anonymous visitor tries to view a collection, the system
must reject it and show the login screen.

### REQ-025 — Only own entries are visible | must | draft
**Requirement:** The system must show a user only their own entries, even when
other users hold their own entries for the same book.

### REQ-026 — Edit a novel | must | draft
**Requirement:** When the user edits fields of one of their novels, the system
must save the changes.

### REQ-027 — Edit validation | must | draft
**Requirement:** If an edit removes a required field or sets a non-4-digit year,
the system must reject the edit and leave the novel unchanged.

### REQ-028 — Replace or add a picture on edit | should | draft
**Requirement:** When the user uploads a picture while editing, the system must
add it if none existed or replace the existing picture.

### REQ-029 — Anonymous cannot edit | must | draft
**Requirement:** If an anonymous visitor tries to edit a novel, the system must
reject it and show the login screen.

### REQ-030 — Cannot edit another user's entry | must | draft
**Requirement:** If a user tries to edit another user's entry, the system must
reject it and change nothing for either user.

### REQ-031 — Delete own novel | must | draft
**Requirement:** When the user deletes one of their own novels, the system must
remove it from their collection.

### REQ-032 — Anonymous cannot delete | must | draft
**Requirement:** If an anonymous visitor tries to delete a novel, the system
must reject it and show the login screen.

### REQ-033 — Cannot delete another user's entry | must | draft
**Requirement:** If a user tries to delete another user's entry, the system must
reject it and leave the other user's entry intact.

### REQ-034 — Mark a novel as a favourite | should | draft

**Requirement:** When the user marks one of their own novels as a favourite, the
system must display that novel with an asterisk; when the user unmarks it, the
system must remove the asterisk.
**Acceptance criteria:**
- Marking adds the asterisk to that novel only.
- Unmarking removes the asterisk.
- The favourite flag belongs to the user's own entry.

### REQ-035 — Filter to favourites only | should | draft

**Requirement:** When the user filters the collection to favourites only, the
system must show only the novels marked as favourites (and only the user's own
entries).
**Acceptance criteria:**
- Only asterisk-marked novels of the signed-in user are shown.
- Clearing the filter restores the normal list.

### REQ-036 — Clicking a picture opens a larger view | should | draft

**Requirement:** When the user clicks a novel's picture in the list, the system
must open a larger view of that picture.
**Acceptance criteria:**
- The larger view shows the same picture, bigger than in the list.
- The list shows the picture as a smaller (thumbnail) image.

### REQ-037 — Mark a novel as a favourite at creation | should | draft

**Requirement:** When a user creates a novel and marks it as a favourite, the
system must store the favourite flag and show the novel with an asterisk.
**Acceptance criteria:**
- The created novel shows the asterisk.
- The flag belongs to the creating user's own entry.

### REQ-038 — A valid picture upload is stored and shown | must | draft

**Requirement:** When the user uploads a picture that is JPEG, PNG, WebP, or GIF
and at most 5 MB, the system must store it and show it for the novel.

### REQ-039 — A provided description is stored and shown | must | draft

**Requirement:** When the user provides a description, the system must store it
and show it as the novel's description preview.

## Traceability

Every scenario in `spec/features/novels/*.feature` carries an
`@req:novels#REQ-nnn` tag pointing at the requirement above.

| Requirement | Scenarios |
|---|---|
| REQ-001 | create-success, create-with-picture, create-with-description, create-multiple-genres |
| REQ-002 | create-missing-author, create-whitespace-author |
| REQ-003 | create-missing-polish-title |
| REQ-004 | create-missing-original-title |
| REQ-005 | create-missing-year |
| REQ-006 | create-missing-genre |
| REQ-007 | create-invalid-year-not-numeric, create-invalid-year-three-digits, create-invalid-year-five-digits, create-boundary-years |
| REQ-008 | create-invalid-genre, create-multiple-genres, create-mixed-genres |
| REQ-009 | create-success |
| REQ-010 | create-picture-invalid-format, create-picture-too-large, create-picture-exactly-5mb |
| REQ-011 | create-success, list-no-description |
| REQ-012 | create-requires-login |
| REQ-013 | list-default-sorting |
| REQ-014 | list-empty |
| REQ-015 | filter-by-author-surname |
| REQ-016 | filter-by-polish-title |
| REQ-017 | filter-by-year |
| REQ-018 | filter-no-matches |
| REQ-019 | list-shows-all-fields |
| REQ-020 | list-description-preview-truncated |
| REQ-021 | list-description-see-more-popup |
| REQ-022 | list-description-short |
| REQ-023 | list-no-picture-default-icon |
| REQ-024 | list-requires-login |
| REQ-025 | list-only-own-novels |
| REQ-026 | update-single-field, update-multiple-fields |
| REQ-027 | update-validation-missing-required-field, update-validation-invalid-year |
| REQ-028 | update-add-picture, update-replace-picture |
| REQ-029 | update-requires-login |
| REQ-030 | update-other-user-novel-denied |
| REQ-031 | delete-success, delete-last-novel |
| REQ-032 | delete-requires-login |
| REQ-033 | delete-other-user-novel-denied |
| REQ-034 | mark-favourite, unmark-favourite, favourite-belongs-to-owner |
| REQ-035 | list-filter-favourites |
| REQ-036 | list-picture-enlarge |
| REQ-037 | create-favourite-at-creation |
| REQ-038 | create-with-picture, create-picture-exactly-5mb |
| REQ-039 | create-with-description |
