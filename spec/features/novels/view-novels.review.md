# view-novels.feature — Spec review

Reviewer: spec-critic · Date: 2026-10-23
Scope reviewed: `view-novels.feature` (16 scenarios), rules
`REQ-013…REQ-025`, `REQ-035`, `REQ-036`,
`spec/domains/novels/ui/novel-list.ui.md`, cross-domain isolation in
`spec/domains/auth/requirements.md`.

Mechanical checks: every scenario carries at least one valid
`@req:novels#REQ-nnn`; every tag resolves to an existing REQ; no `@todo`
remains. All read-side REQs (REQ-013…REQ-025, REQ-035, REQ-036) are proven by
this feature.

## Blocking issues

None.

## Warnings

- **REQ-016 is underspecified.** "Filter by Polish title" says only "the
  matching entries". REQ-015 explicitly says "case-insensitive substring" and
  REQ-017 says "exactly that year", but REQ-016 states neither. The feature's
  `[DECIDED]` note (line 25) fills in "case-insensitive substring", but
  requirements.md is the source of truth and should be updated to match.
- **REQ-020 is not testable as written.** "about the first 10 words, ending
  with an ellipsis" is vague, and line 33 of the feature says the preview length
  is "implementation-tunable" while the requirement fixes it near 10 words.
  "about" + "tunable" cannot be asserted deterministically.
- **REQ-021 is not testable as written.** "the pop-up content scrolls when the
  description is long" gives no threshold; "Long description is truncated…"
  cannot assert scrolling reliably.
- **REQ-036 testability.** "a larger view of the picture … opens" has no size
  assertion. Also, the scenario places REQ-036's own acceptance criterion
  ("the novel … shows the picture … as a thumbnail") in its `Given` block, so
  it asserts the behaviour under test as a precondition.
- **REQ-035 scenario couples two behaviours.** "Filter the collection to
  favourites only" contains two `When`/`Then` pairs (apply filter, then clear
  filter). Valid Gherkin, but the clear-filter restoration is buried in the
  favourites scenario and not covered for the other filters.
- **Filter label vs rule mismatch.** The control is labelled "author surname"
  (REQ-015 / `novel-list.ui.md`) but REQ-015 matches a case-insensitive
  substring of the *Author field*; surname extraction from "J.R.R. Tolkien" is
  undefined, and the scenario's query "Tolkien" cannot distinguish
  field-substring from surname matching.
- **UI drift.** `novel-list.ui.md` renders the genre as "Sci-Fi" while the rule
  value is "Science Fiction" (REQ-008/019); the abbreviation is display
  behaviour absent from the rules.
- **Stale status note.** requirements.md line 5 says Gherkin for REQ-034/035/036
  "follow in a later revise", although the scenarios already exist.
- **Heavy `[DERIVED]` reliance** (7 notes): A-Z sort, OR-based filters,
  author-field substring, Polish-title substring and exact-year matching are
  asserted only in feature comments; only some are mirrored in requirements.md.

## Edge cases missed

- Case-insensitivity of the author/title filters — the tested queries
  ("Tolkien", "Solaris") are exact-case, so the REQ-015 "case-insensitive"
  clause is unproven.
- **Clearing the author / title / year filters** — only clearing the favourites
  filter is tested (REQ-035).
- Description of **exactly the preview length** (~10 words) — the boundary
  between REQ-020 (preview + "See more") and REQ-022 (full, no control).
- Description of exactly 10 words vs 11 words.
- A filter applied to an **empty collection** (REQ-014 vs REQ-018 boundary).
- A novel with **multiple genres** rendered in the list — REQ-019 shows one.
- Polish **diacritic collation** in the A-Z sort (titles differing only by
  Ł/Ś/Ż), and the sort tie-break when two novels share a Polish title.
- Cross-user access by **guessed ID** (the feature's `[SECURITY]` note mentions
  it; only list-content isolation is tested).

## Coverage gaps

- This feature covers REQ-013…REQ-025, REQ-035 and REQ-036 in full.
  Domain-wide all 36 REQs are covered across the four features.
- REQ-019 is proven only for a single genre; multi-genre rendering is unproven.
- REQ-025 is proven for list contents only; a direct read of another user's
  entry by ID is not exercised.
- No scenario proves the REQ-022 "no ellipsis" clause at the exact boundary.

## Suggested scenarios

- Filter by author "tolkien" (lower-case) → matches "J.R.R. Tolkien" (REQ-015).
- Filter by Polish title as a differently-cased substring (e.g. "solar")
  (REQ-016).
- Apply a title filter, then clear it → the full list is restored.
- Description of exactly 10 words → shown in full, no "See more"; 11 words →
  preview + ellipsis + "See more" (REQ-020/022 boundary).
- Filter an empty collection → "No novels match your filter" (REQ-018, distinct
  from REQ-014).
- List a novel with two genres (`Fantasy, Adventure`) → both shown (REQ-019).

**Verdict:** Approved for design
