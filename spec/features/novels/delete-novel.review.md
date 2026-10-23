# delete-novel.feature — Spec review

Reviewer: spec-critic · Date: 2026-10-23
Scope reviewed: `delete-novel.feature` (4 scenarios), rules
`REQ-031…REQ-033`, `spec/domains/novels/ui/novel-list.ui.md`, cross-domain
isolation in `spec/domains/auth/requirements.md`.

Mechanical checks: every scenario carries at least one valid
`@req:novels#REQ-nnn`; every tag resolves to an existing REQ; no `@todo`
remains. All delete REQs (REQ-031, REQ-032, REQ-033) are proven by this
feature.

## Blocking issues

None.

## Warnings

- **No confirmation or undo policy.** `novel-list.ui.md` exposes a Delete
  action ("Delete (REQ-031)"), but no rule or scenario defines a confirmation
  step, and the feature's single `[DERIVED]` note says "no soft-delete or undo
  is assumed". The accidental-deletion path is therefore undefined — resolve
  whether a confirm prompt is required before design.
- **Deletion idempotency undefined.** Nothing states what happens when a user
  deletes an already-deleted or unknown novel; REQ-033 covers another user's
  entry only.
- **Title-based targeting ambiguity.** "User cannot delete another user's
  novel" relies on two identically-titled entries ("Lśnienie") to prove
  isolation. The isolation proof is stronger than the targeting: when one user
  holds two entries with the same Polish title, which entry a title-addressed
  delete removes is unspecified.
- **Single `[DERIVED]` not mirrored by a rule.** The "permanent delete, no
  undo" assumption has no backing requirement in requirements.md.
- **Picture/file lifecycle unspecified.** REQ-031 removes the entry, but no rule
  says whether an associated stored picture file is removed (interacts with
  REQ-028).

## Edge cases missed

- Deleting a novel that **no longer exists** (already deleted / unknown ID).
- Deleting when the user holds **two entries with the same Polish title** —
  which is targeted.
- Deleting a novel that is **marked favourite** — does the entry (and asterisk)
  disappear from the REQ-035 favourites view.
- Deleting the only novel while a **filter is active** vs the full collection
  (REQ-031 is proven only against the full list).
- **Cancelling** a deletion (no confirmation rule exists).
- Deleting a novel that **has a picture** — file cleanup.

## Coverage gaps

- This feature covers REQ-031, REQ-032 and REQ-033 in full. Domain-wide all 36
  REQs are covered across the four features.
- No requirement covers the deletion confirmation/undo policy or the picture
  file lifecycle on delete.
- "Delete the last novel in the collection" already covers the empty-collection
  transition (REQ-031 + REQ-014 interaction) — good.

## Suggested scenarios

- Delete an already-deleted novel → no error/crash and the novel stays absent
  (idempotent delete).
- Given two own entries share the Polish title "Lśnienie", delete one → only
  the targeted entry is removed, the other remains.
- Delete a favourite novel → the entry and its asterisk are gone and the
  favourites filter (REQ-035) no longer lists it.
- If a confirmation step is adopted: cancel a deletion → the novel remains; then
  confirm → it is removed.

**Verdict:** Approved for design
