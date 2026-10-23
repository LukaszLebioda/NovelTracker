---
name: add-db-migration
description: Use when generating a new Drizzle migration in packages/db after a schema change, or when a git rebase produces conflicts under packages/db/migrations/ (the SQL files or the meta/_journal.json and meta/*_snapshot.json index). Covers the generate workflow, matching existing SQL conventions, and safely resolving migration conflicts during a rebase.
---

# Add a DB Migration

Before implementation, load `backend-conventions` for general Drizzle rules (naming, snake_case columns, never editing a committed migration). This skill covers the generate workflow in depth and, separately, how to resolve migration conflicts during a rebase.

## 1. Prerequisite

The schema change must already exist in `packages/db/src/schema/<feature>.ts` and be exported from `packages/db/src/schema/index.ts`. This skill does not cover writing the schema itself.

## 2. Generate

From the repo root:

```bash
yarn db:generate --name <descriptive_name>
```

This produces three artifacts that must always be committed together:

- `packages/db/migrations/NNNN_<descriptive_name>.sql` — the actual SQL to run
- `packages/db/migrations/meta/NNNN_snapshot.json` — the **full** DB-state snapshot at this point (not a diff; the next `db:generate` diffs against the latest snapshot in the chain)
- a new entry appended to `packages/db/migrations/meta/_journal.json` — the ordered index tying migration tags to snapshots

Never write these files by hand, and never renumber or hand-edit a migration that's already committed to `main`.

## 3. Match existing SQL conventions

Check 2-3 recent files in `packages/db/migrations/*.sql` for style before trusting the generated output blindly. Recurring patterns in this repo:

- Quoted snake_case identifiers, `CREATE TABLE IF NOT EXISTS`, `ADD COLUMN IF NOT EXISTS`
- Statements separated by `--> statement-breakpoint`
- FK constraints added via a separate `ALTER TABLE ... ADD CONSTRAINT`, wrapped in a `DO $$ ... IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = '...') ... END $$;` block when the constraint needs to be idempotent
- Seed data uses `INSERT ... ON CONFLICT (...) DO NOTHING`

## 4. Review and apply

Read the generated SQL, show it to the user, and get confirmation before running it:

```bash
yarn db:migrate
```

## Resolving migration conflicts during a rebase

`meta/_journal.json` is an append-only ordered index, and `meta/*_snapshot.json` is a cumulative full DB-state snapshot — neither is a line-diffable artifact. Hand-merging conflict markers in them is unsafe: it's easy to produce a journal entry whose `idx`/`tag` no longer matches its snapshot, or a snapshot that silently drops part of the state, which then makes the *next* `db:generate` compute a wrong diff.

**Rule: never hand-resolve conflicts inside `packages/db/migrations/`. Only resolve conflicts in `packages/db/src/schema/*.ts`, then regenerate.**

When `git rebase` stops on a commit touching `packages/db/migrations/`:

1. Resolve `packages/db/src/schema/*.ts` conflicts normally — merge both sides' intended column/table changes. This file is the real source of truth; everything else is derived from it.
2. For every conflicted file under `packages/db/migrations/`, take the upstream side. During a rebase, "ours" is the branch being rebased onto (the target/upstream state already replayed), "theirs" is the commit coming from your branch:
   ```bash
   git checkout --ours -- packages/db/migrations/meta/_journal.json
   git checkout --ours -- packages/db/migrations/meta/*_snapshot.json
   ```
3. Remove your own new migration SQL file entirely (it will be regenerated from the merged schema):
   ```bash
   git rm -f packages/db/migrations/<your-NNNN>_<name>.sql
   ```
4. Stage and continue:
   ```bash
   git add -A
   git rebase --continue
   ```
5. Once the schema conflict is resolved (immediately, or once the whole rebase finishes if multiple commits touch migrations), regenerate from the now-merged schema:
   ```bash
   yarn db:generate --name <same-descriptive-name-as-before>
   ```
   Drizzle diffs the schema against the latest snapshot in the now-correct upstream chain and appends a fresh migration at the next free index — no manual index arithmetic.
6. Diff the regenerated SQL against what the original migration intended (columns, constraints, indexes, seed data) to confirm nothing was lost, then fold it into the appropriate commit (`git commit --amend` / fixup) per the user's rebase preference, or add it as a new commit if history shouldn't be rewritten further.

**Caution:** this discard-and-regenerate approach is only safe for a migration that hasn't been merged to `main` yet. If the conflict is against a migration already committed to `main` (and possibly applied to a shared database), don't renumber or regenerate over it — add a new migration on top instead.

Note this applies to `git rebase` specifically; for `git merge`, "ours"/"theirs" are reversed (ours = your current branch, theirs = the branch being merged in) — swap the `--ours`/`--theirs` flags above accordingly.
