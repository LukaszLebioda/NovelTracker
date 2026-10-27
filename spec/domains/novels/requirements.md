# Novels — Requirements

**Status:** draft for review
**Date:** 2026-10-27
**Scope (narrowed 2026-10-27):** this domain currently specifies **one feature
only — creating a novel**. Viewing, filtering, editing, deleting, and
authentication (login/logout, per-user ownership) are **deferred**; they will be
added later as separate features. Requirement ids are kept stable: the ids that
belonged to the deferred features were removed, not reused.

- **In scope:** creating a novel.
- **Out of scope (deferred):** authentication and per-user ownership; listing and
  filtering; editing; deleting; marking favourites after creation; enlarging a
  picture.
- **Domain goal:** let a user record a novel — author, both titles, year, one or
  more genres, an optional picture, and an optional description.

## Terms

| Term | Meaning |
|---|---|
| Novel entry | A record of a book (author, Polish and original titles, year, genres, picture, description). |

## Requirements

### REQ-001 — Create a novel | must | draft

**Requirement:** When a user provides an author, a Polish title, an original
title, a 4-digit year, and one or more genres from the allowed list, the system
must create the novel entry.

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

### REQ-009 — No picture when none is uploaded | should | draft

**Requirement:** If no picture is uploaded, the novel must have no picture, so a
default book icon is used wherever the novel is displayed.

### REQ-010 — Picture upload limits | must | draft

**Requirement:** If an uploaded picture is not JPEG, PNG, WebP, or GIF, or is
larger than 5 MB, the system must reject the upload and report why.

### REQ-011 — Empty description when none is provided | should | draft

**Requirement:** If no description is provided, the novel's description must be
empty, shown as "no description yet" wherever the novel is displayed.

### REQ-037 — Mark a novel as a favourite at creation | should | draft

**Requirement:** When a novel is created with the favourite flag set, the system
must store the favourite flag.

### REQ-038 — A valid picture upload is stored | must | draft

**Requirement:** When a picture that is JPEG, PNG, WebP, or GIF and at most 5 MB
is uploaded, the system must store it for the novel.

### REQ-039 — A provided description is stored | must | draft

**Requirement:** When a description is provided, the system must store it with
the novel.

## Removed ids (kept stable, not reused)

These ids were removed on 2026-10-27 with the deferred features:
`REQ-012` (anonymous cannot create), `REQ-013`–`REQ-036` (listing, filtering,
editing, deleting, favourite marking, picture enlargement). They may be
reintroduced with their original meaning when those features are added.

## Traceability

Every scenario in `spec/features/novels/*.feature` carries an
`@req:novels#REQ-nnn` tag pointing at a requirement above.

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
| REQ-011 | create-success |
| REQ-037 | create-favourite-at-creation |
| REQ-038 | create-with-picture, create-picture-exactly-5mb |
| REQ-039 | create-with-description |
