# NovelTracker — Repository Files

The repo is split in two: **the product** lives in `app/`; **the process**
(agent pipeline + specs + docs) lives at the root. `.kilo/` and `AGENTS.md`
must stay at the root — Kilo finds them by walking up from the working directory.

---

## Workflow: From Plain English to Running Code

**Example scenario:** You want users to be able to add private notes to their novels.

---

### Your Plain-English Input (what you type)

```
/spec-gather Users should be able to add a private note to each novel in their 
collection. The note is just text, maximum 2000 characters. Only the owner can 
see or edit the note. The note is optional — novels without a note are fine.
```

### Stage 1: Gather (spec-analyst)

**You run:** `/spec-gather Users should be able to add notes to their novels`

**What happens:**
1. Kilo loads `.kilo/agent/01-spec-analyst.md` (the only agent allowed to touch specs)
2. Agent loads `AGENTS.md` + `.kilo/rules/core.md` (always-on briefing + rules)
3. Agent **reads** `spec/domains/novels/requirements.md` (existing rules for the domain)
4. Agent may ask you clarifying questions (e.g., "Should notes be private? Max length?")
5. Agent **writes/updates** `spec/domains/novels/requirements.md` — adds REQ-040, REQ-041, etc. in EARS form ("When a user views a novel they own, the system must display the note field.")
6. Agent **writes** `spec/features/novels/add-notes.feature` — Gherkin scenarios (Given/When/Then), each tagged `@req:novels#REQ-040` pointing back to the rule
7. Agent prints `[STATUS] novels/add-notes gathered done`
8. **You review and approve** — the `.feature` file is now **frozen**; future changes go only through the analyst in `--revise` mode

**Files created/updated:**
- ✏️ `spec/domains/novels/requirements.md` (added REQ-040, REQ-041)
- ➕ `spec/features/novels/add-notes.feature` (new)

**Example output — `spec/domains/novels/requirements.md` (excerpt):**

```markdown
### REQ-040 — Add a note to a novel | must | draft

**Requirement:** When a user adds or updates a note for a novel they own, the 
system must store the note text (up to 2000 characters) with that novel.
**Why it matters:** Users want to keep private reminders or thoughts about each book.
**Acceptance criteria:**
- The user sees the saved note when they view or edit that novel.
- The note is isolated per user — other users' copies of the same book have 
  separate notes.

### REQ-041 — Note length limit | must | draft

**Requirement:** When a user submits a note longer than 2000 characters, the 
system must reject it with a clear error.
**Why it matters:** Prevents unbounded database growth and keeps the UI manageable.
**Acceptance criteria:**
- Exactly 2000 characters is accepted.
- 2001 characters is rejected with "The note must be 2000 characters or fewer."
```

**Example output — `spec/features/novels/add-notes.feature`:**

```gherkin
Feature: Novel notes
  As a reader
  I want to add private notes to my novels
  So I can remember my thoughts or reading progress

# Analyst assumptions:
# - [DERIVED] Notes are stored per user per novel (not shared across users' copies)
# - [DECIDED] Maximum 2000 characters (from the prompt)
# - [DERIVED] Empty/null note is valid (notes are optional)
# - [SCOPE-OUT] Formatting (plain text only)
# - [SCOPE-OUT] Note history / versioning

Background:
  Given the database is empty
  And user "reader@example.com" is registered and logged in

Scenario: Add a note to a novel
  @req:novels#REQ-040
  Given the user owns a novel "Dune" with no note
  When the user adds the note "Read in 2025. Loved the politics."
  Then the note is saved
  And when the user views the novel, they see the note "Read in 2025. Loved the politics."

Scenario: Edit an existing note
  @req:novels#REQ-040
  Given the user owns a novel "Dune" with note "First read"
  When the user updates the note to "Second read - even better"
  Then the note is updated
  And when the user views the novel, they see "Second read - even better"

Scenario: Remove a note
  @req:novels#REQ-040
  Given the user owns a novel "Dune" with note "Finished"
  When the user clears the note
  Then the novel has no note

Scenario: Note is isolated per user
  @req:novels#REQ-040
  Given user "alice@example.com" owns a novel "Dune" with note "Alice's note"
  And user "bob@example.com" owns a novel "Dune" with no note
  When Bob views his copy of "Dune"
  Then Bob sees no note
  And Alice's note remains unchanged

Scenario: Note within 2000 characters is accepted
  @req:novels#REQ-041
  Given the user owns a novel "Dune"
  When the user adds a note of exactly 2000 characters
  Then the note is saved

Scenario: Note exceeding 2000 characters is rejected
  @req:novels#REQ-041
  Given the user owns a novel "Dune"
  When the user adds a note of 2001 characters
  Then the system shows the error "The note must be 2000 characters or fewer."
  And the note is not saved
```

---

### Stage 2: Critique (spec-critic)

**You run:** `/spec-critique novels/add-notes`

**What happens:**
1. Kilo loads `.kilo/agent/02-spec-critic.md`
2. Agent **reads** `spec/features/novels/add-notes.feature` (the scenarios you just froze)
3. Agent **reads** `spec/domains/novels/requirements.md` (checks every scenario traces to a rule)
4. Agent checks: correctness, completeness, coverage, edge cases, contradictions
5. Agent **writes** `spec/features/novels/add-notes.review.md` with verdict:
   - **"Approved for design"** → you can continue
   - **"Changes required"** (blocking issues) → run `/spec-gather novels/add-notes --revise` to fix the spec first
6. Agent prints `[STATUS] novels/add-notes critiqued done`

**Files created:**
- ➕ `spec/features/novels/add-notes.review.md` (verdict + warnings)

**Example output — `spec/features/novels/add-notes.review.md`:**

```markdown
# Feature Review: Novel Notes

**Feature:** `novels/add-notes`  
**Date:** 2026-10-23  
**Reviewer:** spec-critic  
**Verdict:** ✅ **Approved for design**

## Summary

The feature spec defines 6 scenarios covering adding, editing, removing, and 
length-validating private notes on novels. All scenarios trace cleanly to 
REQ-040 and REQ-041.

## Blocking Issues

None.

## Warnings

1. **Edge case:** What happens if a user tries to add a note to a novel they 
   don't own? The spec doesn't explicitly cover unauthorized access. 
   Recommendation: rely on existing ownership checks (REQ-003, REQ-032) — no 
   change needed, but document the assumption.

## Coverage Gaps

None — the 2000-character boundary is tested (exactly 2000 = pass, 2001 = fail).

## Suggested Scenarios (optional)

- **Whitespace-only note:** Should a note containing only spaces be treated as 
  empty? (Low priority — can defer.)

## Traceability

| Scenario | Requirement |
|---|---|
| Add a note to a novel | REQ-040 |
| Edit an existing note | REQ-040 |
| Remove a note | REQ-040 |
| Note is isolated per user | REQ-040 |
| Note within 2000 characters | REQ-041 |
| Note exceeding 2000 characters | REQ-041 |

All scenarios covered. ✅
```

---

### Stage 3: Design (spec-architect)

**You run:** `/spec-design novels/add-notes`

**What happens:**
1. Kilo loads `.kilo/agent/03-spec-architect.md`
2. Agent **reads** `spec/features/novels/add-notes.feature`, `add-notes.review.md`, `spec/domains/novels/requirements.md`
3. Agent **reads** `spec/domains/novels/data-model.md` (existing database tables)
4. Agent decides:
   - Database change: add `notes TEXT` column to `novels` table → writes migration plan
   - API: `PATCH /api/novels/:id` accepts `{ note: "..." }` → writes contract
   - UI: edit-novel form gains a textarea → writes component plan
   - Tests: which scenarios are API-only, which are UI → writes test plan
5. Agent **writes** `spec/features/novels/add-notes.design.md` (complete technical design)
6. Agent **updates** `spec/domains/novels/data-model.md` (adds the `notes` column)
7. Agent prints `[STATUS] novels/add-notes designed done`

**Files created/updated:**
- ➕ `spec/features/novels/add-notes.design.md` (new)
- ✏️ `spec/domains/novels/data-model.md` (updated)

**Example output — `spec/features/novels/add-notes.design.md` (excerpt):**

```markdown
# Design: Novel Notes

**Feature:** `novels/add-notes`  
**Date:** 2026-10-23  
**Architect:** spec-architect

## Database Schema Changes

### Migration: Add `note` column to `novels`

```sql
-- migration: 0003_add_notes_column.sql
ALTER TABLE novels
ADD COLUMN note TEXT NULL;

COMMENT ON COLUMN novels.note IS 'Private user note, max 2000 chars (validated at app layer)';
```

No index required — notes are retrieved as part of novel records, never queried independently.

---

## API Contract

### `PATCH /api/novels/:id`

**Existing endpoint** — extend to accept `note` field.

**Request:**
```json
{
  "note": "Read in 2025. Loved the politics."  // optional, string, max 2000 chars
}
```

**Response (200 OK):**
```json
{
  "id": "uuid",
  "author": "Frank Herbert",
  "polishTitle": "Diuna",
  "originalTitle": "Dune",
  "year": 1965,
  "genres": ["Science Fiction"],
  "note": "Read in 2025. Loved the politics.",
  "favourite": false,
  "picture": null,
  "description": "..."
}
```

**Errors:**
- `400` `note_too_long` — "The note must be 2000 characters or fewer."
- `401` `unauthenticated` — user not signed in
- `404` `novel_not_found` — novel doesn't exist
- `403` `not_owner` — user doesn't own this novel

**Validation:**
- `note` is optional (null/omitted = clear the note)
- If provided, must be ≤ 2000 characters (UTF-8 length)
- Empty string treated as clearing the note

---

## UI Plan

### Edit Novel Form (`app/client/src/components/EditNovelForm.jsx`)

Add a textarea below the description field:

```jsx
<label htmlFor="note">Private Note (optional)</label>
<textarea
  id="note"
  name="note"
  data-testid="novel-note-input"
  maxLength={2000}
  rows={4}
  placeholder="Your private thoughts, reminders, or reading notes..."
  value={formData.note || ''}
  onChange={handleChange}
/>
<p className="char-count">{(formData.note || '').length} / 2000</p>
```

**Character counter** updates live as the user types.

### Novel List (`app/client/src/components/NovelList.jsx`)

No change — notes are private; not shown in the list view. Only visible when 
editing or viewing the detail.

---

## Test Plan

### API Tests (Postman/Newman)

- `POST /api/novels` — add note at creation
- `PATCH /api/novels/:id` — add/update/clear note
- Boundary: exactly 2000 chars (pass), 2001 chars (fail)
- Isolation: user A cannot see user B's note

### UI Tests (Playwright)

- Add note via edit form → verify saved
- Edit existing note → verify updated
- Clear note → verify removed
- Character counter shows correct count
- 2001-character note shows validation error

---

## Traceability

| Requirement | Scenario | Implementation |
|---|---|---|
| REQ-040 | Add/edit/remove note | `novels` table `note` column, PATCH endpoint, edit form textarea |
| REQ-041 | Length validation | API validation (≤ 2000), UI maxLength + counter, error message |
```

**Example output — `spec/domains/novels/data-model.md` (excerpt):**

```markdown
## `novels` table

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PRIMARY KEY | Novel entry identifier |
| `user_id` | UUID | NOT NULL, FK → users(id) | Owner |
| `author` | VARCHAR(200) | NOT NULL | Author name |
| `polish_title` | VARCHAR(200) | NOT NULL | Title in Polish |
| ... | ... | ... | ... |
| `note` | TEXT | NULL | Private user note (max 2000 chars, app-validated) ← NEW |
```

---

### Stage 4: Test (spec-test-author) — Red Phase

**You run:** `/spec-test novels/add-notes`

**What happens:**
1. Kilo loads `.kilo/agent/04-spec-test-author.md`
2. Agent **reads** `spec/features/novels/add-notes.feature`, `.design.md`, `data-model.md`
3. Agent **reads** existing test helpers in `app/tests/e2e/auth/helpers.js` (to reuse login patterns)
4. Agent **writes** `app/tests/e2e/novels/add-notes.spec.js` (Playwright browser tests — one `test()` per Gherkin scenario, each carrying the `@req:novels#REQ-040` tag in the test name or a comment)
5. Agent **writes/updates** `app/tests/api/novels.postman_collection.json` (Newman API tests for the PATCH endpoint scenarios)
6. Agent runs the tests → they **fail** (red phase) because the feature doesn't exist yet
7. Agent prints `[STATUS] novels/add-notes tested-red done`

**Files created/updated:**
- ➕ `app/tests/e2e/novels/add-notes.spec.js` (new Playwright tests)
- ✏️ `app/tests/api/novels.postman_collection.json` (added requests)
- ✏️ `app/tests/package.json` (updated `test:e2e` script if needed)

**Example output — `app/tests/e2e/novels/add-notes.spec.js` (excerpt):**

```javascript
import { test, expect } from '@playwright/test';
import { seedAccount, loginViaUI } from '../auth/helpers.js';

// @req:novels#REQ-040 — Add a note to a novel
test('user can add a note to their novel', async ({ page, request }) => {
  const account = await seedAccount(request);
  await loginViaUI(page, account);

  // Create a novel
  await page.goto('/novels/new');
  await page.fill('[data-testid="author-input"]', 'Frank Herbert');
  await page.fill('[data-testid="polish-title-input"]', 'Diuna');
  await page.fill('[data-testid="original-title-input"]', 'Dune');
  await page.fill('[data-testid="year-input"]', '1965');
  await page.selectOption('[data-testid="genre-select"]', 'Science Fiction');
  await page.click('[data-testid="submit-button"]');

  // Edit and add note
  await page.click('[data-testid="edit-novel-button"]');
  await page.fill('[data-testid="novel-note-input"]', 'Read in 2025. Loved the politics.');
  await page.click('[data-testid="save-button"]');

  // Verify note saved
  await page.click('[data-testid="edit-novel-button"]');
  const noteValue = await page.inputValue('[data-testid="novel-note-input"]');
  expect(noteValue).toBe('Read in 2025. Loved the politics.');
});

// @req:novels#REQ-041 — Note exceeding 2000 characters is rejected
test('note longer than 2000 characters shows error', async ({ page, request }) => {
  const account = await seedAccount(request);
  await loginViaUI(page, account);
  
  // Create a novel and try to add 2001-char note
  const longNote = 'a'.repeat(2001);
  await page.goto('/novels/new');
  await page.fill('[data-testid="author-input"]', 'Test Author');
  await page.fill('[data-testid="polish-title-input"]', 'Test');
  await page.fill('[data-testid="original-title-input"]', 'Test');
  await page.fill('[data-testid="year-input"]', '2020');
  await page.selectOption('[data-testid="genre-select"]', 'Fiction');
  await page.fill('[data-testid="novel-note-input"]', longNote);
  await page.click('[data-testid="submit-button"]');

  // Verify error message
  await expect(page.locator('[data-testid="error-message"]'))
    .toHaveText('The note must be 2000 characters or fewer.');
});
```

**Example output — `app/tests/api/novels.postman_collection.json` (excerpt):**

```json
{
  "name": "PATCH /api/novels/:id - add note",
  "request": {
    "method": "PATCH",
    "url": "{{baseUrl}}/api/novels/{{novelId}}",
    "header": [{"key": "Content-Type", "value": "application/json"}],
    "body": {
      "mode": "raw",
      "raw": "{\"note\": \"Read in 2025. Loved the politics.\"}"
    }
  },
  "event": [{
    "listen": "test",
    "script": {
      "exec": [
        "// @req:novels#REQ-040",
        "pm.test('Status 200', () => pm.response.to.have.status(200));",
        "pm.test('Note saved', () => {",
        "  const body = pm.response.json();",
        "  pm.expect(body.note).to.eql('Read in 2025. Loved the politics.');",
        "});"
      ]
    }
  }]
},
{
  "name": "PATCH /api/novels/:id - note too long",
  "request": {
    "method": "PATCH",
    "url": "{{baseUrl}}/api/novels/{{novelId}}",
    "body": {
      "mode": "raw",
      "raw": "{\"note\": \"{{longNote2001}}\"}"
    }
  },
  "event": [{
    "listen": "test",
    "script": {
      "exec": [
        "// @req:novels#REQ-041",
        "pm.test('Status 400', () => pm.response.to.have.status(400));",
        "pm.test('Error code note_too_long', () => {",
        "  pm.expect(pm.response.json().error).to.eql('note_too_long');",
        "});"
      ]
    }
  }]
}
```

---

### Stage 5: Implement (spec-implementer) — Green Phase

**You run:** `/spec-implement novels/add-notes`

**What happens:**
1. Kilo loads `.kilo/agent/05-spec-implementer.md`
2. Agent **reads** `spec/features/novels/add-notes.feature`, `.design.md`, `data-model.md`, and the new tests in `app/tests/`
3. Agent **writes** `app/server/migrations/0003_add_notes_column.sql` (adds `notes TEXT NULL` to `novels`)
4. Agent **updates** `app/server/src/routes/novels.js` (or creates it) — adds/updates `PATCH /api/novels/:id` handler that accepts and saves `note`
5. Agent **updates** `app/client/src/components/EditNovelForm.jsx` (or creates it) — adds `<textarea>` for notes
6. Agent runs the tests → they **pass** (green phase)
7. Agent prints `[STATUS] novels/add-notes implemented done`

**Files created/updated:**
- ➕ `app/server/migrations/0003_add_notes_column.sql` (new migration)
- ✏️ `app/server/src/routes/novels.js` (updated endpoint)
- ✏️ `app/client/src/components/EditNovelForm.jsx` (updated form)
- (possibly) ✏️ `app/server/src/index.js` (if routes needed wiring)

**Example output — `app/server/migrations/0003_add_notes_column.sql`:**

```sql
-- 0003_add_notes_column.sql
-- Adds private notes to novels (REQ-040, REQ-041)

ALTER TABLE novels
ADD COLUMN note TEXT NULL;

COMMENT ON COLUMN novels.note IS 'Private user note, max 2000 chars (validated at app layer)';
```

**Example output — `app/server/src/routes/novels.js` (excerpt):**

```javascript
// PATCH /api/novels/:id - update novel (includes note field)
router.patch('/:id', authenticate, async (req, res) => {
  const { id } = req.params;
  const { author, polishTitle, originalTitle, year, genres, note, favourite, description } = req.body;

  try {
    // Verify ownership
    const existing = await pool.query(
      'SELECT user_id FROM novels WHERE id = $1',
      [id]
    );
    if (existing.rows.length === 0) {
      return res.status(404).json({ error: 'novel_not_found' });
    }
    if (existing.rows[0].user_id !== req.user.id) {
      return res.status(403).json({ error: 'not_owner' });
    }

    // Validate note length (REQ-041)
    if (note !== undefined && note !== null && note.length > 2000) {
      return res.status(400).json({
        error: 'note_too_long',
        message: 'The note must be 2000 characters or fewer.'
      });
    }

    // Update novel
    const updated = await pool.query(
      `UPDATE novels 
       SET author = COALESCE($1, author),
           polish_title = COALESCE($2, polish_title),
           original_title = COALESCE($3, original_title),
           year = COALESCE($4, year),
           note = $5,
           favourite = COALESCE($6, favourite),
           description = COALESCE($7, description),
           updated_at = NOW()
       WHERE id = $8
       RETURNING *`,
      [author, polishTitle, originalTitle, year, note, favourite, description, id]
    );

    res.json(updated.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'server_error' });
  }
});
```

**Example output — `app/client/src/components/EditNovelForm.jsx` (excerpt):**

```jsx
export default function EditNovelForm({ novel, onSave, onCancel }) {
  const [formData, setFormData] = useState({
    author: novel.author || '',
    polishTitle: novel.polishTitle || '',
    originalTitle: novel.originalTitle || '',
    year: novel.year || '',
    genres: novel.genres || [],
    note: novel.note || '',  // ← NEW
    favourite: novel.favourite || false,
    description: novel.description || ''
  });

  const handleChange = (e) => {
    const { name, value, type, checked } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value
    }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    // Validate note length (client-side, REQ-041)
    if (formData.note.length > 2000) {
      setError('The note must be 2000 characters or fewer.');
      return;
    }

    try {
      const response = await fetch(`/api/novels/${novel.id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData)
      });
      
      if (response.ok) {
        const updated = await response.json();
        onSave(updated);
      } else {
        const err = await response.json();
        setError(err.message || 'Failed to update novel');
      }
    } catch (err) {
      setError('Network error');
    }
  };

  return (
    <form onSubmit={handleSubmit} data-testid="edit-novel-form">
      {/* ... other fields ... */}
      
      <label htmlFor="note">Private Note (optional)</label>
      <textarea
        id="note"
        name="note"
        data-testid="novel-note-input"
        maxLength={2000}
        rows={4}
        placeholder="Your private thoughts, reminders, or reading notes..."
        value={formData.note}
        onChange={handleChange}
      />
      <p className="char-count">
        {formData.note.length} / 2000 characters
      </p>

      {error && <p data-testid="error-message" className="error">{error}</p>}

      <button type="submit" data-testid="save-button">Save</button>
      <button type="button" onClick={onCancel}>Cancel</button>
    </form>
  );
}
```

---

### Stages 6 & 7 (not yet created)

- **Stage 6: Review** — would verify implementation matches spec and run full test suite
- **Stage 7: Document** — would generate user/operator/dev docs from the feature

---

## Key Rules of the Flow

1. **Specs are frozen after gather** — only the analyst (via `--revise`) may change a `.feature` file
2. **Each stage reads the previous stage's outputs** — the chain is: `.feature` → `.review.md` → `.design.md` → tests → code
3. **No agent edits another agent's domain:**
   - Analyst: owns `requirements.md` + `.feature`
   - Critic: only reads, writes `.review.md`
   - Architect: only reads specs, writes `.design.md` + `data-model.md`
   - Test-author: only writes `app/tests/`, never touches `app/server/` or `app/client/`
   - Implementer: only writes `app/`, never touches `spec/`
4. **You control the pace** — run one stage at a time, review the output, then run the next
5. **Continuity** — `STATUS.md` tracks which features are at which stage so you (or another session) can resume

---

## Root (process / spec-driven development)

| File | What it is | What it does | Important? |
|---|---|---|---|
| `.dockerignore` | (moved to `app/`) | — | Moved with the app |
| `.env.example` | Environment variables template | Sample settings (DATABASE_URL, PORT, SESSION_SECRET). Copy to `.env` locally. | Yes — duplicated in `app/server/.env.example` |
| `.gitignore` | Git ignore list | Tells git which files not to track (secrets, node_modules, build output, Kilo state) | Yes |
| `AGENTS.md` | AI agent briefing | Always-loaded project overview: stack, layout, agent roster, resolved decisions. Must stay at root. | Yes |
| `package.json` | Workspace root manifest | Declares npm workspaces (`app/server`, `app/client`, `app/tests`) and top-level commands (dev:server, test:api, migrate) | Yes |
| `README.md` | Project journal | What the project is, stack, layout, dated progress log | Yes |
| `REPO_GUIDE.md` | This file | File-by-file guide | Reference |
| `STATUS.md` | Current state snapshot | Stage table, exact next action, pending decisions, how to run. Read first. | Yes |

## .kilo/ (agent pipeline — pinned at root)

| File | What it is | What it does | Important? |
|---|---|---|---|
| `kilo.json` | Permissions config | What AI may do without asking (read/edit allowed, rm denied, mv asks) | Yes |
| **agent/** | | | |
| `01-spec-analyst.md` | Requirements → Gherkin agent | Turns descriptions into numbered requirements + scenarios. Only agent allowed to edit specs. | Yes |
| `02-spec-critic.md` | Spec review agent | Critiques specs, writes `.review.md` verdict. Never edits specs. | Yes |
| `03-spec-architect.md` | Design agent | Turns approved features into technical designs. Never edits specs or code. | Yes |
| `04-spec-test-author.md` | Test authoring agent | Writes Playwright + Postman tests before the feature exists (red phase) | Yes |
| `05-spec-implementer.md` | Implementation agent | Writes application code under `app/` until tests pass (green phase) | Yes |
| **command/** | | | |
| `spec-gather.md` | Slash command | Runs 01-spec-analyst | Yes |
| `spec-critique.md` | Slash command | Runs 02-spec-critic | Yes |
| `spec-design.md` | Slash command | Runs 03-spec-architect | Yes |
| `spec-test.md` | Slash command | Runs 04-spec-test-author | Yes |
| `spec-implement.md` | Slash command | Runs 05-spec-implementer | Yes |
| **rules/** | | | |
| `core.md` | Always-on rules | Session-start checks, continuity duties, spec workflow, live rules | Yes |
| **suspended-agents/** | | | |
| `spec-orchestrator.md` | Automatic pipeline driver (switched off) | Would run the pipeline automatically. Kept as future option, not loaded. | Reference |

## spec/ (the specifications)

### spec/domains/

| File | What it is | What it does | Important? |
|---|---|---|---|
| `auth/requirements.md` | Auth business rules | 12 numbered requirements (REQ-001 to REQ-012) for registration, login, logout | Yes — source of truth |
| `auth/data-model.md` | Auth database model | Describes `users` and `sessions` tables | Yes |
| `novels/requirements.md` | Novels business rules | 39 numbered requirements (REQ-001 to REQ-039) | Yes — source of truth |
| `novels/data-model.md` | Novels database model | Describes `novels` and `novel_genres` tables | Yes |
| `novels/ui/novel-form.ui.md` | Form screen layout | Visual notes for create/edit form | Yes — UI reference |
| `novels/ui/novel-list.ui.md` | List screen layout | Visual notes for the list | Yes — UI reference |

### spec/features/

Each feature has 3 files: `.feature` (scenarios), `.review.md` (critic verdict), `.design.md` (technical design).

| File | What it is | Scenarios | Important? |
|---|---|---|---|
| `auth/register.feature` | Registration scenarios | 9 | Yes — frozen spec |
| `auth/register.review.md` | Registration review verdict | — | Yes — gates design |
| `auth/register.design.md` | Registration technical design | — | Yes |
| `auth/login-logout.feature` | Login/logout scenarios | 6 | Yes — frozen spec |
| `auth/login-logout.review.md` | Login/logout review verdict | — | Yes — gates design |
| `auth/login-logout.design.md` | Login/logout technical design | — | Yes |
| `novels/create-novel.feature` | Create novel scenarios | 21 | Yes — frozen spec |
| `novels/create-novel.review.md` | Create novel review verdict | — | Yes — gates design |
| `novels/create-novel.design.md` | Create novel technical design | — | Yes |
| `novels/view-novels.feature` | View/filter novels scenarios | 16 | Yes — frozen spec |
| `novels/view-novels.review.md` | View novels review verdict | — | Yes — gates design |
| `novels/view-novels.design.md` | View novels technical design | — | Yes |
| `novels/edit-novel.feature` | Edit novel scenarios | 11 | Yes — frozen spec |
| `novels/edit-novel.review.md` | Edit novel review verdict | — | Yes — gates design |
| `novels/edit-novel.design.md` | Edit novel technical design | — | Yes |
| `novels/delete-novel.feature` | Delete novel scenarios | 4 | Yes — frozen spec |
| `novels/delete-novel.review.md` | Delete novel review verdict | — | Yes — gates design |
| `novels/delete-novel.design.md` | Delete novel technical design | — | Yes |

**Total: 67 scenarios across 6 features (auth 15, novels 52)**

## app/ (the runnable product)

### app/server/ — backend (Express.js + PostgreSQL)

| File | What it is | What it does | Important? |
|---|---|---|---|
| `package.json` | Backend manifest | Dependencies (express, pg, cookie-parser, bcryptjs) and scripts | Yes |
| `.env.example` | Backend settings template | Same as root `.env.example` | Duplicate — remove one |
| `src/index.js` | Server entry point | Starts web server. Only endpoint today: GET /health | Yes |
| `src/db.js` | Database connection | Shared PostgreSQL connection pool | Yes |
| `src/migrate.js` | Migration runner | Applies SQL files in migrations/ in order | Yes |
| `migrations/0001_init.sql` | First migration | Empty placeholder; real tables come later | Placeholder |

### app/client/ — frontend (React + Vite)

| File | What it is | What it does | Important? |
|---|---|---|---|
| `package.json` | Frontend manifest | React + Vite dependencies and scripts | Yes |
| `index.html` | The web page | Browser starting point; holds `<div id="root">` | Yes |
| `vite.config.js` | Build tool config | Dev port 5173; proxies /api and /health to backend (:3000) | Yes |
| `src/main.jsx` | React bootstrap | Mounts the React app | Yes |
| `src/App.jsx` | Root component | Shows title + API health; will host the screens | Yes |

### app/tests/ — automated tests

| File | What it is | What it does | Important? |
|---|---|---|---|
| `package.json` | Test manifest | Playwright + Newman dependencies and scripts | Yes |
| `playwright.config.js` | Playwright settings | Browser test config (port 5173) | Yes |
| `api/README.md` | API test instructions | How to run API tests | Could merge into root README |
| `api/noveltracker.postman_collection.json` | Baseline API test | Minimal collection: checks GET /health | Yes — smoke test |
| `api/auth.postman_collection.json` | Auth API tests | 22 requests for auth, traced to REQ-nnn | Yes |
| `api/auth.postman_environment.json` | API test settings | Variables like baseUrl | Yes |
| `e2e/.gitkeep` | Empty folder placeholder | Keeps e2e/ in git | Standard practice |
| `e2e/auth/helpers.js` | Shared test utilities | Register/login via API, unique emails, wording constants | Yes |
| `e2e/auth/register.spec.js` | Registration UI tests | 10 browser scenarios | Yes |
| `e2e/auth/login-logout.spec.js` | Login/logout UI tests | 6 browser scenarios | Yes |

### app/docker/ and app/jenkins/ — shipping

| File | What it is | What it does | Important? |
|---|---|---|---|
| `docker/Dockerfile.server` | Backend container recipe | Packages the API into an image | Yes |
| `docker/Dockerfile.client` | Frontend container recipe | Packages the UI into an image | Yes |
| `docker/docker-compose.yml` | Local launcher | Starts PostgreSQL + backend + frontend locally | Yes |
| `jenkins/Jenkinsfile` | Automated build pipeline | On push: install, test, build images | Yes |
| `.dockerignore` | Container build ignore list | Excludes secrets/node_modules from images (scoped to `app/`) | Yes |

## Summary

- **Essential:** almost everything
- **Duplicates to merge:** 2 (`.env.example` root vs `app/server/`, `app/tests/api/README.md`)
- **Placeholders:** 2 (`e2e/.gitkeep`, empty migration)
- **Pinned at root (cannot move):** `.kilo/`, `AGENTS.md`
