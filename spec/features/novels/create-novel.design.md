# Create a novel — Design

**Status:** design (draft for implementation)
**Date:** 2026-10-23
**Feature:** `spec/features/novels/create-novel.feature` (21 scenarios, 22 examples)
**Review gate:** `create-novel.review.md` — **Approved for design** (2026-10-23)
**Shared model:** [`../../domains/novels/data-model.md`](../../domains/novels/data-model.md)
**UI note:** `spec/domains/novels/ui/novel-form.ui.md`
**Sibling designs:** `view-novels.design.md`, `edit-novel.design.md`,
`delete-novel.design.md`

This design adds no new behaviour beyond the feature and REQ-001…REQ-012,
REQ-037…REQ-039. It reuses the shared `novels` / `novel_genres` model and the
`NovelDto` contract unchanged.

## 1. API contract

### 1.1 `POST /api/novels`

Creates one entry owned by the session user.

| Property | Value |
|---|---|
| Method / path | `POST /api/novels` |
| Auth | Required (`requireAuth`); `401 unauthenticated` otherwise |
| Content type | `multipart/form-data` |
| Success | `201 Created`, `Location: /api/novels/{id}`, body `NovelDto` |
| Owner | `user_id` is taken from `req.userId`; never from the request |
| Side effects | Inserts one `novels` row, one or more `novel_genres` rows, and optionally one stored picture file |

Request fields (multipart parts):

| Field | Type | Required | Rules |
|---|---|---|---|
| `author` | text | yes | Trimmed; non-blank (REQ-002) |
| `titlePl` | text | yes | Trimmed; non-blank (REQ-003) |
| `titleOriginal` | text | yes | Trimmed; non-blank (REQ-004) |
| `year` | text integer | yes | Integer 1000-9999 (REQ-005, REQ-007) |
| `genres` | repeated text | yes (≥1) | Each value from the canonical list; duplicates are de-duplicated; at least one remains (REQ-006, REQ-008) |
| `description` | text | no | Trimmed; empty/whitespace-only becomes `NULL` (REQ-011, REQ-039) |
| `isFavourite` | `"true"` / `"false"` | no | Defaults to `false` (REQ-037) |
| `picture` | one file | no | JPEG/PNG/WebP/GIF by magic bytes, ≤ 5,242,880 bytes (REQ-010, REQ-038) |

The scenario tables use `Genre | Fantasy, Adventure`. The client sends that as
two repeated `genres` parts. The API does not accept a comma-separated string as
two genres; a comma-containing single value is simply not an allowed genre.

Example success response:

```json
{
  "id": "3f2a9c1e-6b7d-4e8f-9a0b-1c2d3e4f5a6b",
  "author": "J.R.R. Tolkien",
  "titlePl": "Władca Pierścieni",
  "titleOriginal": "The Lord of the Rings",
  "year": 1954,
  "genres": ["Fantasy", "Adventure"],
  "description": null,
  "picture": null,
  "isFavourite": false,
  "createdAt": "2026-10-23T08:00:00.000Z",
  "updatedAt": "2026-10-23T08:00:00.000Z"
}
```

With a picture, `picture` is
`{ "url": "/api/novels/3f2a9c1e-6b7d-4e8f-9a0b-1c2d3e4f5a6b/picture?v=1761206400000", "mimeType": "image/jpeg" }`.

### 1.2 Supporting reads used by this feature

| Method / path | Why |
|---|---|
| `GET /api/novels` | The list after creation; proves "the user sees the novel in their collection" and the count. Sorted A-Z with the shared envelope `{ items }`. |
| `GET /api/novels/:id/picture` | Renders the uploaded picture/thumbnail. Auth and ownership checked. |
| `GET /api/genres` | Populates the multi-select with the canonical list. Static response `{ "items": Genre[] }`, no user data. |

`GET /api/novels` and `GET /api/novels/:id/picture` are specified in
`view-novels.design.md` and the shared data model; this feature does not add a
variant of either.

### 1.3 Error responses

| Status | Code | When | Scenario |
|---|---|---|---|
| `400` | `validation_error` | `author` missing/blank | Attempt to add a novel without an author; … whitespace-only author |
| `400` | `validation_error` | `titlePl` missing/blank | Attempt to add a novel without a Polish title |
| `400` | `validation_error` | `titleOriginal` missing/blank | Attempt to add a novel without an original title |
| `400` | `validation_error` | `year` missing | Attempt to add a novel without a year |
| `400` | `validation_error` | `year` not an integer or outside 1000-9999 | … non-numeric year; … 3-digit year; … 5-digit year |
| `400` | `validation_error` | no `genres` supplied | … with no genre selected |
| `400` | `validation_error` | any genre outside the list | … with a genre outside the dropdown list; … mix of allowed and disallowed genres |
| `400` | `picture_invalid_type` | file content is not JPEG/PNG/WebP/GIF (including a renamed PDF or corrupt image) | … with an unsupported picture format |
| `413` | `picture_too_large` | file is larger than 5 MB | … with a picture larger than 5 MB |
| `401` | `unauthenticated` | no session | Anonymous user cannot add a novel |
| `500` | `internal_error` | unexpected failure; nothing is committed | not scenario-bearing |

The body follows the shared envelope; `fields` carries one entry per invalid
field. When several fields are invalid, all field errors are returned together.
`picture_too_large` is determined by the multipart limit before any row is
written. `picture_invalid_type` is determined by content sniffing, so an
uppercase `.JPG` extension is accepted if the bytes are JPEG, and a `.pdf`
renamed to `.jpg` is rejected.

On every failure, no `novels` row, no `novel_genres` row, and no stored file
remains. The client stays on the form and displays the message(s).

## 2. Data model

No schema change. This feature performs the first writes to the shared model.

| Table | Write |
|---|---|
| `novels` | One row: `user_id` from session; `author`, `title_pl`, `title_original`, `published_year`, `description`, `picture_key/mime/size`, `is_favourite` |
| `novel_genres` | One row per selected genre; composite PK prevents duplicates |

Details:

- `title_pl` uses the Polish ICU collation defined in the shared model.
- `published_year` is `smallint`; 1000 and 9999 are accepted.
- `description` is `NULL` when absent or blank; the list renders
  "no description yet".
- `picture_key` is a server-generated relative key; the client filename is not
  stored. `picture_mime` and `picture_size_bytes` are detected values.
- `is_favourite` is stored on the new row and is owned by the creator's entry.
- Insert of `novels` and `novel_genres` is one transaction. The picture file is
  written before the transaction; on failure it is unlinked.
- No uniqueness constraint exists on title/author/year. Adding the same book
  twice creates two independent entries; no rule forbids it.
- Indexes are unchanged; see the shared model section 5.

## 3. UI plan

### 3.1 Route and components

| Item | Design |
|---|---|
| Route | `/novels/new` (guarded by `RequireAuth`) |
| Page | `NovelCreatePage` |
| Form | `NovelForm` with `mode="create"` |
| Controls | `TextField` (Author, Polish title, Original title), `YearField`, `GenreMultiSelect`, `PictureField`, `DescriptionField`, `FavouriteField`, `FormErrors`, `FormActions` |
| Shared shell | `AppLayout` with a link back to `/novels` |
| After success | Navigate to `/novels`; the list refetches and shows the new row |
| Cancel | Navigate to `/novels` (navigation only; no behavioural rule) |

The UI note's layout maps directly:

| UI note element | Component |
|---|---|
| Author / Polish title / Original title text boxes | `TextField` |
| Year number field with spinner | `YearField` — a text input with `inputMode="numeric"` and custom up/down stepper buttons. It deliberately accepts arbitrary text so the non-numeric scenario is reachable through the UI; the app validates `^\d{4}$` and 1000-9999 on submit. |
| Genre multi-select dropdown | `GenreMultiSelect` (checkbox list in a popover; options from `GET /api/genres`) |
| Picture image picker + preview thumbnail | `PictureField` (file input, preview via `URL.createObjectURL`, accepts the four extensions) |
| Description auto-growing text box | `DescriptionField` (textarea that grows with content) |
| Favourite checkbox | `FavouriteField` (label "Mark as favourite (asterisk)") |
| Save / Cancel | `FormActions` |

### 3.2 State

`NovelForm` owns:

```ts
{
  values: {
    author: string;
    titlePl: string;
    titleOriginal: string;
    year: string;          // input value; parsed on submit
    genres: Genre[];
    description: string;
    isFavourite: boolean;
  };
  pictureFile: File | null;
  picturePreviewUrl: string | null;
  errors: Record<string, string>;   // API field names
  submitError: string | null;       // non-field error (picture size/type, network, 500)
  isSubmitting: boolean;
}
```

- The year is held as a string while typing and validated on submit; the API
  receives an integer.
- The form is rendered with `noValidate` and uses application-level validation,
  so the canonical messages are shown instead of browser-native validation
  bubbles. The custom stepper keeps the "number field with arrows" affordance
  while allowing the non-numeric value in the scenario to be entered.
- `GenreMultiSelect` may be left empty; the application shows "At least one
  genre is required" on submit, and the server repeats the check. The Save
  button is not disabled for validation failures (only while submitting), so the
  no-genre scenario is reachable.
- `PictureField` pre-checks `file.size > 5 * 1024 * 1024` and the extension for
  immediate feedback. The server's magic-byte check is authoritative.
- `FormErrors` shows a summary and each field message; `submitError` is used for
  `picture_too_large`, `picture_invalid_type`, and unexpected failures.
- Values survive a failed submit; the form is not reset.

### 3.3 Flow

1. `RequireAuth` verifies the session. A 401 from any call redirects to
   `/login?returnTo=/novels/new` and the login screen shows "Login is required".
2. On mount, fetch `GET /api/genres` (or use the app's cached constant) to fill
   the multi-select.
3. Submit builds `FormData` with all text fields, repeated `genres` parts,
   `isFavourite`, and the optional `picture` file.
4. `201`: invalidate the list query, navigate to `/novels`, show a success
   notice. The new row appears in A-Z position, with an asterisk if favourite,
   the thumbnail/default icon, and the description preview/placeholder.
5. `400`/`413`: stay on `/novels/new`, map `error.fields` to inline errors,
   show `error.message` for picture errors. No row appears in the list.
6. `401`: redirect to login with the login-required notice.

No optimistic insert is used: the list is refetched from the server.

## 4. Test plan

### 4.1 Playwright (primary for UI behaviour)

File: `e2e/novels/create-novel.spec.ts`.
Each test creates a fresh user through the auth API and signs in via
`storageState`; no shared collection state is assumed. Picture fixtures live in
`e2e/fixtures/images/`.

| # | Scenario (feature) | Playwright assertion | Newman |
|---|---|---|---|
| C1 | Add a new novel with all required fields | Fill form, save, see row; default icon; "no description yet" | `POST` 201 + list contains it |
| C2 | Add a novel with more than one genre | Select Fantasy + Adventure; both shown | `POST` 201; `genres` = both |
| C3 | Create a novel marked as a favourite at creation | Check favourite; asterisk shown | `POST` 201; `isFavourite:true` |
| C4 | Add a novel with a picture upload | Upload `cover.jpg`; thumbnail shown | `POST` 201; `picture` non-null |
| C5 | Attempt to add a novel with an unsupported picture format | Upload `cover.pdf`; message; no row | `POST` 400 `picture_invalid_type`; list unchanged |
| C6 | Attempt to add a novel with a picture larger than 5 MB | Upload `huge-cover.png`; message; no row | `POST` 413 `picture_too_large`; list unchanged |
| C7 | Add a novel with a description | Fill description; preview text shown | `POST` 201; `description` stored |
| C8 | Attempt to add a novel without an author | Blank author; error; no row | `POST` 400; `fields.author` |
| C9 | Attempt to add a novel without a Polish title | Blank title; error; no row | `POST` 400; `fields.titlePl` |
| C10 | Attempt to add a novel without an original title | Blank title; error; no row | `POST` 400; `fields.titleOriginal` |
| C11 | Attempt to add a novel without a year | Blank year; error; no row | `POST` 400; `fields.year` |
| C12 | Attempt to add a novel with no genre selected | No genre; error; no row | `POST` 400; `fields.genres` |
| C13 | Attempt to add a novel with a non-numeric year | "eighteen-thirty-four"; error; no row | `POST` 400; `fields.year` |
| C14 | Attempt to add a novel with a 3-digit year | `999`; error; no row | `POST` 400; `fields.year` |
| C15 | Attempt to add a novel with a 5-digit year | `10000`; error; no row | `POST` 400; `fields.year` |
| C16 | Attempt to add a novel with a genre outside the dropdown list | Client cannot select "Vampire Romance"; API test is authoritative | `POST` 400; `fields.genres` |
| C17 | Boundary years are accepted (outline) | Two tests: `1000`, `9999`; both appear | `POST` 201 for each |
| C18 | Add a novel with a picture of exactly 5 MB | Upload `exactly-5mb.png`; thumbnail shown | `POST` 201; size accepted |
| C19 | Attempt to add a novel with a mix of allowed and disallowed genres | API-only payload; UI cannot produce it | `POST` 400; `fields.genres` |
| C20 | Attempt to add a novel with a whitespace-only author | `"   "`; error; no row | `POST` 400; `fields.author` |
| C21 | Anonymous user cannot add a novel | Log out, open `/novels/new`; login screen + notice | `POST` 401 `unauthenticated` |

For C16 and C19 the UI is a constrained multi-select, so Playwright cannot
originate an out-of-list genre. The Playwright test may assert that the option is
absent; the server rejection is covered by Newman (`C16N`, `C19N`).

Additional Playwright checks from the review (no new behaviour): a
whitespace-only Polish/original title is rejected; an uppercase-extension
`cover.JPG` is accepted; a `.pdf` renamed `.jpg` is rejected; a 4-digit
out-of-range year (`0999`, `0000`) is rejected.

### 4.2 Newman / Postman

File: `api/novels/novels.postman_collection.json`, folder **Create novel**.
Prerequisite: the auth-domain register/login requests in the same collection
establish a session cookie. Each request asserts status, `error.code`/`fields`,
and the response schema.

| Request | Asserts |
|---|---|
| `C1N` create minimal | 201; `NovelDto` shape; `picture:null`; `description:null`; `isFavourite:false` |
| `C2N` multiple genres | 201; `genres` contains both; no duplicates |
| `C3N` favourite at creation | 201; `isFavourite:true` |
| `C4N` picture upload | 201; `picture.url` and `mimeType`; `GET picture` returns 200 image |
| `C5N` PDF / renamed image | 400 `picture_invalid_type`; no row |
| `C6N` >5 MB | 413 `picture_too_large`; no row |
| `C7N` description | 201; description stored |
| `C8N`–`C12N` missing fields | 400; correct `fields` key; list unchanged |
| `C13N`–`C15N` bad years | 400; `fields.year` |
| `C16N` out-of-list genre | 400; `fields.genres` |
| `C17N` years 1000/9999 | 201 each |
| `C18N` exactly 5 MB | 201; `picture` non-null |
| `C19N` mixed genres | 400; `fields.genres` |
| `C20N` whitespace author | 400; `fields.author` |
| `C21N` anonymous | 401 `unauthenticated` |

Newman also verifies that each failed request leaves the user's list unchanged
(compare the list before/after) and that a created row belongs to the
authenticated user only.

### 4.3 Fixtures and setup

- `cover.jpg`, `cover.png`, `cover.webp`, `cover.gif` — small valid images.
- `cover.JPG` — uppercase extension, valid JPEG bytes.
- `cover.pdf` and `renamed.jpg` (PDF bytes named `.jpg`) — rejected by magic
  bytes.
- `huge-cover.png` — 5,242,881+ bytes.
- `exactly-5mb.png` — exactly 5,242,880 bytes and a valid PNG.
- Playwright arranges state through the API (`request` fixture) and acts through
  the UI; it never re-seeds via the form for negative tests.
- Newman uses unique users/emails per run and deletes its created entries in a
  cleanup request; no test depends on pre-existing rows.

## 5. Traceability

| Scenario | REQ | Endpoint(s) | UI component(s) | Primary test |
|---|---|---|---|---|
| Add a new novel with all required fields | REQ-001, 009, 011 | `POST /novels`; `GET /novels` | `NovelCreatePage`, `NovelForm`, `NovelListPage`, `NovelRow`, `DefaultBookIcon`, `DescriptionPreview` | Playwright C1 |
| Add a novel with more than one genre | REQ-001, 008, 019 | `POST /novels`; `GET /novels` | `GenreMultiSelect`, `NovelRow`, `GenreList` | Playwright C2 |
| Create a novel marked as a favourite at creation | REQ-037 | `POST /novels` | `FavouriteField`, `FavouriteMarker` | Playwright C3 |
| Add a novel with a picture upload | REQ-001, 038 | `POST /novels`; `GET /novels/:id/picture` | `PictureField`, `NovelPictureThumbnail` | Playwright C4 |
| Attempt to add a novel with an unsupported picture format | REQ-010 | `POST /novels` | `PictureField`, `FormErrors` | Playwright C5 + Newman C5N |
| Attempt to add a novel with a picture larger than 5 MB | REQ-010 | `POST /novels` | `PictureField`, `FormErrors` | Newman C6N + Playwright C6 |
| Add a novel with a description | REQ-001, 039 | `POST /novels`; `GET /novels` | `DescriptionField`, `DescriptionPreview` | Playwright C7 |
| Attempt to add a novel without an author | REQ-002 | `POST /novels` | `TextField`, `FormErrors` | Playwright C8 + Newman C8N |
| Attempt to add a novel without a Polish title | REQ-003 | `POST /novels` | `TextField`, `FormErrors` | Playwright C9 + Newman C9N |
| Attempt to add a novel without an original title | REQ-004 | `POST /novels` | `TextField`, `FormErrors` | Playwright C10 + Newman C10N |
| Attempt to add a novel without a year | REQ-005 | `POST /novels` | `YearField`, `FormErrors` | Playwright C11 + Newman C11N |
| Attempt to add a novel with no genre selected | REQ-006 | `POST /novels` | `GenreMultiSelect`, `FormErrors` | Playwright C12 + Newman C12N |
| Attempt to add a novel with a non-numeric year | REQ-007 | `POST /novels` | `YearField`, `FormErrors` | Playwright C13 + Newman C13N |
| Attempt to add a novel with a 3-digit year | REQ-007 | `POST /novels` | `YearField`, `FormErrors` | Playwright C14 + Newman C14N |
| Attempt to add a novel with a 5-digit year | REQ-007 | `POST /novels` | `YearField`, `FormErrors` | Playwright C15 + Newman C15N |
| Attempt to add a novel with a genre outside the dropdown list | REQ-008 | `POST /novels` | `GenreMultiSelect` | Newman C16N |
| Boundary years are accepted | REQ-007 | `POST /novels`; `GET /novels` | `YearField`, `NovelRow` | Playwright C17 (×2) + Newman C17N |
| Add a novel with a picture of exactly 5 MB | REQ-010, 038 | `POST /novels`; `GET /novels/:id/picture` | `PictureField`, `NovelPictureThumbnail` | Playwright C18 + Newman C18N |
| Attempt to add a novel with a mix of allowed and disallowed genres | REQ-008 | `POST /novels` | `GenreMultiSelect`, `FormErrors` | Newman C19N |
| Attempt to add a novel with a whitespace-only author | REQ-002 | `POST /novels` | `TextField`, `FormErrors` | Playwright C20 + Newman C20N |
| Anonymous user cannot add a novel | REQ-012 | `POST /novels` | `RequireAuth`, login screen | Playwright C21 + Newman C21N |
