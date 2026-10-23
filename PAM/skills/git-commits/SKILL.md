---
name: git-commits
description: Use when creating, amending, or preparing a git commit or release in this repository. Applies the branch-ticket commit subject format and commit restrictions.
---

# Git Commit Conventions

Format:

```text
<ticket> <verb> <what>
```

- Extract the Jira ticket from the branch name, such as `ULT40-4` before the first space or after the last `/`.
- Use a lowercase imperative verb (`add`, `fix`, `remove`, `update`, `refactor`, `move`).
- Keep the concise lowercase subject under 100 characters with no final period.
- Add a body only when it explains why; separate it with a blank line.
- Never include `Co-Authored-By` or AI attribution lines.
