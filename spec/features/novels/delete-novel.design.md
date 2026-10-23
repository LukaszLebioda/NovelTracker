# Delete a novel — Design

**Status:** design (draft for implementation)
**Date:** 2026-10-23
**Feature:** `spec/features/novels/delete-novel.feature` (4 scenarios)
**Review gate:** `delete-novel.review.md` — **Approved for design** (2026-10-23)
**Shared model:** [`../../domains/novels/data-model.md`](../../domains/novels/data-model.md)
**UI note:** `spec/domains/novels/ui/novel-list.ui.md`
**Sibling designs:** `create-novel.design.md`, `view-novels.design.md`,
`edit-novel.design.md`

This design implements REQ-031…REQ-033 using the shared model. Deletion is
permanent: no soft delete, undo, or confirmation is designed because no
requirement or scenario defines one. Title-based Gherkin steps resolve to IDs in
the API, so two same-titled entries are unambiguous.

## 1. API contract

### 1.1 `DELETE /api/novels/:id`

| Property | Value |
|---|---|
| Method / path | `DELETE /api/novels/:id` |
| Auth | Required (`requireAuth`) |
| Request body | None |
| Scope | `DELETE FROM novels WHERE id = :id AND user_id = req.userId` |
| Success | `204 No Content`, empty body |
| Not found | `404 novel_not_found` for unknown, already-deleted, or another user's id |
| Side effects | Deletes the `novels` row; `novel_genres` rows cascade; the stored picture file is unlinked best-effort after commit |
| Idempotency | Repeating the request returns `404`; the novel stays absent and no error page/crash occurs |

The route never trusts a title, author, or user id from the client. The row is
addressed by `id`; the UI passes the id of the row the user actually sees.

Example success:

```http
DELETE /api/novels/3f2a9c1e-6b7d-4e8f-9a0b-1c2d3e4f5a6b
```

```http
204 No Content
```

Error responses:

| Status | Code | When | Scenario |
|---|---|---|---|
| `401` | `unauthenticated` | No session | Anonymous user cannot delete a novel |
| `404` | `novel_not_found` | Unknown id, already-deleted id, or an id owned by another user | User cannot delete another user's novel |
| `500` | `internal_error` | Unexpected failure; the row is not deleted | not scenario-bearing |

A cross-user id and an unknown id intentionally produce the same `404` body and
message `The novel was not found`. This proves isolation without disclosing
whether another user's entry exists (REQ-033). The other user's row is untouched
because the `WHERE` clause includes `user_id`.

Idempotency note: the HTTP response of a repeated delete is `404`, not `204`.
The observable resource state is the same (the novel is absent). The UI treats a
`404` as "already gone", refetches, and does not show a crash. This resolves the
review's undefined already-deleted case without adding an unstated successful
delete.

### 1.2 Supporting reads

| Method / path | Why |
|---|---|
| `GET /api/novels` | Refetch after a successful delete: count, remaining rows, empty state, active filters, favourites view |
| `GET /api/novels/:id` | Optional confirmation that the id is gone in API tests; the UI does not need it |

There is no delete confirmation endpoint and no undelete/restore endpoint.

### 1.3 What deletion removes

- The `novels` row.
- All `novel_genres` rows for the novel (`ON DELETE CASCADE`).
- The stored picture file, best-effort, after the DB commit. A failed unlink
  does not fail the request; an orphan sweep can remove unreferenced keys later.
- The favourite flag disappears with the row. A deleted favourite no longer
  appears in the favourites-only list (REQ-035) because the row is gone.

The same book may still exist in the other user's collection; only the targeted
entry is removed (REQ-031, REQ-033).

## 2. Data model

No schema change. This feature deletes from the shared model.

| Table | Operation |
|---|---|
| `novels` | `DELETE` by `id` and `user_id`; `updated_at` is irrelevant after deletion |
| `novel_genres` | Cascaded delete via `novels(id)` FK |

Details:

- The delete is a single row delete inside a transaction. The picture unlink is
  outside the transaction and cannot roll it back.
- No soft-delete column, `deleted_at`, or tombstone exists.
- Secondary indexes are maintained automatically by PostgreSQL. No index is
  dropped.
- Deleting a row with no picture skips file cleanup.
- Deleting the last row leaves an empty collection; the list shows "You have no
  novels yet" (REQ-014). If a filter is active, the empty filtered view shows
  "No novels match your filter" as usual.
- No cascade beyond genres: deleting a user is auth's concern and uses the
  `users(id)` FK with `ON DELETE CASCADE` from the shared model.

## 3. UI plan

### 3.1 Route and components

| Item | Design |
|---|---|
| Route | The action lives on `/novels` (guarded by `RequireAuth`); there is no separate delete page |
| Row action | `DeleteNovelButton` inside `RowActions` on each `NovelRow` |
| Confirmation | None. The button performs the delete immediately, matching the feature's direct "When the user deletes the novel" step. No undo is offered. |
| Pending state | The button is disabled while the request is in flight; the row shows a pending style |
| Success | `204`: invalidate/refetch the list. The row disappears; counts update; the last-row case shows the empty message |
| `404` | Treat as already gone: show "The novel was not found", refetch, keep the list usable |
| `401` | Redirect to `/login?returnTo=/novels` with the login-required notice |
| Other errors | `ErrorState`/toast "Something went wrong. Try again."; the row remains until a successful refetch |
| Accessibility | The button has an accessible name including the novel title; a pending state is announced |

The UI note's row actions are "Edit (REQ-026), Delete (REQ-031)". This design
uses the same `RowActions` component as the view design and adds
`DeleteNovelButton`.

### 3.2 State

```ts
{
  deletingNovelId: string | null;  // shared with NovelListPage
  deleteError: string | null;
}
```

- The list query supplies the rows. Delete does not optimistically remove the
  row; it awaits `204` and then refetches. This avoids a false success if the
  server returns `404`/`500`.
- After the refetch, the list re-applies the current URL filters and A-Z order.
  Deleting with a filter active can produce the "No novels match your filter"
  state even when other novels exist; that is the correct filtered view.
- Deleting a favourite removes its asterisk with the row; a favourites-only view
  refetches and no longer lists it.
- No confirmation dialog, undo snackbar, or soft-delete state is designed. The
  review's suggested cancel scenario is therefore not applicable: there is no
  cancel step to test.

### 3.3 Flow

1. The user clicks Delete on a row. The button is disabled.
2. `DELETE /api/novels/:id` is sent with the session cookie.
3. `204`: refetch the list with the current filters; the row is gone. If it was
   the last row in the collection, show "You have no novels yet".
4. `404`: refetch; show "The novel was not found"; the row is gone if it was
   already deleted, otherwise the list remains correct.
5. `401`: redirect to login.
6. `500`/network: show an error; the row remains; the user may retry.

## 4. Test plan

### 4.1 Playwright (primary for UI behaviour)

File: `e2e/novels/delete-novel.spec.ts`. Seed the collection through the API,
then delete through the row action.

| # | Scenario | Playwright assertion | Newman |
|---|---|---|---|
| D1 | Delete a novel from the collection | Two rows; delete one; 1 row; remaining "Wiedźmin"; deleted title gone | `DELETE` 204; `GET` count 1; deleted id absent |
| D2 | Delete the last novel in the collection | One row; delete; "You have no novels yet" | `DELETE` 204; `GET` `items: []` |
| D3 | Anonymous user cannot delete a novel | Log out; API-only attempt; login screen + notice for the guard | `DELETE` 401 `unauthenticated`; row still exists |
| D4 | User cannot delete another user's novel | Not reachable through the reader's UI; API test is authoritative | Two users with "Lśnienie"; reader deletes the other id → 404; both copies still present |

D3 note: the anonymous user cannot see the list or the row, so the UI assertion
is the guard/login screen; the actual delete attempt and 401 are asserted by
Newman. D4 is likewise API-only because the other user's row is never rendered
for the reader.

Additional Playwright checks from the review (no new behaviour): delete a
favourite while the favourites filter is active → the row and asterisk disappear
from the filtered list; delete one of two own entries with the same Polish title
→ only the targeted row (the one whose Delete button was clicked) disappears;
delete the only row while a filter is active → the no-match empty state shows,
and clearing the filter still shows the collection (if any other rows exist).

### 4.2 Newman / Postman

File: `api/novels/novels.postman_collection.json`, folder **Delete novel**.

| Request | Asserts |
|---|---|
| `D1N` delete one of two | 204; `GET` has 1 item; deleted id absent; the other id present |
| `D2N` delete last | 204; `GET` `items: []` |
| `D3N` anonymous | 401; the row still exists |
| `D4N` cross-user | 404 `novel_not_found`; other user's `GET` still has the id; reader's own copy still has its id |
| `DX1` delete already deleted | First 204; second 404; `GET` still absent; no 500 |
| `DX2` delete favourite | 204; `?favourite=true` no longer lists it; the deleted row's asterisk is gone |
| `DX3` duplicate titles | Seed two own entries with the same title; delete one id → only that id is gone; the other remains |
| `DX4` picture cleanup | Delete a row with a picture → 204; the `picture` file key is no longer served; no 500 if the file is already missing |
| `DX5` delete with filter | Seed two rows, filter, delete the matching row → 204; the filtered list is empty; clearing the filter shows the other row |

For `DX4`, the API test may check that the old picture URL is 404 after deletion;
filesystem orphan cleanup itself is not asserted (best-effort by design).

### 4.3 Fixtures and setup

- Seed novels via `POST /api/novels`; capture ids from the responses. Never
  target a row by title in the API; the tests use the captured id.
- Two-user isolation: create the same title in each account, capture both ids,
  authenticate as the reader, delete the other id.
- Favourite: create with `isFavourite:true` or `PATCH` it before deleting.
- Picture: create with `cover.jpg`; retain the returned `picture.url`.
- Filter tests: seed two rows, apply `?author=…`, delete the matching row, then
  re-query without the filter.
- Playwright uses the row's visible title to choose the correct Delete button,
  then asserts the resulting list; duplicate-title tests target a specific row
  by its position/test id, not by title alone.

## 5. Traceability

| Scenario | REQ | Endpoint(s) | UI component(s) | Primary test |
|---|---|---|---|---|
| Delete a novel from the collection | REQ-031 | `DELETE /novels/:id`; `GET /novels` | `DeleteNovelButton`, `RowActions`, `NovelRow`, `NovelList` | Playwright D1 + Newman D1N |
| Delete the last novel in the collection | REQ-031 | `DELETE /novels/:id`; `GET /novels` | `DeleteNovelButton`, `EmptyState` | Playwright D2 + Newman D2N |
| Anonymous user cannot delete a novel | REQ-032 | `DELETE /novels/:id` | `RequireAuth`, login screen; `DeleteNovelButton` not reachable | Playwright D3 + Newman D3N |
| User cannot delete another user's novel | REQ-033 | `DELETE /novels/:id` | not rendered for the reader | Newman D4N |
