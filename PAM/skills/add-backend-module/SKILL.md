---
name: add-backend-module
description: Use when creating a new NestJS domain_cluster module in pam-api. Scaffolds the module and registers it in AppModule. Cascade from add-backend-feature when the module folder does not exist yet.
---

# Add a Backend Module

Prereq: `task-preflight`. Before implementation, load `backend-conventions` for the repository's NestJS, package-boundary, Drizzle, Swagger, and testing requirements. This skill only covers module scaffolding.

Replace `<feature>` with singular cluster name (`player`, `wallet`).

If `apps/pam-api/src/modules/<feature>/` exists → stop; use `add-backend-feature` only.

## Scaffold

From `apps/pam-api/`:

```bash
nest g module modules/<feature>
```

Creates `<feature>.module.ts` and registers in `AppModule`.

## Next

`add-backend-feature` for contracts, DB, service, controller, then `test-backend`.
