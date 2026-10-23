# View novels — Design

**Status:** design (draft for implementation)
**Date:** 2026-10-23
**Feature:** `spec/features/novels/view-novels.feature` (16 scenarios)
**Review gate:** `view-novels.review.md` — **Approved for design** (2026-10-23)
**Shared model:** [`../../domains/novels/data-model.md`](../../domains/novels/data-model.md)
**UI note:** `spec/domains/novels/ui/novel-list.ui.md`
**Sibling designs:** `create-novel.design.md`, `edit-novel.design.md`,
`delete-novel.design.md`

This design implements REQ-013…REQ-025, REQ-035 and REQ-036. It adds no new
behaviour. The list is the only view; there is no detail route or detail screen.

## 1. API contract

### 1.1 `GET /api/novels`

Returns the session user's entries, sorted and optionally filtered.

| Property | Value |
|---|---|
| Method / path | `GET /api/novels` |
| Auth | Required; `401 unauthenticated` otherwise |
| Request body | None; filters are query parameters |
| Success | `200 OK`, `{ "items": NovelDto[] }` |
| Scope | Always `WHERE user_id = req.userId` |
| Order | `title_pl COLLATE "pl-PL-x-icu" ASC, id ASC` |
| Pagination | None (out of scope) |

Query parameters:

| Parameter | Type | Matching | Notes |
|---|---|---|---|
| `author` | string | Case-insensitive substring of the whole `author` field | Empty/whitespace is ignored. The UI label is "Author (surname)" but no surname extraction is done. |
| `title` | string | Case-insensitive substring of `title_pl` | Empty/whitespace is ignored |
| `year` | integer | Exact `published_year` | Non-integer → `400 invalid_filter` |
| `favourite` | `true`/`1`/`false`/`0` | Exact `is_favourite` | Any other value → `400 invalid_filter` |

Semantics:

- The UI sends at most one of `author`, `title`, `year`. If an API client sends
  several, they are OR-ed: an entry matches if any supplied text/year condition
  matches.
- `favourite=true` is a separate restriction and is AND-ed with the text/year
  condition. This is the only supported combination; there is no advanced
  combined filter.
- Substring metacharacters `%`, `_` and `\` are escaped, so they match literally.
- `author`/`title` matching uses `ILIKE` (case-insensitive but accent-sensitive),
  which satisfies REQ-015 and REQ-016. No diacritic folding is performed for
  filtering; diacritic-aware ordering is handled by the Polish collation.

Example:

```http
GET /api/novels?author=tolkien
```

```json
{
  "items": [
    {
      "id": "1a2b3c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d",
      "author": "J.R.R. Tolkien",
      "titlePl": "Hobbit",
      "titleOriginal": "The Hobbit",
      "year": 1937,
      "genres": ["Fantasy"],
      "description": null,
      "picture": null,
      "isFavourite": false,
      "createdAt": "2026-10-23T08:00:00.000Z",
      "updatedAt": "2026-10-23T08:00:00.000Z"
    },
    {
      "id": "2b3c4d5e-6f7a-4b8c-9d0e-1f2a3b4c5d6e",
      "author": "J.R.R. Tolkien",
      "titlePl": "Władca Pierścieni",
      "titleOriginal": "The Lord of the Rings",
      "year": 1954,
      "genres": ["Fantasy", "Adventure"],
      "description": "An epic high fantasy adventure",
      "picture": {
        "url": "/api/novels/2b3c4d5e-6f7a-4b8c-9d0e-1f2a3b4c5d6e/picture?v=1761206400000",
        "mimeType": "image/jpeg"
      },
      "isFavourite": true,
      "createdAt": "2026-10-23T08:00:00.000Z",
      "updatedAt": "2026-10-23T08:00:00.000Z"
    }
  ]
}
```

Error responses:

| Status | Code | When |
|---|---|---|
| `400` | `invalid_filter` | `year` is not an integer or `favourite` is not a recognised boolean |
| `401` | `unauthenticated` | No session |
| `500` | `internal_error` | Unexpected failure |

### 1.2 `GET /api/novels/:id/picture`

Streams the stored picture for one entry.

| Property | Value |
|---|---|
| Method / path | `GET /api/novels/:id/picture` |
| Auth | Required |
| Request body | None |
| Scope | `WHERE id = :id AND user_id = req.userId` |
| Success | `200 OK`, binary body, `Content-Type` = `picture_mime`, `X-Content-Type-Options: nosniff`, `Content-Disposition: inline` |
| Cache | `Cache-Control: private, max-age=300`, `ETag` |
| Not found | `404 novel_not_found` for unknown id, another user's id, or a novel with no picture |
| No access to bytes | Bytes are never served from a public static directory |

The DTO's `picture.url` is the only URL the client uses. The optional `?v=`
cache-busting token is derived from `updated_at`; it is not an authorization
mechanism.

### 1.3 Not used by this feature

`GET /api/novels/:id` exists for edit prefill only. The list view neither calls
nor links to it: there is no per-novel detail screen (REQ-019).

### 1.4 Scenario-to-endpoint map

| Scenario | Endpoint |
|---|---|
| View an empty novel collection | `GET /api/novels` |
| View novels sorted A-Z by Polish title | `GET /api/novels` |
| User sees only their own novels | `GET /api/novels` |
| Filters by author / Polish title / year | `GET /api/novels?author=…` / `?title=…` / `?year=…` |
| Filter returns no results | `GET /api/novels?…` |
| List shows all fields | `GET /api/novels` |
| Description preview / See more / short / none | `GET /api/novels` |
| Default icon / picture enlarge | `GET /api/novels`; `GET /api/novels/:id/picture` |
| Favourites only | `GET /api/novels?favourite=true` |
| Anonymous cannot view | `GET /api/novels` |

## 2. Data model

No schema change. This feature reads the shared model.

| Table | Read |
|---|---|
| `novels` | All owned rows, filtered and ordered |
| `novel_genres` | All genres for each returned novel, aggregated in canonical order |

Query shape:

```sql
SELECT n.*,
       COALESCE(
         array_agg(g.genre ORDER BY array_position($genreList, g.genre))
           FILTER (WHERE g.genre IS NOT NULL),
         '{}'
       ) AS genres
FROM novels n
LEFT JOIN novel_genres g ON g.novel_id = n.id
WHERE n.user_id = $sessionUserId
  AND (/* OR group: author ILIKE / title_pl ILIKE / published_year = */
       /* AND group: is_favourite when requested */)
GROUP BY n.id
ORDER BY n.title_pl COLLATE "pl-PL-x-icu" ASC, n.id ASC;
```

Indexes used are the shared model's `novels_user_title_idx`,
`novels_user_year_idx`, `novels_user_favourite_title_idx`,
`novels_author_trgm_idx`, `novels_title_pl_trgm_idx`, and the `novel_genres`
primary key.

Empty result has two distinct UI meanings, but the API returns the same
`{ "items": [] }`:

- no active filter → "You have no novels yet" (REQ-014);
- at least one active filter → "No novels match your filter" (REQ-018).

The client owns this distinction from its URL state; no extra server flag is
needed. The server never returns another user's rows, even when titles match.

## 3. UI plan

### 3.1 Route and components

| Item | Design |
|---|---|
| Route | `/novels` (guarded by `RequireAuth`); `/` redirects here |
| Page | `NovelListPage` |
| Filter bar | `NovelFilterBar` — field selector (`Author (surname)` / `Polish title` / `Year`) plus one value input, debounced |
| Favourites | `FavouritesFilter` — checkbox/toggle labelled with an asterisk |
| List | `NovelList` → one `NovelRow` per item |
| Row fields | `NovelPictureThumbnail` or `DefaultBookIcon`, Polish title, original title, author, year, `GenreList`, `FavouriteMarker`, `DescriptionPreview` |
| Row actions | `RowActions` with Edit (link to `/novels/:novelId/edit`) and `DeleteNovelButton` |
| Description | `DescriptionPreview` + `DescriptionDialog` (pop-up) |
| Picture | `NovelPictureThumbnail` (button wrapping the image) + `PictureLightbox` |
| Empty | `EmptyState` with "You have no novels yet" or "No novels match your filter" |
| Loading/error | `LoadingState`, `ErrorState` with retry; 401 redirects to login |

### 3.2 State

The URL is the source of truth for filters, so the browser back button, a
refresh, and a link all restore the same view:

```text
/novels
/novels?filterBy=author&filterValue=Tolkien
/novels?filterBy=title&filterValue=solar
/novels?filterBy=year&filterValue=1954
/novels?favourites=1
/novels?filterBy=author&filterValue=Tolkien&favourites=1
```

- `filterBy` ∈ `author` | `title` | `year`; default `author` when a value is
  present.
- `filterValue` is debounced (300 ms) before the query. An empty value removes
  both `filterBy` and `filterValue` from the URL and restores the full list.
- Changing `filterBy` keeps the view consistent: the value is trimmed; a year
  value is restricted to digits in the input.
- `favourites=1` toggles the favourites restriction; clearing it removes the
  parameter and restores the full list.
- Local state:
  - `descriptionNovelId: string | null` — open "See more" pop-up;
  - `pictureNovelId: string | null` — open larger picture;
  - `deletingNovelId: string | null` — shared with the delete design.
- Server state: `useNovelsQuery({ author, title, year, favourite })` calls
  `GET /api/novels` and returns `{ items, isLoading, error, refetch }`. No
  client-side filtering of a full collection; the API filters and sorts.
- After create/edit/delete, the list query is invalidated/refetched. The list is
  the only place the change is displayed.

Mapping the URL to API parameters: `filterBy=author` → `author=filterValue`;
`title` → `title`; `year` → `year`; `favourites=1` → `favourite=true`. Only one
text/year parameter is ever sent by the UI.

### 3.3 Description preview and "See more"

The full description is in the DTO, so the preview is deterministic on the
client:

```ts
function toDescriptionPreview(description: string | null): {
  text: string;
  canSeeMore: boolean;
  isPlaceholder: boolean;
} {
  if (description == null || description.trim() === '') {
    return { text: 'no description yet', canSeeMore: false, isPlaceholder: true };
  }
  const words = description.trim().split(/\s+/);
  if (words.length <= 10) {
    return { text: description.trim(), canSeeMore: false, isPlaceholder: false };
  }
  return {
    text: words.slice(0, 10).join(' ') + '…',
    canSeeMore: true,
    isPlaceholder: false,
  };
}
```

- The preview length is fixed at **10 words** to make REQ-020's "about the first
  10 words" testable. A description of exactly 10 words is shown in full with no
  ellipsis and no "See more" (REQ-022); 11 or more words get the preview and
  control.
- `DescriptionPreview` renders the text. If `canSeeMore`, it renders a
  "See more" button.
- `DescriptionDialog` is an accessible modal (`role="dialog"`, `aria-modal`,
  focus trap, `Esc`/backdrop close) whose body is
  `max-height: 60vh; overflow-y: auto`, satisfying "scrolls when the description
  is long" (REQ-021). It shows the full, untruncated description.
- The placeholder "no description yet" never has a "See more" control.

### 3.4 Picture thumbnail and larger view

- `NovelPictureThumbnail` renders `<img src={novel.picture.url}>` at a fixed
  thumbnail size (for example 48 × 64 CSS px, `object-fit: cover`) inside a
  button with an accessible name such as `View larger picture of <title>`.
- `DefaultBookIcon` renders the inline SVG book icon when `picture` is `null`.
- Clicking a thumbnail sets `pictureNovelId`; `PictureLightbox` opens a modal
  with the same `picture.url` at `max-width: 90vw; max-height: 90vh;
  object-fit: contain`. The rendered image is larger than the thumbnail, which
  is the REQ-036 assertion. `Esc`/backdrop/close button closes it.
- A missing/404 picture shows the default icon or a broken-image fallback; the
  list itself does not fail.

### 3.5 Favourite and genres

- `FavouriteMarker` renders an asterisk next to the title when
  `isFavourite === true`, with an accessible label.
- `GenreList` renders every genre, comma-separated, in the canonical order from
  the API. It shows more than one genre (REQ-019) and does not abbreviate
  "Science Fiction" (the list note's "Sci-Fi" is visual shorthand that is not
  part of the rules).
- The favourites toggle shows only `isFavourite` rows for the signed-in user
  (REQ-035). Clearing it removes the parameter and restores all rows.

### 3.6 Empty, loading, and anonymous states

- `items.length === 0` and no active filter → `EmptyState` with "You have no
  novels yet".
- `items.length === 0` and an active filter → `EmptyState` with "No novels match
  your filter".
- Loading → `LoadingState`; request failure → `ErrorState` with a retry button.
- A 401 (session expired) → redirect to `/login?returnTo=/novels` and the login
  screen shows the login-required notice (REQ-024).
- Edit and Delete actions are rendered from `RowActions` but are specified in
  the sibling designs; this feature only links to them.

## 4. Test plan

### 4.1 Playwright (primary for UI behaviour)

File: `e2e/novels/view-novels.spec.ts`. Seed novels through the API with the
`request` fixture; act and assert through the UI. Every test uses a fresh user
or a unique set of titles so sort/filter assertions are isolated.

| # | Scenario | Playwright assertion | Newman |
|---|---|---|---|
| V1 | View an empty novel collection | "You have no novels yet" | `GET` 200, `items: []` |
| V2 | View novels sorted A-Z by Polish title (default) | Row order Pan Tadeusz, Solaris, Wiedźmin, Władca Pierścieni | `GET` order matches |
| V3 | User sees only their own novels | Two users with "Lśnienie"; only own row and count 1 | User A list excludes user B's id |
| V4 | Filter novels by author surname | Filter "Tolkien"; 2 rows; no Sapkowski/Lem | `?author=Tolkien` returns 2 |
| V5 | Filter novels by Polish title | Filter "Solaris"; only Solaris | `?title=Solaris` |
| V6 | Filter novels by year of publishing | Filter "1954"; only Władca Pierścieni | `?year=1954` |
| V7 | Filter returns no results | Filter "Rowling"; "No novels match your filter" | `?author=Rowling` → `items: []` |
| V8 | List view shows all fields | Author, Polish title, original title, year, genre, description, picture all visible | DTO contains all fields |
| V9 | Long description is truncated | First 10 words + "…"; See more present; full text absent inline | `description` full in DTO |
| V10 | See more opens a pop-up | Click; dialog shows full text; body scrollable | n/a |
| V11 | Short description is shown in full | "An epic high fantasy adventure"; no ellipsis; no See more | `description` stored |
| V12 | Novel with no description shows a placeholder | "no description yet"; no See more | `description:null` |
| V13 | Novel with no picture shows the default book icon | `DefaultBookIcon` visible, no `<img>` | `picture:null` |
| V14 | Filter the collection to favourites only | Toggle on → 2 rows; toggle off → 3 rows | `?favourite=true` returns only marked |
| V15 | Clicking a picture opens a larger view | Click thumbnail; lightbox image rendered larger than thumbnail; same URL | `GET picture` 200 image |
| V16 | Anonymous user cannot view | Log out, open `/novels`; login screen + notice | `GET` 401 `unauthenticated` |

Additional Playwright checks from the review (no new behaviour): lower-case
author/title filters match; clearing a title filter restores the list; a
10-word description has no See more and an 11-word description does; a
multi-genre novel renders both genres; a filtered empty collection shows
"No novels match your filter".

### 4.2 Newman / Postman

File: `api/novels/novels.postman_collection.json`, folder **View novels**.

| Request | Asserts |
|---|---|
| `V1N` empty list | 200; `items: []` |
| `V2N` default order | 200; `items[].titlePl` ascending under the Polish collation; tie-break by id |
| `V3N` own rows only | Two users; each `GET` returns only its own ids |
| `V4N` author filter | `?author=tolkien` and `?author=Tolkien` return the same two |
| `V5N` title filter | `?title=solar` matches "Solaris" |
| `V6N` year filter | `?year=1954` returns only 1954 |
| `V7N` no matches | `?author=Rowling` → `items: []` |
| `V8N` DTO fields | `NovelDto` has all fields; `genres` array; picture shape |
| `V14N` favourites | `?favourite=true` returns only `isFavourite:true` for that user |
| `V15N` picture | 200, correct `Content-Type`; 404 for no picture; 404 for another user's id |
| `V16N` anonymous | 401 `unauthenticated` |
| `VX` isolation by guessed id | Another user's id returns exactly the same 404 as an unknown id; the list is unchanged |

Newman also checks a malformed `year` (`?year=abcd`) → 400 `invalid_filter` and
an invalid `favourite` (`?favourite=maybe`) → 400 `invalid_filter`.

### 4.3 Fixtures and setup

- Seed at least four novels via `POST /api/novels` for sort/filter tests:
  Władca Pierścieni (1954), Wiedźmin (1990), Solaris (1961), Pan Tadeusz (1834).
- Favourites test: mark two via `PATCH` (edit design) or create with
  `isFavourite:true`.
- Picture test: create one with `cover.jpg`; use the returned `picture.url` for
  both thumbnail and lightbox.
- Description fixtures: a 10-word description, an 11-word description, a long
  description (for scrolling), and one with no description.
- Two-user isolation tests use separate sessions; never rely on the UI to see
  the other user's row.

## 5. Traceability

| Scenario | REQ | Endpoint(s) | UI component(s) | Primary test |
|---|---|---|---|---|
| View an empty novel collection | REQ-014 | `GET /novels` | `NovelListPage`, `EmptyState` | Playwright V1 |
| View novels sorted A-Z by Polish title (default) | REQ-013 | `GET /novels` | `NovelList`, `NovelRow` | Playwright V2 + Newman V2N |
| User sees only their own novels, not other users' novels | REQ-025 | `GET /novels` | `NovelList` | Playwright V3 + Newman V3N |
| Filter novels by author surname | REQ-015 | `GET /novels?author=…` | `NovelFilterBar` | Playwright V4 + Newman V4N |
| Filter novels by Polish title | REQ-016 | `GET /novels?title=…` | `NovelFilterBar` | Playwright V5 + Newman V5N |
| Filter novels by year of publishing | REQ-017 | `GET /novels?year=…` | `NovelFilterBar` | Playwright V6 + Newman V6N |
| Filter returns no results when no novels match | REQ-018 | `GET /novels?…` | `EmptyState` | Playwright V7 + Newman V7N |
| List view shows all fields for each novel | REQ-019 | `GET /novels` | `NovelRow`, `GenreList`, `DescriptionPreview`, `NovelPictureThumbnail` | Playwright V8 + Newman V8N |
| Long description is truncated to a short inline preview | REQ-020 | `GET /novels` | `DescriptionPreview` | Playwright V9 |
| See more opens a pop-up with the full description | REQ-021 | `GET /novels` | `DescriptionDialog` | Playwright V10 |
| Short description is shown in full without a See more control | REQ-022 | `GET /novels` | `DescriptionPreview` | Playwright V11 |
| Novel with no description shows a placeholder | REQ-011 | `GET /novels` | `DescriptionPreview` | Playwright V12 |
| Novel with no picture shows the default book icon in the list | REQ-023 | `GET /novels` | `DefaultBookIcon` | Playwright V13 |
| Filter the collection to favourites only | REQ-035 | `GET /novels?favourite=true` | `FavouritesFilter`, `FavouriteMarker` | Playwright V14 + Newman V14N |
| Clicking a picture opens a larger view | REQ-036 | `GET /novels/:id/picture` | `NovelPictureThumbnail`, `PictureLightbox` | Playwright V15 + Newman V15N |
| Anonymous user cannot view novel collections | REQ-024 | `GET /novels` | `RequireAuth`, login screen | Playwright V16 + Newman V16N |
