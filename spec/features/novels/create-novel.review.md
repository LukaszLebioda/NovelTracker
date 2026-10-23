# create-novel.feature — Spec review

Reviewer: spec-critic · Date: 2026-10-23
Scope reviewed: `create-novel.feature` (21 scenarios), rules
`REQ-001…REQ-012` plus `REQ-037`, `REQ-038`, `REQ-039`,
`spec/domains/novels/ui/novel-form.ui.md`, and cross-domain isolation in
`spec/domains/auth/requirements.md`.

Mechanical checks: every scenario carries at least one valid
`@req:novels#REQ-nnn`; every tag resolves to an existing REQ; no `@todo`
remains. All create-side REQs (REQ-001…REQ-012, REQ-037, REQ-038, REQ-039) are
proven by this feature.

## Blocking issues

None. The previously reported blocking issue is resolved: the create-time
favourite control is now backed by **REQ-037** ("Mark a novel as a favourite at
creation") and proven by *Create a novel marked as a favourite at creation*,
which asserts the asterisk. The earlier success-path gaps are also closed:
REQ-038 backs a stored/shown valid picture and REQ-039 backs a stored/shown
provided description, and the affected scenarios are re-tagged.

## Warnings

- **REQ-008 message drift.** REQ-008 requires reporting "each genre must be one
  of the allowed options"; *…genre outside the dropdown list* and *…mix of
  allowed and disallowed genres* both assert "the genre must be one of the
  allowed options". Align the wording (as was done for REQ-006).
- **Whitespace-only Author scenario uses a non-standard step shape.**
  *Attempt to add a novel with a whitespace-only author* pairs a bespoke
  "whitespace-only author" step with "the user enters the following details",
  unlike every sibling's single details table. Also, REQ-002 says only that the
  author is "missing"; treating a present-but-blank value as missing is sensible
  but is not stated in the rule (compare auth REQ-003, which codifies whitespace
  explicitly).
- **Under-tagging.** *Add a novel with a picture upload* asserts the REQ-011
  placeholder ("no description yet") but is tagged only REQ-001/REQ-038; *Add a
  novel with more than one genre* asserts both genres are displayed but is
  tagged only REQ-001/REQ-008 (no REQ-019 tag).
- **Duplicate assumption lines.** Lines 43–44 and 48–49 restate the same
  picture-format/size decision; harmless today, but the two copies can drift if
  edited independently.
- **Heavy `[DERIVED]` reliance** remains (year range, picture formats, default
  icon); mitigated because each is now promoted to a REQ (REQ-007, REQ-010,
  REQ-009).

## Edge cases missed

- Year values that are **4 digits but out of range** (`0999`, `0100`, `0000`) —
  REQ-007 says "between 1000 and 9999", but only 3-digit `999` and 5-digit
  `10000` cover the boundaries.
- Picture format detection for an uppercase extension (`.JPG`) or a
  renamed/spoofed file (a `.pdf` renamed `.jpg`).
- An **empty-string** genre entry versus "no genre selected" (mixed
  allowed/disallowed is now covered).
- Adding the **same book twice** to one collection (duplicate entries) — no
  rule.
- Oversized description / any description length limit — no rule.
- **Whitespace-only Polish title / Original title** (only Author is covered).
- Display and ordering of multiple genres on the success path.

## Coverage gaps

- This feature covers REQ-001…REQ-012 and REQ-037/REQ-038/REQ-039 in full;
  domain-wide all requirements are covered across the four features.
- REQ-037's acceptance criterion "the flag belongs to the creating user's own
  entry" is not exercised here (owner isolation is shown only in
  `edit-novel.feature`).
- The REQ-010 accepted formats are proven for a `.png` (size edges) but a valid
  JPEG/GIF/WebP success upload is not individually exercised.

## Suggested scenarios

- Create with year `0999` and `0000` → rejected (REQ-007, 4-digit but
  out-of-range).
- Create with an uppercase-extension picture (`cover.JPG`) → accepted, or
  rejected under a stated policy.
- Create with a whitespace-only Polish title / Original title → rejected
  (REQ-003/REQ-004).
- Create a favourite on one account, then assert a same-title entry on another
  account is not starred (REQ-037 ownership AC).

**Verdict:** Approved for design
