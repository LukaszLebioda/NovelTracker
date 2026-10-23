# edit-novel.feature — Spec review

Reviewer: spec-critic · Date: 2026-10-23
Scope reviewed: `edit-novel.feature` (11 scenarios), rules
`REQ-025…REQ-030` and `REQ-034`, `spec/domains/novels/ui/novel-form.ui.md`,
and cross-domain isolation in `spec/domains/auth/requirements.md`.

Mechanical checks: every scenario carries at least one valid
`@req:novels#REQ-nnn`; every tag resolves to an existing REQ; no `@todo`
remains. All edit-side REQs (REQ-025, REQ-026…REQ-030, REQ-034) are proven by
this feature.

## Blocking issues

None. The previously flagged UI-note drift that could have let design build
unbacked behaviour is resolved: `novel-form.ui.md` now scopes REQ-036
(click-to-enlarge) to the list and removes it from the form, annotates the
favourite control as "REQ-034 on edit; REQ-037 at creation", and marks Cancel
as navigation with no behavioural rule. The stale `[DERIVED]` picture-format
list now includes WebP, matching REQ-010.

## Warnings

- **Year range absent from REQ-027.** REQ-027 rejects only a "non-4-digit
  year", while the feature's `[DERIVED]` notes and CREATE's REQ-007 define a
  valid year as 1000–9999. Edit could accept `0999`/`0100` while create
  rejects them. Only `61` is tested, and the asserted message "the year must be
  a valid 4-digit number" differs from create's "a valid 4-digit year
  (1000–9999)".
- **"Edit multiple fields" changes only one field.** The scenario sets Genre to
  "Science Fiction", which is already the novel's genre, so only the
  Description actually changes; the multi-field claim is not proven.
- **REQ-027 "removes a required field" is proven only for Author.** Removing the
  Polish title / Original title / Year / Genre on edit is untested.
- **Picture constraints never exercised on the edit path.** REQ-028 uploads
  pictures, yet no edit scenario rejects an unsupported format or a picture
  larger than 5 MB (REQ-010). Covered by `create-novel.feature`, so not
  blocking here, but the edit flow never proves the constraint.
- **Favourite atomicity unspecified (REQ-034).** The form carries the favourite
  control alongside field edits, but REQ-034 does not state whether a field
  edit and a favourite toggle in the same save are atomic.
- **Tag precision.** *A favourite belongs only to the owner's own entry* is
  tagged REQ-034 + REQ-025; REQ-025 governs list visibility, whereas the
  scenario actually proves per-entry favourite ownership (a REQ-034 acceptance
  criterion).
- **Broad assertion.** "all other fields remain unchanged" in *Edit a single
  field…* is hard to assert exhaustively.

## Edge cases missed

- Editing the year to `999` / `10000` / `0999` (invalid) and to `1000` / `9999`
  (valid) — only `61` is tested.
- Clearing the **genre** on edit (set to empty) — REQ-006/027 boundary.
- Setting an **out-of-list genre** on edit — REQ-008 applied to the edit path.
- **Removing the picture** on edit / reverting to the default icon — REQ-028
  covers add and replace only; no rule mentions removal.
- Setting the description to **empty** on edit → should show "no description
  yet" (REQ-011).
- **Whitespace-only field edits** (Author / Polish title / Original title =
  `"   "`).
- Attempting to mark **another user's entry** directly as favourite — the
  forbidden cross-user operation is never attempted; the existing scenario only
  marks the user's own copy.
- Editing a **non-existent / already-deleted** novel — REQ-030 covers another
  user's entry, not a missing ID.
- Editing Author / Polish title to change the A-Z position, and concurrent
  edits — unstated.

## Coverage gaps

- This feature covers REQ-025, REQ-026…REQ-030 and REQ-034 in full.
- REQ-026 is exercised for Original title (single field) and
  Description/Genre (multiple fields) only; Author, Polish title, and a valid
  Year edit are never updated.
- REQ-028 proves add and replace but not removal; no rule covers removal.

## Suggested scenarios

- Edit year to `1000`, then to `9999` → succeeds; to `999`, then `10000` (and
  `0999`) → rejected, novel unchanged (REQ-027 boundary).
- Edit into an unsupported picture format / a picture larger than 5 MB →
  rejected with the REQ-010 message.
- Clear all genres on edit → rejected, novel unchanged (REQ-027/REQ-006).
- Set the description to empty on edit → the novel shows "no description yet"
  (REQ-011).
- Attempt to favourite another user's entry → denied (REQ-034 + REQ-025).
- Edit the Polish title, then assert the novel's A-Z position updates
  (REQ-026/REQ-013).

**Verdict:** Approved for design
