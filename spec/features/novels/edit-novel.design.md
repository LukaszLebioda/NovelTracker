# Edit a novel — Design

**Status:** design (draft for implementation)
**Date:** 2026-10-23
**Feature:** `spec/features/novels/edit-novel.feature` (11 scenarios)
**Review gate:** `edit-novel.review.md` — **Approved for design** (2026-10-23)
**Shared model:** [`../../domains/novels/data-model.md`](../../domains/novels/data-model.md)
**UI note:** `spec/domains/novels/ui/novel-form.ui.md`
**Sibling designs:** `create-novel.design.md`, `view-novels.design.md`,
`delete-novel.design.md`

This design implements REQ-026…REQ-030 and REQ-034 using the same form, fields,
and `NovelDto` as create. It adds no new behaviour. Title-based Gherkin steps
resolve to IDs in the API; duplicate titles are therefore unambiguous.

## 1. API contract

### 1.1 `GET /api/novels/:id` — edit prefill

| Property | Value |
|---|---|
| Method / path | `GET /api/novels/:id` |
| Auth | Required |
| Request body | None |
| Scope | `WHERE id = :id AND user_id = req.userId` |
| Success | `200 OK`, `NovelDto` |
| Not found | `404 novel_not_found` for unknown, deleted, or another user's id |
| Use | Prefill `/novels/:novelId/edit`; not a detail screen and not linked from the list |

The response is the same `NovelDto` as the list item, including `genres`,
`description`, `picture`, and `isFavourite`.

### 1.2 `PATCH /api/novels/:id`

Partially updates one owned entry. Omitted fields are unchanged, which directly
supports the single-field scenario and the "all other fields remain unchanged"
assertion.

| Property | Value |
|---|---|
| Method / path | `PATCH /api/novels/:id` |
| Auth | Required |
| Scope | `WHERE id = :id AND user_id = req.userId` |
| Content type | `application/json`, or `multipart/form-data` when a picture is sent |
| Success | `200 OK`, updated `NovelDto` |
| Atomicity | Fields, genres, favourite, and picture metadata commit together or not at all |
| Not found | `404 novel_not_found` (unknown, deleted, or another user's id) |

Updatable fields:

| Field | Type | If omitted | Rules |
|---|---|---|---|
| `author` | text | unchanged | If supplied: trimmed; blank is rejected (REQ-027) |
| `titlePl` | text | unchanged | If supplied: trimmed; blank is rejected (REQ-027) |
| `titleOriginal` | text | unchanged | If supplied: trimmed; blank is rejected (REQ-027) |
| `year` | integer | unchanged | If supplied: integer 1000-9999; same range and message as create (REQ-007 applied by REQ-027) |
| `genres` | array/repeated text | unchanged | If supplied: replacement set, at least one, all allowed, deduplicated (REQ-006/REQ-008 applied by REQ-027) |
| `description` | text or `null` | unchanged | Trimmed; empty/whitespace-only/`null` becomes `NULL` (REQ-011) |
| `isFavourite` | boolean | unchanged | Marks/unmarks this entry only (REQ-034) |
| `picture` | one file | unchanged | JPEG/PNG/WebP/GIF by magic bytes, ≤ 5,242,880 bytes; adds if none, replaces if present (REQ-028, REQ-010) |

There is no "remove picture" operation in the feature or requirements. Omitting
`picture` leaves the current picture; sending a new file replaces it. Reverting to
the default icon is out of scope until a rule defines it.

Example request (JSON, single-field edit):

```json
{ "titleOriginal": "The Lord of the Rings" }
```

Example request (favourite only):

```json
{ "isFavourite": true }
```

Example request (genres replacement):

```json
{ "genres": ["Science Fiction"] }
```

Example success response: the full updated `NovelDto` (same shape as create).
For a multipart edit, `genres` is repeated once per genre, `isFavourite` is
`"true"`/`"false"`, and `picture` is one optional file part.

Validation order and failure behaviour:

1. Load the owned row with `id + user_id`. No row → `404`, and neither user's
   data changes (REQ-030).
2. Validate all supplied fields. Any invalid field → `400 validation_error` with
   `fields`; the row and genres are unchanged (REQ-027).
3. If a picture is supplied, validate its content and size before writing.
4. In one transaction: update only supplied `novels` columns; if `genres` was
   supplied, delete the old `novel_genres` rows and insert the new set; commit.
5. If a picture was supplied, write the new file before the transaction and
   unlink it on failure; after a successful commit, unlink the old file.

Error responses:

| Status | Code | When |
|---|---|---|
| `400` | `validation_error` | Blank required field, invalid year, empty/out-of-list genres |
| `400` | `picture_invalid_type` | Bad picture content |
| `413` | `picture_too_large` | Picture > 5 MB |
| `401` | `unauthenticated` | No session |
| `404` | `novel_not_found` | Unknown/deleted id or another user's id |
| `500` | `internal_error` | Unexpected failure; nothing is changed |

Canonical messages are the shared ones. In particular, an invalid year returns
`The year must be a valid 4-digit year (1000–9999)` on edit as well as create;
the edit scenario's "valid 4-digit number" is the same semantic assertion
against that canonical message.

### 1.3 Supporting reads

| Method / path | Why |
|---|---|
| `GET /api/novels` | Refetch the sorted list after a successful edit; the edited row may move A-Z (REQ-026/REQ-013) |
| `GET /api/novels/:id/picture` | Show the added/replaced picture in the form and list |

### 1.4 Ownership and favourite semantics

- `user_id` is never accepted from the client. The `UPDATE` is always
  `WHERE id = :id AND user_id = req.userId`.
- Attempting to edit another user's id returns the same `404 novel_not_found` as
  an unknown id. The other user's row and the caller's own copy are untouched
  (REQ-030).
- `isFavourite` belongs to the row, so marking one user's entry never marks the
  other user's separate entry for the same book (REQ-034).
- A field edit and a favourite toggle in one `PATCH` are atomic.

## 2. Data model

No schema change. This feature updates the shared model.

| Table | Write |
|---|---|
| `novels` | Only supplied columns; `updated_at` is set by the `novels_touch_updated_at` trigger |
| `novel_genres` | When `genres` is supplied: delete all rows for the novel, insert the new set in the same transaction |

Details:

- `published_year` remains within the `novels_year_range` check; the API also
  pre-validates so the client gets a field error rather than a DB error.
- `description` is `NULL` when cleared; the list then shows "no description yet".
- A replaced picture gets a new `picture_key`; the old key is unlinked after
  commit. The `novels_picture_consistent` check guarantees the three picture
  columns move together.
- The genre composite PK deduplicates a repeated genre in the request.
- Indexes are unchanged. Changing `title_pl` naturally changes the row's A-Z
  position because the list re-queries with the shared ordering.
- Concurrency is last-write-wins; no optimistic locking is designed.

## 3. UI plan

### 3.1 Route and components

| Item | Design |
|---|---|
| Route | `/novels/:novelId/edit` (guarded by `RequireAuth`) |
| Page | `NovelEditPage` |
| Data load | `useNovelQuery(novelId)` → `GET /api/novels/:id`; prefill on success |
| Form | `NovelForm` with `mode="edit"` and `initialValues` |
| Controls | Same as create: `TextField`, `YearField`, `GenreMultiSelect`, `PictureField`, `DescriptionField`, `FavouriteField`, `FormErrors`, `FormActions` |
| Favourite | The form's `FavouriteField` is the mark/unmark control (REQ-034) |
| After success | Navigate to `/novels`; the list refetches, re-sorts, and shows the updated fields/asterisk |
| Cancel | Navigate to `/novels` (navigation only) |
| Not found | `404` → `ErrorState` "The novel was not found" with a link back to `/novels` |

The UI note's form is shared verbatim with create. The only differences are the
initial values, the submit endpoint, and the success navigation; the picture
preview shows the existing picture when present.

### 3.2 State

```ts
{
  values: {
    author: string;
    titlePl: string;
    titleOriginal: string;
    year: string;
    genres: Genre[];
    description: string;
    isFavourite: boolean;
  };
  pictureFile: File | null;          // new file only
  picturePreviewUrl: string | null;  // existing picture URL or object URL
  errors: Record<string, string>;
  submitError: string | null;
  isSubmitting: boolean;
}
```

- On load, `NovelEditPage` maps the DTO to `values` and sets the picture preview
  to `novel.picture?.url` (or the default icon).
- Choosing a new file sets `pictureFile` and replaces the preview with an object
  URL; the original URL is revoked on unmount.
- The form submits a full field set plus an optional picture, as `FormData`.
  Although the API supports partial JSON, the form sends the complete current
  state so a save is a coherent snapshot. The API still treats each field as
  supplied or omitted; there is no hidden partial update from the UI.
- `DescriptionField` can be cleared; on save it becomes `NULL` and the list shows
  the placeholder.
- `GenreMultiSelect` may be cleared; the application shows the required-genre
  error on submit, and the server rejects an empty set. The Save button is not
  disabled for validation failures (only while submitting).
- `YearField` enforces 1000-9999 in the UI and the server repeats it. It is a
  text input with `inputMode="numeric"` and custom stepper buttons, so every
  invalid-year case (including non-numeric text) is reachable; the form uses
  `noValidate` and displays the canonical application messages.

### 3.3 Flow

1. `RequireAuth` verifies the session.
2. `NovelEditPage` fetches the novel. `401` → login redirect; `404` → not-found
   state; other error → `ErrorState`.
3. The user changes fields, genres, the favourite checkbox, and/or the picture.
4. Submit sends `PATCH /api/novels/:novelId` (multipart when a picture is
   selected, JSON/FormData otherwise).
5. `200`: invalidate the list and single-novel queries; navigate to `/novels`;
   show "Novel updated". The list shows the new values, A-Z position, asterisk,
   picture, and description preview.
6. `400`/`413`: stay on the edit page, preserve all values, map `fields` to
   inline errors; the stored novel remains unchanged.
7. `404` (including another user's entry reached by a guessed URL): show
   "The novel was not found" and link back; do not reveal whether the id exists.
8. `401`: redirect to login.

Marking a favourite: open the edit page, check `FavouriteField`, save. The list
shows the asterisk after refetch. Unmarking uses the same control and removes it.
No separate one-click favourite control is designed, matching the UI note that
places the control on the form.

## 4. Test plan

### 4.1 Playwright (primary for UI behaviour)

File: `e2e/novels/edit-novel.spec.ts`. Seed the novel through the API, act
through the UI, and assert the list after the form navigates back.

| # | Scenario | Playwright assertion | Newman |
|---|---|---|---|
| E1 | Edit a single field of an existing novel | Edit original title; save; list shows it; other visible fields unchanged | `PATCH` 200; only that field changed |
| E2 | Edit multiple fields of an existing novel | Change description and genre; both shown | `PATCH` 200; both updated |
| E3 | Add a picture to a novel that had none | Default icon → upload; thumbnail shown | `PATCH` multipart 200; `picture` non-null |
| E4 | Replace an existing picture with a new one | Upload `new-cover.jpg`; thumbnail URL changes | `PATCH` 200; new key/mime; old file removed best-effort |
| E5 | Attempt to edit a novel by removing a required field | Clear Author; error; stored row unchanged | `PATCH` 400; `fields.author`; GET unchanged |
| E6 | Attempt to edit a novel with an invalid year | `61`; canonical year error; row unchanged | `PATCH` 400; `fields.year`; GET unchanged |
| E7 | Anonymous user cannot edit a novel | Log out, open edit URL; login screen + notice | `PATCH` 401 `unauthenticated` |
| E8 | User cannot edit another user's novel | Direct other-user URL is not reachable from the list; API test is authoritative | Seed two users; reader PATCHes the other id → 404; both GETs unchanged; reader can still PATCH own id |
| E9 | Mark a novel as a favourite | Check favourite; save; asterisk shown | `PATCH {"isFavourite":true}` 200 |
| E10 | Unmark a favourite | Uncheck; save; asterisk gone | `PATCH {"isFavourite":false}` 200 |
| E11 | A favourite belongs only to the owner's own entry | API test is authoritative for both accounts | Reader marks own copy; both users' GETs; only reader's is `isFavourite:true` |

Additional Playwright checks from the review (no new behaviour): year `1000` and
`9999` accepted; `999`, `10000`, `0999` rejected; clearing the genre selection
rejected; clearing the description shows "no description yet"; whitespace-only
author/titles rejected; changing the Polish title moves the row in the A-Z list.

### 4.2 Newman / Postman

File: `api/novels/novels.postman_collection.json`, folder **Edit novel**.

| Request | Asserts |
|---|---|
| `E1N` single field | 200; `titleOriginal` changed; other fields equal the before snapshot |
| `E2N` multiple fields | 200; description and genres replaced |
| `E3N` add picture | 200; picture metadata; `GET picture` 200 |
| `E4N` replace picture | 200; new `picture.url`; old key no longer referenced |
| `E5N` blank author | 400; `fields.author`; GET snapshot unchanged |
| `E6N` year `61` | 400; `fields.year`; GET snapshot unchanged |
| `E7N` anonymous | 401 |
| `E8N` cross-user | 404; both users' snapshots unchanged; reader's own PATCH still succeeds |
| `E9N` favourite on | 200; `isFavourite:true` |
| `E10N` favourite off | 200; `isFavourite:false` |
| `E11N` favourite ownership | Reader's flag true; other user's flag false |
| `EX` validation extras | `genres: []` → 400; out-of-list genre → 400; `description: ""` → 200 and `null`; whitespace title → 400; year `1000`/`9999` → 200 |
| `EP` picture extras | unsupported type → 400; >5 MB → 413; no change to the stored picture |

Each edit request captures a before snapshot (`GET /api/novels/:id`) and compares
after a failure to prove "remains unchanged".

### 4.3 Fixtures and setup

- Seed one novel per test via `POST /api/novels`; capture its `id`.
- Two-user isolation: create the same title in both accounts, capture both ids,
  authenticate as the reader, and target the other id.
- Pictures: `cover.jpg`, `new-cover.jpg`, `cover.pdf`, `renamed.jpg`,
  `huge-cover.png`, `exactly-5mb.png` from the create fixtures.
- Favourite ownership: Reader marks their own id; then `GET /api/novels` as the
  other user and assert the other row is not favourite.
- Playwright asserts the list after navigation; it does not inspect the DB.

## 5. Traceability

| Scenario | REQ | Endpoint(s) | UI component(s) | Primary test |
|---|---|---|---|---|
| Edit a single field of an existing novel | REQ-026 | `GET /novels/:id`; `PATCH /novels/:id` | `NovelEditPage`, `NovelForm`, `TextField` | Playwright E1 + Newman E1N |
| Edit multiple fields of an existing novel | REQ-026 | `GET /novels/:id`; `PATCH /novels/:id` | `NovelForm`, `DescriptionField`, `GenreMultiSelect` | Playwright E2 + Newman E2N |
| Add a picture to a novel that had none | REQ-028 | `PATCH /novels/:id`; `GET picture` | `PictureField`, `NovelPictureThumbnail` | Playwright E3 + Newman E3N |
| Replace an existing picture with a new one | REQ-028 | `PATCH /novels/:id`; `GET picture` | `PictureField`, `NovelPictureThumbnail` | Playwright E4 + Newman E4N |
| Attempt to edit a novel by removing a required field | REQ-027 | `PATCH /novels/:id` | `TextField`, `FormErrors` | Playwright E5 + Newman E5N |
| Attempt to edit a novel with an invalid year | REQ-027 | `PATCH /novels/:id` | `YearField`, `FormErrors` | Playwright E6 + Newman E6N |
| Anonymous user cannot edit a novel | REQ-029 | `GET /novels/:id`; `PATCH /novels/:id` | `RequireAuth`, login screen | Playwright E7 + Newman E7N |
| User cannot edit another user's novel | REQ-030 | `GET /novels/:id`; `PATCH /novels/:id` | `NovelEditPage` not-found state | Newman E8N |
| Mark a novel as a favourite | REQ-034 | `PATCH /novels/:id` | `FavouriteField`, `FavouriteMarker` | Playwright E9 + Newman E9N |
| Unmark a favourite | REQ-034 | `PATCH /novels/:id` | `FavouriteField`, `FavouriteMarker` | Playwright E10 + Newman E10N |
| A favourite belongs only to the owner's own entry | REQ-034, REQ-025 | `PATCH /novels/:id`; `GET /novels` | `FavouriteMarker` (both accounts) | Newman E11N |
