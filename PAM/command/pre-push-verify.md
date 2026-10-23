---
description: Pre-push verification - runs the full local CI pipeline and loops fixing any failures until green
---

Execute the pre-push verification loop exactly as specified below. Do not skip steps, do not reorder them, and do not abandon the loop early.

## The verify command

Run this exact command (single shell invocation, chained with `&&`) via the Bash tool, from the repository root. Changed Gherkin files are detected the same way as `.github/workflows/spec-review.yml` (`git diff` against the upstream tracking branch, or `origin/HEAD` / `main` / `master` as fallback). If none changed, the `spec:lint` loop is a no-op.

```
yarn install --immutable \
  && yarn lint \
  && { \
       UPSTREAM=$(git rev-parse --abbrev-ref --symbolic-full-name @{upstream} 2>/dev/null || true); \
       if [ -n "$UPSTREAM" ]; then BASE="$UPSTREAM"; \
       elif git rev-parse --verify origin/HEAD >/dev/null 2>&1; then BASE="origin/HEAD"; \
       elif git rev-parse --verify origin/main >/dev/null 2>&1; then BASE="origin/main"; \
       else BASE="origin/master"; fi; \
       CHANGED=$(git diff --name-only "$BASE"...HEAD | grep '^spec/features/.*/.*\.feature$' | sed 's|^spec/features/||; s|\.feature$||' | sort -u || true); \
       if [ -n "$CHANGED" ]; then \
         echo "$CHANGED" | while IFS= read -r f; do yarn spec:lint -- "$f" --strict; done; \
       fi; \
     } \
  && yarn check-types \
  && yarn test \
  && yarn test:cov \
  && yarn build \
  && cp apps/pam-api/.env.example apps/pam-api/.env \
  && yarn turbo run test:e2e lint check-types build --affected
```

Use a generous timeout - the combined pipeline can take several minutes, so set the Bash timeout to at least 600000 (10 minutes). Run it as a single Bash call, not as separate calls.

## The loop

1. Run the verify command once and capture the full output.
2. If the exit code is 0 (success): report the green result concisely and stop. The workflow is complete.
3. If the exit code is non-zero (failure): proceed to the diagnosis phase below.
4. After applying a fix, go back to step 1 (re-run the verify command from the top, including `yarn install --immutable`). Repeat until the command exits 0.

## Diagnosis phase (only on failure)

When the command fails, investigate the root cause before touching any code:

1. Identify the first failing step in the chain. The command stops at the first `&&` that fails, so the failure is at that boundary.
2. Read the relevant error output from that step. Use grep/read on the captured output to pinpoint the exact error message, file path, and line.
3. Determine the root cause - do not paper over the symptom. If it is a lint error, fix the linted code. If it is a type error, fix the typing. If it is a test failure, fix the implementation or the test depending on which is wrong. If it is a build failure, fix the build configuration or source. If it is an e2e failure, fix the app or the test accordingly.
4. Form a concise hypothesis of the cause and the fix.

## Fix phase

1. Apply the minimal, correct fix that addresses the root cause. Follow the repo's existing conventions (see AGENTS.md and the .kilo/rules/*.md files). Do not introduce unrelated changes.
2. After editing, briefly state what you changed and why.
3. Do not run isolated checks to validate the fix - the only accepted validation in this workflow is re-running the full verify command in step 1 of the loop. This guarantees the fix does not regress an earlier step.
4. Return to the loop.

## Stopping the loop

- Stop only when the verify command exits 0. Report the final green result.
- If you hit a failure you genuinely cannot resolve (for example an external dependency is down, or the root cause is outside the repo), stop, summarize the blocker clearly, and ask the user how to proceed. Do not keep retrying blindly.

## Rules

- Always re-run the entire verify command on each loop iteration - partial re-runs are not permitted.
- Do not commit, push, amend, or create PRs unless the user explicitly asks.
- Do not edit the verify command itself.
- Keep the user informed between iterations: report the failing step, the root cause found, the fix applied, and that you are re-running the full pipeline.
