# Novels — Shared data model

**Status:** design (draft for implementation)
**Date:** 2026-10-23
**Owner:** novels domain
**Inputs:** `spec/domains/novels/requirements.md`, the four approved
`spec/features/novels/*.feature` files, and `spec/domains/novels/ui/*.ui.md`.
**Consumers:** `create-novel.design.md`, `view-novels.design.md`,
`edit-novel.design.md`, `delete-novel.design.md`.

This is the single source of truth for the novels tables, the shared `NovelDto`,
the endpoint index, and the error envelope. The four feature designs must not
diverge from it.

## 1. Scope and ownership

The novels domain owns exactly two tables: `novels` and `novel_genres`.
The auth domain owns `users` and sessions. The novels domain never stores or
accepts a user id from a request body or query string; `user_id` always comes
from the authenticated session.

Every row in `novels` is one **entry** in one user's private collection. Two
users may each hold an entry for the same book; those rows are independent.
There is no shared book catalogue and no uniqueness rule on titles or authors.

## 2. Cross-domain contract with auth

The auth design owns the `users` table. The novels design assumes the following
contract, which is the only cross-domain dependency:

| Contract | Value used here |
|---|---|
| `users.id` type | `uuid`, default `gen_random_uuid()` |
| `novels.user_id` type | `uuid` (matches `users.id`) |
| Session | HTTP-only `nt_session` cookie set by the auth domain |
| Session middleware | `requireAuth` sets `req.userId` to `users.id` |
| Unauthenticated API result | `401` with `unauthenticated` |
| Unauthenticated UI result | redirect to the auth domain's login screen |

This matches the auth data model's forward reference, which fixes
`novels.user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE`. No
novels query joins `users`; the FK exists for integrity and for
`ON DELETE CASCADE`.

## 3. Tables

### 3.1 `novels`

```sql
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE TABLE novels (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id            uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  author             text NOT NULL,
  title_pl           text COLLATE "pl-PL-x-icu" NOT NULL,
  title_original     text NOT NULL,
  published_year     smallint NOT NULL,
  description        text,
  picture_key        text,
  picture_mime       varchar(32),
  picture_size_bytes integer,
  is_favourite       boolean NOT NULL DEFAULT false,
  created_at         timestamptz NOT NULL DEFAULT now(),
  updated_at         timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT novels_author_not_blank
    CHECK (btrim(author) <> ''),
  CONSTRAINT novels_title_pl_not_blank
    CHECK (btrim(title_pl) <> ''),
  CONSTRAINT novels_title_original_not_blank
    CHECK (btrim(title_original) <> ''),
  CONSTRAINT novels_year_range
    CHECK (published_year BETWEEN 1000 AND 9999),
  CONSTRAINT novels_picture_mime_allowed
    CHECK (picture_mime IS NULL OR picture_mime IN
      ('image/jpeg', 'image/png', 'image/webp', 'image/gif')),
  CONSTRAINT novels_picture_size_range
    CHECK (picture_size_bytes IS NULL OR
           picture_size_bytes BETWEEN 1 AND 5242880),
  CONSTRAINT novels_picture_consistent
    CHECK (
      (picture_key IS NULL AND picture_mime IS NULL AND picture_size_bytes IS NULL)
      OR
      (picture_key IS NOT NULL AND picture_mime IS NOT NULL AND picture_size_bytes IS NOT NULL)
    ),
  CONSTRAINT novels_picture_key_unique UNIQUE (picture_key)
);

CREATE FUNCTION novels_touch_updated_at() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER novels_touch_updated_at
BEFORE UPDATE ON novels
FOR EACH ROW EXECUTE FUNCTION novels_touch_updated_at();
```

Column notes:

| Column | Notes |
|---|---|
| `id` | Opaque `uuid` target for edit/delete. Gherkin names novels by title, but the API always targets `id`; duplicate titles are therefore unambiguous, and ids do not disclose collection size. |
| `user_id` | Owner. Set only from the session. `ON DELETE CASCADE` removes a deleted user's entries. |
| `author` | Trimmed by the API; blank is rejected. |
| `title_pl` | Polish title. Uses the Polish ICU collation so A-Z sorting places `Ł`, `Ś`, `Ż` correctly. |
| `title_original` | Original title. Not used for sorting. |
| `published_year` | `smallint` is sufficient for 1000-9999 and makes the range explicit. |
| `description` | `NULL` means "no description yet". The API trims and converts an empty/whitespace-only value to `NULL`. No length limit is set because no requirement sets one. |
| `picture_key` | Relative storage key such as `novels/2026/10/<uuid>.jpg`. It is never an absolute path, a client filename, or a public URL. `NULL` means the default book icon. |
| `picture_mime` | Detected MIME type, not the client-declared one. One of the four allowed image types. |
| `picture_size_bytes` | Detected size. The check encodes the 5 MB ceiling: 5,242,880 bytes. Exactly 5 MB is valid. |
| `is_favourite` | Per-entry flag. It is not per book and never shared between users. |
| `created_at`, `updated_at` | `updated_at` is maintained by the trigger, including favourite-only edits. |

`picture_key`, `picture_mime` and `picture_size_bytes` are all-or-nothing via
`novels_picture_consistent`. This prevents a row that claims a picture without
a file reference or vice versa.

### 3.2 `novel_genres`

```sql
CREATE TABLE novel_genres (
  novel_id uuid NOT NULL REFERENCES novels(id) ON DELETE CASCADE,
  genre    text NOT NULL,
  PRIMARY KEY (novel_id, genre),
  CONSTRAINT novel_genres_allowed CHECK (genre IN (
    'Fantasy', 'Science Fiction', 'Horror', 'Thriller', 'Mystery',
    'Crime', 'Romance', 'Historical', 'Adventure', 'Literary',
    'Drama', 'Poetry', 'Non-fiction', 'Biography', 'Other'
  ))
);

CREATE INDEX novel_genres_genre_novel_idx
  ON novel_genres (genre, novel_id);
```

- The composite primary key makes a genre unique within one novel.
- `ON DELETE CASCADE` removes genre rows with the novel.
- The `CHECK` is the database-level copy of the fixed allowed list. The list is
  revisable, so changing it is a migration plus a shared constant update, not a
  data-entry task.
- The `(genre, novel_id)` index is not needed by the current scenarios; it is
  included because genre filtering is a likely next requirement and it is cheap.
- Reads aggregate genres per novel and order them by the canonical list order
  (section 3.4). No `position` column is needed; display order is deterministic
  from the list itself.

### 3.3 Why a join table instead of a PostgreSQL array

**Decision: `novel_genres` join table.**

| Concern | Join table (chosen) | `text[]` column |
|---|---|---|
| Allowed values | Per-row `CHECK`; impossible to store an unsupported genre | Array `CHECK` is possible but easier to bypass in application code and harder to evolve |
| Duplicates | Composite primary key prevents them | Application must dedupe; arrays can hold duplicates |
| Genre filtering | Plain indexed join / `EXISTS` | Requires `unnest` or a GIN index; more awkward in joins |
| Referential integrity | FK cascade with the novel | No FK; array travels with the row |
| Read cost | One `LEFT JOIN` + aggregate | No join |
| Write cost | Delete/insert a few rows in the same transaction | One column update |
| Future genre catalogue | Can grow into a lookup table without reshaping novels | Would require migrating the array |

The read-side join cost is negligible for a personal collection, while the
constraints (allowed values, no duplicates, cascade) match the rules directly.
An array would be simpler to read but would move validation and deduplication
into every writer and make later genre filtering harder. The join table is the
better fit for this domain.

### 3.4 Canonical genre list and display order

The fixed list, in canonical order, is:

```text
Fantasy, Science Fiction, Horror, Thriller, Mystery, Crime, Romance,
Historical, Adventure, Literary, Drama, Poetry, Non-fiction, Biography, Other
```

The API returns `genres` sorted by this order, regardless of selection order.
This gives the list view and the edit form a stable order. The create scenario
`Fantasy, Adventure` therefore renders as `Fantasy, Adventure`; a reversed
selection also renders in canonical order. The list is a shared constant in the
server validation module and is also exposed by the supporting
`GET /api/genres` endpoint so the client does not hard-code a second copy.

## 4. Picture storage

Pictures are files on the API host's upload volume, not bytes in PostgreSQL.
The database stores only the reference and metadata:

- `picture_key` — relative key under the configured uploads root.
- `picture_mime` — MIME detected from file content.
- `picture_size_bytes` — detected byte size.

Rules enforced by the API and reflected in the schema:

| Rule | Enforcement |
|---|---|
| Formats JPEG, PNG, WebP, GIF | Magic-byte detection (`file-type` or equivalent); MIME allow-list; extension is derived from detected type, never trusted from the client |
| At most 5 MB | Multipart file-size limit `5 * 1024 * 1024`; DB check; exactly 5,242,880 bytes accepted |
| Client filename | Never used for storage; generated UUID key plus canonical extension |
| Path traversal | Only server-generated keys; no client-supplied path segments |
| Isolation | Picture bytes are served only by the authenticated, ownership-checked `GET /api/novels/:id/picture` route. No public static directory is exposed. |
| Active content | Only raster formats; no SVG. Responses set `X-Content-Type-Options: nosniff`, `Content-Type` from `picture_mime`, and `Content-Disposition: inline`. |
| Cache | `Cache-Control: private, max-age=300` plus an `ETag`; the DTO URL includes a `?v=<updated_at>` token so a replacement is not masked by a stale cache |

`picture_key` is generated before the row is inserted. Replacing a picture
writes a new key, updates the row, and only then deletes the old file. See
section 8.

## 5. Indexes and the queries they serve

```sql
-- Default list and every listing order: per-user, Polish A-Z, stable tie-break.
CREATE INDEX novels_user_title_idx
  ON novels (user_id, title_pl, id);

-- Exact year filter.
CREATE INDEX novels_user_year_idx
  ON novels (user_id, published_year);

-- Favourites-only filter, still ordered A-Z.
CREATE INDEX novels_user_favourite_title_idx
  ON novels (user_id, title_pl, id)
  WHERE is_favourite;

-- Case-insensitive substring filters (ILIKE '%term%').
CREATE INDEX novels_author_trgm_idx
  ON novels USING gin (author gin_trgm_ops);

CREATE INDEX novels_title_pl_trgm_idx
  ON novels USING gin (title_pl gin_trgm_ops);
```

Query mapping:

| Operation | Index |
|---|---|
| List all of a user's novels A-Z | `novels_user_title_idx` |
| Filter favourites, A-Z | `novels_user_favourite_title_idx` |
| Filter by exact year | `novels_user_year_idx` |
| Filter by author substring | `novels_author_trgm_idx` (bitmap-AND with the user filter) |
| Filter by Polish-title substring | `novels_title_pl_trgm_idx` |
| Load genres for a page of novels | `novel_genres` primary key `(novel_id, genre)` |
| Ownership check on edit/delete/picture | primary key `id`, filtered by `user_id` |

All list queries start with `user_id = $sessionUserId`. There is no index or
query path that lists novels across users.

Sorting is always:

```sql
ORDER BY title_pl COLLATE "pl-PL-x-icu" ASC, id ASC
```

The `id` tie-break makes two entries with the same Polish title deterministic.
No pagination is designed because it is out of scope.

## 6. Shared read model — `NovelDto`

Every write endpoint returns the same shape; every list item uses it.

```ts
export type Genre =
  | 'Fantasy' | 'Science Fiction' | 'Horror' | 'Thriller' | 'Mystery'
  | 'Crime' | 'Romance' | 'Historical' | 'Adventure' | 'Literary'
  | 'Drama' | 'Poetry' | 'Non-fiction' | 'Biography' | 'Other';

export interface NovelDto {
  id: string;            // uuid
  author: string;
  titlePl: string;
  titleOriginal: string;
  year: number;
  genres: Genre[];
  description: string | null;
  picture: null | {
    url: string;          // /api/novels/:id/picture?v=<updatedAt epoch ms>
    mimeType: 'image/jpeg' | 'image/png' | 'image/webp' | 'image/gif';
  };
  isFavourite: boolean;
  createdAt: string;      // ISO 8601
  updatedAt: string;      // ISO 8601
}
```

- `description` is the full text, not the preview. The client computes the
  deterministic preview from it. This lets the "See more" pop-up use the same
  payload without a second request.
- `picture` is `null` exactly when `picture_key` is `NULL`; the UI then renders
  the default book icon.
- `genres` is never empty for a stored row.
- The list envelope is `{ "items": NovelDto[] }`. There is no pagination
  envelope and no total count requirement.

## 7. API conventions

### 7.1 Endpoint index

All paths are under `/api`. All novel endpoints require a valid session.

| Method | Path | Purpose | Feature design |
|---|---|---|---|
| `POST` | `/novels` | Create one entry (multipart, optional picture) | `create-novel.design.md` |
| `GET` | `/novels` | List the session user's entries, filtered and sorted | `view-novels.design.md` |
| `GET` | `/novels/:id` | Read one entry for edit prefill and ownership checks; not a detail screen | `edit-novel.design.md` |
| `PATCH` | `/novels/:id` | Partially update fields, genres, favourite, and/or picture | `edit-novel.design.md` |
| `DELETE` | `/novels/:id` | Permanently delete one entry | `delete-novel.design.md` |
| `GET` | `/novels/:id/picture` | Stream the stored picture after an ownership check | view/create/edit |
| `GET` | `/genres` | Supporting endpoint: the canonical genre list (static, no user data) | create/edit |

There is deliberately no `GET /novels/:id` detail screen in the client. The
endpoint exists only so an edit route can be deep-linked and pre-filled. The
list is the only view of a novel's fields.

### 7.2 Content types and field names

- `POST /novels` is always `multipart/form-data`. Text fields are strings;
  `genres` is repeated once per genre; `isFavourite` is `"true"` or `"false"`;
  `picture` is an optional single file part.
- `PATCH /novels/:id` accepts `application/json` when no picture is sent, and
  `multipart/form-data` when a picture is sent (same field names).
- JSON uses camelCase (`titlePl`, `titleOriginal`, `isFavourite`); the database
  uses snake_case. The API layer is the only mapping point.
- Unknown multipart/JSON fields are ignored, not silently persisted.

### 7.3 Error envelope

```json
{
  "error": {
    "code": "validation_error",
    "message": "Validation failed",
    "fields": {
      "year": "The year must be a valid 4-digit year (1000–9999)"
    }
  }
}
```

`fields` is optional; it is present for field-level validation and keyed by the
API field names (`author`, `titlePl`, `titleOriginal`, `year`, `genres`,
`description`, `picture`). A single request may return several field errors.

| Code | HTTP | Meaning |
|---|---|---|
| `validation_error` | 400 | One or more fields are missing, blank, out of range, or not allowed |
| `picture_invalid_type` | 400 | The uploaded file is not JPEG, PNG, WebP, or GIF by content |
| `picture_too_large` | 413 | The uploaded file is larger than 5 MB |
| `unauthenticated` | 401 | No valid session |
| `novel_not_found` | 404 | Unknown id, deleted id, or an id owned by another user |
| `invalid_filter` | 400 | A filter query value is malformed |
| `internal_error` | 500 | Unexpected server failure |

Canonical validation messages (the UI displays these, and tests assert them):

| Field | Message |
|---|---|
| `author` | `The author is required` |
| `titlePl` | `The Polish title is required` |
| `titleOriginal` | `The original title is required` |
| `year` (missing) | `The year is required` |
| `year` (invalid) | `The year must be a valid 4-digit year (1000–9999)` |
| `genres` (empty) | `At least one genre is required` |
| `genres` (not allowed) | `Each genre must be one of the allowed options` |
| `picture` (type) | `The picture must be a JPEG, PNG, WebP, or GIF file` |
| `picture` (size) | `The picture must be at most 5 MB` |

The same `year` message is used on create and edit. The edit feature's prose
says "valid 4-digit number"; tests assert the canonical message above, which is
the create rule's wording and the more specific range statement.

### 7.4 Filter semantics for `GET /novels`

Query parameters:

| Parameter | Meaning |
|---|---|
| `author` | Case-insensitive substring of the whole `author` field. The UI labels it "Author (surname)", but no surname parsing is performed; this matches REQ-015's acceptance wording. |
| `title` | Case-insensitive substring of `title_pl`. |
| `year` | Exact integer match on `published_year`. |
| `favourite` | `true`/`1` restricts to `is_favourite = true`; `false`/`0` or absent does not restrict. |

- Empty or whitespace-only `author`/`title` values are ignored.
- The UI sends at most one of `author`, `title`, `year` at a time. If an API
  client sends more than one, they are combined with **OR** (any match), which
  preserves the derived "filters are OR-based" rule.
- `favourite=true` is an independent restriction and is combined with the text
  filter using **AND**. Clearing it restores the unfiltered list.
- `%`, `_` and `\` in substring values are escaped so they match literally.
- A malformed `year` (non-integer) or an unrecognised `favourite` value returns
  `400 invalid_filter`.
- No pagination, sorting parameter, or combined advanced filter is designed.

### 7.5 Auth and per-entry isolation

- `requireAuth` runs before every novel route. Missing/expired session returns
  the auth domain's `401` body
  (`{ "error": { "code": "unauthenticated", "message": "You are not signed in." } }`);
  the novels UI redirects to login and shows its own "login is required" notice.
  The session cookie is the auth domain's `nt_session`; novels never issues or
  reads a cookie directly.
- Every SQL statement is scoped by the session user:
  - list: `WHERE user_id = $sessionUserId`
  - read/update/delete/picture: `WHERE id = $id AND user_id = $sessionUserId`
- A cross-user id and an unknown id both return `404 novel_not_found`. This
  avoids disclosing whether another user's entry exists.
- `:id` is validated as a UUID before any SQL. A malformed id (for example
  `/novels/not-a-uuid`) returns the same `404 novel_not_found`; it must not
  reach PostgreSQL and must not become a `500`.
- The client never receives or sends a `userId`; there is no request field for
  it.
- The picture route repeats the ownership check. A guessed picture URL for
  another user's entry is a 404.

## 8. Write transactions and file lifecycle

| Operation | Sequence |
|---|---|
| Create | Validate fields/genres/file; write the validated file to its final generated key; begin transaction; insert `novels`; insert `novel_genres`; commit. If the transaction fails, unlink the new file. No row is committed without its file. |
| Edit | Validate; if a picture is supplied, write it to a new key; begin transaction; update `novels` (only supplied fields, including `picture_key/mime/size`) and replace all `novel_genres` when `genres` is supplied; commit. On failure, unlink the new file and keep the old row/picture. On success, unlink the old picture best-effort. |
| Delete | Begin transaction; delete the `novels` row (genres cascade); commit; unlink the picture best-effort. A failed unlink does not fail the request; an optional orphan sweep can remove unreferenced keys later. |

- Genre replacement is delete-all/insert-selected within the same transaction.
- A single `PATCH` that changes fields and `isFavourite` is atomic: all changes
  commit or none do.
- Concurrency is last-write-wins; no optimistic-locking or `If-Match` policy is
  designed because no requirement asks for it.
- `updated_at` changes on every update, including favourite-only edits.

## 9. Invariants

1. A novel row always belongs to exactly one user.
2. Required text fields are trimmed and non-blank.
3. `published_year` is an integer in 1000-9999.
4. A novel has at least one genre; every genre is from the canonical list; no
   duplicates.
5. `description` is either `NULL` or non-blank text; whitespace-only becomes
   `NULL`.
6. A picture is either absent (`NULL` reference) or a validated file with one of
   the four MIME types and size 1-5,242,880 bytes.
7. `is_favourite` is a per-entry boolean and defaults to `false`.
8. Two entries may share a title, author, year, genres, and picture; there is no
   duplicate-entry constraint.
9. There is no soft delete, undo, confirmation, or restore state.
10. No detail screen exists; the list view is the only place fields are shown.

## 10. Migration order and rollback

Apply in this order:

1. Ensure the PostgreSQL build has ICU and the `pgcrypto` and `pg_trgm`
   extensions available.
2. `CREATE EXTENSION IF NOT EXISTS pgcrypto;` (for `gen_random_uuid()`) and
   `CREATE EXTENSION IF NOT EXISTS pg_trgm;`.
3. `users` (auth migration; prerequisite).
4. `novels` and its constraints.
5. `novels_touch_updated_at()` and the `novels_touch_updated_at` trigger.
6. `novel_genres` and its index.
7. The five novel indexes in section 5.

If `pl-PL-x-icu` is unavailable in a local image, create an equivalent ICU
collation (`provider = icu, locale = 'pl-PL'`) in a prerequisite migration and
use it for `title_pl`; do not fall back to `C` or `en_US`, which would sort
Polish diacritics incorrectly. Rollback drops the tables in reverse order after
dropping the indexes and trigger; dropping `novels` cascades `novel_genres`.

## 11. Out of scope

- Shared/public books, sharing, or collaborative editing.
- A separate genre catalogue table or user-managed genres.
- Picture cropping, multiple pictures per novel, external picture URLs, or
  picture removal on edit (REQ-028 covers add and replace only).
- Pagination, sorting options, combined advanced filters, and genre filters.
- Soft delete, undo, and delete confirmation.
- Description length limits and full-text search.
- Optimistic concurrency control.
