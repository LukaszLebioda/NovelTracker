# Complete PAM Agent Guide
## From Beginner to Expert: Creating New Services with Kilo AI Agents

---

## 📖 How to Use This Guide

**If you're NEW to agents**: Start with **Part 1** - it explains everything using simple analogies.

**If you're EXPERIENCED**: Jump to **Part 2** for technical details, API references, and advanced patterns.

**If you need QUICK HELP**: Check the **Quick Reference** at the end.

---

# PART 1: BEGINNER'S GUIDE
## Understanding Agents Without Technical Jargon

---

## Think of It Like a Construction Company

Imagine you want to build a house. You don't do everything yourself - you hire specialists:

- **Architect** - designs the house
- **Inspector** - checks if the design is good
- **Builders** - actually build it
- **Tester** - makes sure everything works
- **Reviewer** - does final inspection

**Kilo Agents work the same way** - they're AI specialists that each do one job really well.

---

## What is an Agent? (Simple Explanation)

An **agent** is like a **virtual employee** who:
- Has a specific job (like "write tests" or "review code")
- Knows what files they're allowed to touch
- Follows a checklist (workflow)
- Can ask other agents for help

### Real-World Analogy

Think of an agent like a **restaurant worker**:

| Restaurant | Kilo Agent |
|---|---|
| **Chef** - cooks food | **Implementer** - writes code |
| **Waiter** - takes orders | **Analyst** - gathers what you want |
| **Manager** - coordinates everyone | **Orchestrator** - runs the whole workflow |
| **Health Inspector** - checks quality | **Critic** - reviews requirements |

Each person has:
- A **role** (what they do)
- **Permissions** (what areas they can access - kitchen, dining room, etc.)
- A **process** (steps they follow)

---

## How Do Agents Work?

### The Magic Command: `/spec-flow`

When you type `/spec-flow I want to add a deposit approval system`, here's what happens:

```
YOU type a command
    ↓
ORCHESTRATOR (the manager) reads it
    ↓
ORCHESTRATOR assigns work to specialists
    ↓
Each SPECIALIST does their part
    ↓
ORCHESTRATOR checks if it's done
    ↓
YOU get the finished feature!
```

### The Assembly Line

Think of it like a car factory assembly line:

**Station 1: ANALYST** (Requirements Gatherer)
- **Input**: Your description "I want deposit approval"
- **Job**: Writes down exactly what the feature should do
- **Output**: A document with scenarios (like a blueprint)

**Station 2: CRITIC** (Quality Inspector)
- **Input**: The blueprint from Station 1
- **Job**: Checks if anything is missing or unclear
- **Output**: "Approved" or "Fix these issues"

**Station 3: ARCHITECT** (Code Designer)
- **Input**: Approved blueprint
- **Job**: Creates empty code templates (like cutting wood to size)
- **Output**: Empty functions ready to be filled

**Station 4: TEST AUTHOR** (Quality Checker)
- **Input**: Empty code templates
- **Job**: Writes tests that check if code will work
- **Output**: Tests (that fail because code isn't written yet)

**Station 5: IMPLEMENTER** (Builder)
- **Input**: Empty templates + failing tests
- **Job**: Fills in the code to make tests pass
- **Output**: Working feature!

**Station 6: REVIEWER** (Final Inspector)
- **Input**: Working code
- **Job**: Checks for bugs, bad practices
- **Output**: "Approved for release"

**Station 7: DOCUMENTER** (Technical Writer)
- **Input**: Finished code
- **Job**: Writes instructions for different audiences
- **Output**: 3 manuals (for developers, operators, end users)

---

## How Do I Know What Commands Are Available?

Great question! There are **3 ways** to discover available commands:

### Method 1: Look in the `command/` Folder (Easiest)

All available commands are just files in the `command/` folder:

```bash
ls command/
```

You'll see:
```
pre-push-verify.md
spec-critique.md
spec-design.md
spec-document.md
spec-flow.md          ← The main one!
spec-gather.md
spec-implement.md
spec-prompt.md
spec-review.md
spec-test.md
```

**Each filename = a command you can type!**

- File: `spec-flow.md` → Command: `/spec-flow`
- File: `pre-push-verify.md` → Command: `/pre-push-verify`

### Method 2: Open a Command File to See What It Does

Want to know what `/spec-flow` does? Open the file:

```bash
cat command/spec-flow.md
```

You'll see:
```markdown
---
description: Flow tracking — owns /spec-flow, tracks feature sets through stages
agent: spec-orchestrator
arguments: <feature description>
---

Run the spec-orchestrator agent with the following arguments:
$ARGUMENTS
...
```

The `description` tells you what it does!  
The `arguments` tells you what to type after the command!

### Method 3: Use Kilo's Built-in Help (If Available)

In the Kilo CLI/TUI, you might be able to type:
```
/help
```
or
```
Ctrl+P
```

This may show you all available commands (depending on your Kilo version).

---

## Which Command Should I Use?

Here's a simple decision tree:

```
Do you want to build a COMPLETE feature (from idea to docs)?
  → Use /spec-flow <description>
  
Do you want to run just ONE stage?
  ├─ Just write scenarios → /spec-gather <domain>/<feature>
  ├─ Just review scenarios → /spec-critique <domain>/<feature>
  ├─ Just design code → /spec-design <domain>/<feature>
  ├─ Just write tests → /spec-test <domain>/<feature>
  ├─ Just implement → /spec-implement <domain>/<feature>
  ├─ Just review code → /spec-review <domain>/<feature>
  └─ Just write docs → /spec-document <domain>/<feature>

Do you want to verify before pushing to git?
  → Use /pre-push-verify
  
Do you want help writing a clear feature description?
  → Use /spec-prompt <rough idea>
```

**90% of the time, you'll use `/spec-flow`** - it runs everything automatically!

---

## Real Example: How You'd Discover This

Let's say you're new to the project and someone tells you "use agents to build a feature."

**Step 1**: "What commands exist?"
```bash
ls command/
```
Output: `spec-flow.md` ← Interesting!

**Step 2**: "What does spec-flow do?"
```bash
cat command/spec-flow.md
```
Output: "Flow tracking — runs all stages" ← Perfect for a complete feature!

**Step 3**: "How do I use it?"
The file says: `arguments: <feature description>`

**Step 4**: Try it!
```
/spec-flow Add a login page with username and password fields
```

**Done!** You've discovered and used your first command.

---

## Visual: File → Command Mapping

Here's how the files in `command/` become commands you type:

```
command/
├── spec-flow.md              → You type: /spec-flow <description>
├── spec-gather.md            → You type: /spec-gather <domain>/<feature>
├── spec-critique.md          → You type: /spec-critique <domain>/<feature>
├── spec-design.md            → You type: /spec-design <domain>/<feature>
├── spec-test.md              → You type: /spec-test <domain>/<feature>
├── spec-implement.md         → You type: /spec-implement <domain>/<feature>
├── spec-review.md            → You type: /spec-review <domain>/<feature>
├── spec-document.md          → You type: /spec-document <domain>/<feature>
├── spec-prompt.md            → You type: /spec-prompt <rough idea>
└── pre-push-verify.md        → You type: /pre-push-verify
```

**The pattern**: 
- Remove `.md`
- Add `/` at the start
- Add required arguments (shown in the file)

---

## Where Do Agents Live?

Agents are just **text files** on your computer. They're like instruction manuals.

### Your Project Folder Structure

```
PAM/                          (Your main project folder)
│
├── agent/                    ← AGENTS LIVE HERE
│   ├── spec-analyst.md           (Requirements gatherer)
│   ├── spec-architect.md         (Code designer)
│   ├── spec-implementer.md       (Builder)
│   └── ... (7 more agents)
│
├── command/                  ← COMMANDS LIVE HERE
│   ├── spec-flow.md              (The main command you'll use)
│   └── ... (other shortcuts)
│
├── rules/                    ← RULES LIVE HERE
│   ├── core.md                   (Rules everyone follows)
│   ├── backend.md                (Rules for server code)
│   └── frontend.md               (Rules for website code)
│
├── skills/                   ← SKILLS LIVE HERE
│   ├── add-backend-feature/      (How to add server features)
│   ├── test-backend/             (How to test server code)
│   └── ... (13 more skills)
│
└── AGENTS.md                 ← THE MASTER GUIDE
                                  (Always loaded, tells agents about your project)
```

---

## Let's Look Inside an Agent File

### Example: `agent/spec-analyst.md`

This is what an agent file looks like (simplified):

```markdown
---
description: I gather requirements and write scenarios
model: kilo/z-ai/glm-5.3
variant: high
steps: 50
permission:
  edit:
    "spec/features/**/*.feature": allow
    "apps/**": deny
---

You are the spec-analyst agent.

## Your Job
1. Read what the user wants
2. Ask questions if unclear
3. Write scenarios in a file
4. Check for errors
5. Tell the orchestrator you're done
```

### Breaking It Down

**Top Section** (between `---` lines):
- `description`: One sentence about what this agent does
- `model`: Which AI brain to use (like choosing between GPT-4 or Claude)
- `variant: high`: How much thinking power (low/medium/high)
- `steps: 50`: Maximum number of actions allowed
- `permission`: What this agent is allowed to edit

**Bottom Section** (after `---`):
- Detailed instructions for what the agent should do
- Like a recipe or instruction manual

---

## The 4 Types of Files

### 1. AGENTS (agent/*.md)

**What**: Virtual employees who do the work  
**When created**: Rarely - only when you need a new type of worker  
**Example**: `spec-analyst.md`, `spec-implementer.md`

Think of these as **job descriptions**.

### 2. COMMANDS (command/*.md)

**What**: Shortcuts you can type to start work  
**When created**: When you want a quick way to run an agent  
**Example**: `/spec-flow`, `/spec-implement`

Think of these as **buttons** that start a process.

### 3. RULES (rules/*.md)

**What**: Laws that everyone must follow  
**When created**: Rarely - only for project-wide constraints  
**Example**: "Never commit passwords", "Always use yarn not npm"

Think of these as **company policies**.

### 4. SKILLS (skills/*/SKILL.md)

**What**: Instruction manuals agents can look up when needed  
**When created**: When you have a repeated pattern  
**Example**: "How to add a database table", "How to test React components"

Think of these as **training manuals** or **cookbooks**.

---

## Your First Feature: Password Reset (Simple Walkthrough)

### What You Want

"I want players to be able to reset their password if they forget it. They should get an email with a link that expires after 1 hour."

### Step 1: Type the Command

Open your terminal and type:

```
/spec-flow I want a password reset feature. Players enter their email, get a link by email, click the link to set a new password. The link expires after 1 hour. Players can only reset once per hour to prevent spam.
```

Press Enter.

### Step 2: Answer Questions

The **Analyst** agent might ask:

> **Agent**: "Should the link work if they're already logged in?"

You answer: "Yes, they can reset even if logged in."

> **Agent**: "What happens if they click an expired link?"

You answer: "Show an error message: 'This link has expired. Please request a new one.'"

### Step 3: Review the Scenarios

The **Analyst** writes scenarios. The **Orchestrator** pauses and asks you:

> "Please review `spec/features/auth/password-reset.feature`. Does it match your expectations?"

You read it and reply: "Yes, looks good!"

### Step 4: Wait (Agents Work Automatically)

Now you just **wait**. The agents work through the assembly line:

- **CRITIC**: ✓ Checks scenarios (30 seconds)  
- **ARCHITECT**: ✓ Creates code templates (2 minutes)  
- **TEST AUTHOR**: ✓ Writes tests (3 minutes)  
- **IMPLEMENTER**: ✓ Fills code, tests pass (5 minutes)  
- **REVIEWER**: ✓ Checks quality (1 minute)  
- **DOCUMENTER**: ✓ Writes docs (2 minutes)

**Total time**: ~15 minutes (without you doing anything!)

### Step 5: Done!

You have:
- ✓ Working password reset code
- ✓ All tests passing
- ✓ Documentation created
- ✓ Ready to deploy

---

## Common Questions (Beginner)

### Q: Do I need to understand code to use agents?

**A**: No! You just describe **what** you want, not **how** to build it.

Like ordering at a restaurant - you say "I want a burger", not "Here's how to cook a burger".

### Q: What if an agent makes a mistake?

**A**: Agents check each other! If the **Critic** finds a problem, it sends work back. If tests fail, the **Implementer** has to fix them.

### Q: How do I know what's happening?

**A**: Check the log file: `spec/features/<your-feature>.log.md`

It shows each agent's progress:
```
[STATUS] auth/password-reset gathered done
[STATUS] auth/password-reset critiqued done
[STATUS] auth/password-reset designed done
```

### Q: Can I stop and restart?

**A**: Yes! Press `Ctrl+C` to stop. Restart with the same command - agents remember where they stopped.

### Q: Do I need to create agents often?

**A**: No! Your project already has 9 agents that handle 99% of work. You might **never** need to create a new agent.

### Q: How did you know to type `/spec-flow`? Where do I find available commands?

**A**: All commands are files in the `command/` folder!

**Quick way**:
```bash
ls command/
```

Each file is a command:
- `spec-flow.md` → type `/spec-flow`
- `spec-implement.md` → type `/spec-implement`

**To see what a command does**:
```bash
cat command/spec-flow.md
```

The `description:` line at the top tells you everything!

**Rule of thumb**: Use `/spec-flow` for complete features, and look in `command/` if you need something specific.

### Q: What if I forget the command syntax?

**A**: Open the command file! Example:

```bash
cat command/spec-flow.md
```

It shows:
```
arguments: <feature description>
```

So you know to type: `/spec-flow Add my feature description here`

---

# PART 2: TECHNICAL REFERENCE
## Detailed Architecture, APIs, and Advanced Patterns

---

## Overview

The PAM (Player Account Management) project uses a **spec-driven development (SDD)** approach powered by specialized AI agents. The system orchestrates work through multiple stages, from gathering requirements to implementation and documentation.

### Key Principles

- **Token budget**: Hard limit of **170k tokens** per session
- **Spec-driven**: Everything flows from executable Gherkin specs
- **Multi-agent**: Each stage has a specialized agent
- **Atomic work**: One responsibility per change
- **Tests with code**: Every behavior change ships with tests

> **Where is the 170k limit set?** It is **not set in code or config** — it is a *policy* written into instruction files that agents read:
> 1. `AGENTS.md` (line ~54) — the always-loaded baseline states the hard session budget
> 2. `rules/core.md` (line 5) — the always-on rule states the hard cap and coping strategies
> 3. `skills/task-preflight/SKILL.md` (section 6) — reinforces it with concrete budget-management tactics
>
> Agents follow it because they are *instructed* to, not because a program enforces it. Think of it like a company rule written in the employee handbook — the workers (agents) obey it because their job description says so.

---

## Project Architecture

### Monorepo Layout

```
PAM/
├── apps/
│   ├── pam-api/          # All backend (NestJS 11)
│   ├── pam-ui/           # All frontend (React 19, Vite 8)
│   ├── pam-worker/       # Scheduled jobs (@Cron)
│   └── pam-event-bridge/ # RabbitMQ→Kafka relay
├── packages/
│   ├── contracts/        # Shared Zod schemas/types
│   ├── db/               # Drizzle ORM schemas/migrations
│   ├── backend-shared/   # Shared backend primitives
│   ├── eslint-config/    # Shared ESLint config
│   └── typescript-config/# Shared TS config
├── spec/
│   ├── domains/          # Stakeholder requirements
│   │   └── <domain>/
│   │       ├── requirements.md  # EARS requirements
│   │       ├── ui/*.ui.md       # Wireframes (Markdown-UI DSL)
│   │       └── traceability.md  # Legacy→EARS mapping
│   ├── features/         # Executable Gherkin specs
│   │   └── <domain>/
│   │       ├── <feature>.feature        # Frozen scenarios
│   │       ├── <feature>.contracts.md   # Architecture design
│   │       ├── <feature>.review.md      # Critique report
│   │       ├── <feature>.impl-plan.md   # Implementation plan
│   │       └── <feature>.code-review.md # Review report
│   └── legacy/           # Read-only historical docs
├── agent/               # Agent definitions
├── command/             # Slash commands
├── rules/               # Always-on constraints
├── skills/              # On-demand patterns
└── AGENTS.md            # Always-loaded baseline
```

### Technology Stack

| Layer | Technology |
|---|---|
| Backend | NestJS 11, TypeScript |
| Auth | BetterAuth + Keycloak (OIDC) |
| Frontend | React 19, Vite 8 |
| Styling | Tailwind v4, shadcn/ui |
| Database | PostgreSQL, Drizzle ORM |
| Package manager | Yarn v4 Berry, nodeLinker: node-modules |
| Monorepo | Turborepo |
| Messaging | RabbitMQ, Kafka |

### Domain → App Mapping

PAM has **2 apps** post-consolidation:
- `pam-api` - All backend logic
- `pam-ui` - All frontend UI

**Key domains** (examples from AGENTS.md):

| Domain | Host App | Notes |
|---|---|---|
| auth-registration, account-kyc | `pam-api` | Player domain (`src/modules/player/`) |
| auth-password | `pam-api` | Password reset (`src/modules/player/password-reset/`) |
| player-authorization | `pam-api` | Session management, OIDC |
| wallet-ledger, txn-lifecycle | `pam-api` | Finance coupling, outbox pattern |
| rg-limits | `pam-api` | Responsible gaming (`src/modules/rg-limits/`) |
| rg-exclusions | `pam-api` | Self-exclusion (`src/modules/rg-exclusions/`) |
| admin-ui-routes | `pam-ui` | Admin UI surface |
| platform-cron-workers | `pam-worker` | Scheduled jobs |
| platform-event-bridge | `pam-event-bridge` | RabbitMQ→Kafka relay |

---

## Agent Specifications

### Agent Roster (9 Specialized Agents)

#### 1. spec-orchestrator

**Command**: `/spec-flow`  
**Model**: DeepSeek v4 Flash  
**Variant**: high  
**Steps**: 100

**Role**: Flow controller - drives features through all stages

**Responsibilities**:
- Reads `.log.md` files for progress tracking
- Invokes stage agents via `task` tool
- Manages state in `.state.md`
- Pauses after gather for user confirmation
- Auto-advances through stages until `documented` or blocked

**State Machine** (per sub-feature):
```
gathered → critiqued → designed → tested-red → implemented → reviewed → documented
    ^          | (blocked: spec-change-required)
    |__________|  /spec-gather --revise  →  gathered(revised) → critiqued ...
```

**Permissions**:
- Read: all
- Edit: `spec/features/*.state.md`, `spec/features/*.brief.md`
- Deny: `spec/features/**/*.feature` (frozen)

**Key behaviors**:
- First gather is `/spec-gather` or `/spec-gather --new` (user decides mode)
- Subsequent gathers are always `/spec-gather --revise` (driven by blockers)
- Post-gather confirmation gate (user must approve `.feature` before proceeding)
- Delegates via `task` tool, not by printing commands for user to run

---

#### 2. spec-analyst

**Command**: `/spec-gather [<prompt> | <domain>/<feature-slug> --revise | <domain>/<feature-slug> --new]`  
**Model**: GLM 5.3  
**Variant**: high  
**Steps**: 50

**Role**: Requirements → Gherkin conversion

**Modes**:
1. **Default**: Maps from `spec/domains/<domain>/requirements.md` (or legacy fallback)
2. **--new**: Brand-new functionality absent from domain requirements
3. **--revise**: Updates frozen `.feature` files (only allowed path)

**Workflow** (default mode):
1. Read originating `/spec-flow` prompt
2. Determine affected domain(s), read canonical requirements
3. Emit `# Analyst assumptions:` comment block with sources and scope-outs
4. Draft `spec/features/<domain>/<feature-slug>.feature`
5. Tag scenarios: `@req:<domain>#REQ-n`, `@req:<domain>#BR-n`, or `@req:new#<id>`
6. Run `yarn spec:lint -- <domain>/<feature-slug>` until exit 0
7. Print `[STATUS] <domain>/<feature-slug> gathered done`
8. Append status to `spec/features/<root-slug>.log.md`

**New-feature mode** (`--new`):
- Source: user prompt + Q&A (not legacy)
- Clarify ambiguities via `question` tool
- Tag scenarios: `@req:new#<short-id>`
- Print `[STATUS] ... gathered(new) done`

**Revise mode** (`--revise`):
- Read existing `.feature` + blocking reports with `## Spec change required` sections
- Apply only described changes
- Update `# Analyst assumptions:` comment
- Print `[STATUS] ... gathered(revised) done`

**Permissions**:
- Read: all
- Edit: `spec/features/**/*.feature` (allow), `spec/features/**` (allow)
- Ask: `spec/domains/**`
- **Only agent allowed to write `.feature` files**

---

#### 3. spec-critic

**Command**: `/spec-critique <domain>/<feature-slug>`  
**Model**: (varies by configuration)  
**Variant**: high

**Role**: Quality gate - reviews Gherkin for completeness

**Checks**:
- Scenario testability (clear Given/When/Then)
- Persistence contracts (DB implications)
- API contracts (HTTP boundaries)
- UI contracts (component/page boundaries)
- Coverage gaps (missing scenarios)
- Ambiguities (vague steps)

**Outputs**: `spec/features/<domain>/<feature-slug>.review.md`

**Review Structure**:
```markdown
# Feature Review: <feature-name>

## Summary
Approved for architecture | Needs revision | Blocked

## Approval
✓ Criterion met
✗ Criterion failed

## Warnings
- W1: Description
- W2: Description

## Coverage Gaps
Missing scenarios or edge cases

## Required Contracts
- API: endpoints
- DB: tables/columns
- Events: domain events
```

**Prints**: `[STATUS] <domain>/<feature-slug> critiqued done|blocked: <reason>`

**Warnings vs Blockers**:
- Warnings name missing contracts → Architect must resolve
- Blockers require spec changes → Triggers `--revise`

---

#### 4. spec-architect

**Command**: `/spec-design <domain>/<feature-slug>`  
**Model**: DeepSeek v4 Pro  
**Variant**: high  
**Steps**: 50

**Role**: Decides code placement, writes thin production contracts

**Precondition**: Read `.review.md`, verify "Approved for architecture"

**Workflow**:
1. Read approved `.feature` and AGENTS.md domain→app mapping
2. Classify scenarios: **single-app** vs **cross-app**
   - Cross-app: asserts persistence, external effects, network calls, or boundary-crossing data flow
3. List **every** host app that owns a boundary the scenario crosses
4. Decide: reuse module, extend module, or create new module
5. Create empty, DI-friendly contracts in **each** host app
6. Write `spec/features/<domain>/<feature-slug>.contracts.md`
7. Update AGENTS.md domain→app mapping if needed
8. Run `yarn spec:lint` and `yarn turbo run check-types` for every host app
9. Outline DB schema changes in `.contracts.md` under `## Database Schema Changes`
10. Print `[STATUS] <domain>/<feature-slug> designed done|blocked: <reason>`

**Contracts Manifest** (`.contracts.md`):
- **One row per (scenario, host app)** pair
- Columns: Scenario | Contract path | Method | Host app | Reuse/New | Boundary | Requirements

**Key Rule**: Cross-app scenarios produce **multiple rows** (one per boundary-owning app)

**Spec Change Escape Hatch**: If scenario/step requires Gherkin change, append `## Spec change required` section, print `blocked: spec-change-required`, and stop

**Permissions**:
- Read: all
- Edit: `apps/**`, `packages/**`, `AGENTS.md`, `spec/features/**/*.contracts.md`
- Deny: `spec/features/**/*.feature` (frozen)
- Ask: destructive infra/DB

---

#### 5. spec-test-author

**Command**: `/spec-test <domain>/<feature-slug>`  
**Model**: (varies)  
**Variant**: high

**Role**: Red phase of TDD - writes failing tests

**Workflow**:
1. Read feature spec, contracts manifest, and architecture design
2. Create per-app feature e2e tests: `apps/<app>/src/test/features/<domain>/<feature-slug>.e2e-spec.ts`
3. One `describe`/`it` per Gherkin `Feature`/`Scenario` (no step-definition binding)
4. Create unit tests for services/utils (colocated in `src/`)
5. Create MSW mocks for API contracts: `apps/pam-ui/src/test/mocks/<domain>.mock.ts`
6. Run tests (should be **red**)
7. Print `[STATUS] <domain>/<feature-slug> tested-red done|blocked: <reason>`

**Test Structure** (backend):
```typescript
describe('Feature: Transaction Dispute', () => {
  let app: INestApplication;
  let db: any;

  beforeAll(async () => {
    db = await setupTestDb();
    // Bootstrap Nest app
  });

  describe('Scenario: Player disputes recent transaction', () => {
    it('creates dispute with pending state', async () => {
      // Given - setup
      // When - action
      // Then - assertions
    });
  });
});
```

**Test Infrastructure**:
- Backend: PGlite for DB, supertest for HTTP
- Frontend: React Testing Library + MSW for API mocking
- Shared helpers: `apps/<app>/src/test/features/mocks/`

**Permissions**:
- Read: all
- Edit: `apps/**`, `packages/**` (test files)

---

#### 6. spec-implementer

**Command**: `/spec-implement <domain>/<feature-slug>`  
**Model**: Grok 4.6  
**Variant**: high  
**Steps**: 50

**Role**: Green phase - fills contracts until tests pass

**Workflow**:
1. Read feature spec, contracts manifest, red tests
2. List **every** host app with contract rows (must implement all, not just one)
3. Write `spec/features/<domain>/<feature-slug>.impl-plan.md`
4. Implement bodies of architect-created stubs in **each** host app
5. Add DB migrations as implied
6. Make minimal mechanical fixes to contracts/tests (never weaken assertions)
7. Run `yarn turbo run test:e2e --filter=<app>` for **every** host app until green
8. Run `yarn turbo run lint check-types build --filter=<app>` (or `--affected`)
9. Grep diff for `TODO`/`FIXME`/no-op bodies (must tie to `@todo` scenarios)
10. Print `[STATUS] <domain>/<feature-slug> implemented done|blocked: <reason>`

**Key Rules**:
- **All boundary-owning apps must be green** (not just one)
- Non-`@todo` scenarios require full implementation (no always-allow guards, no hardcoded literals when real collaborators exist)
- If real implementation blocked by out-of-scope infra, use `## Spec change required` escape hatch

**Domain Skills**: Load matching skills for cross-file propagation:
- New permission key → `add-permission` skill (registers in `PERMISSION_KEYS` + seed + mock)

**Spec Change Escape Hatch**: If API divergence requires scenario change, append `## Spec change required` to `.impl-plan.md`, print `blocked: spec-change-required`, stop

**Permissions**:
- Read: all
- Edit: `apps/**`, `packages/**`, `spec/features/**/*.impl-plan.md`
- Deny: `spec/features/**/*.feature` (frozen)
- Ask: destructive DB/infra

---

#### 7. spec-reviewer

**Command**: `/spec-review <domain>/<feature-slug>`  
**Model**: (varies)  
**Variant**: high

**Role**: Code review before merge

**Checks**:
- Implementation matches contracts
- No regressions (runs full test suite)
- Code quality (patterns, naming, DRY)
- Test coverage
- Security considerations
- Performance implications

**Outputs**: `spec/features/<domain>/<feature-slug>.code-review.md`

**Review Structure**:
```markdown
# Code Review: <feature-name>

## Summary
Approved for merge | Needs fixes

## Implementation Quality
✓ Contracts implemented
✓ Tests green
✓ Type-safe

## Issues (blocking)
None

## Suggestions (non-blocking)
- Consider adding index on...
- Extract common logic to...

## Approval
Ready for merge | Requires changes
```

**Prints**: `[STATUS] <domain>/<feature-slug> reviewed done|blocked: <reason>`

---

#### 8. spec-documenter

**Command**: `/spec-document <domain>/<feature-slug>`  
**Model**: (varies)  
**Variant**: high

**Role**: Generates audience-specific docs

**Creates 3 Documents**:

1. **Developer docs**: `docs/dev/<domain>/<feature-slug>.md`
   - Database schema (SQL + Drizzle)
   - API endpoints (request/response)
   - Events published/consumed
   - Testing instructions
   - PlantUML diagrams

2. **DevOps docs**: `docs/devops/<domain>/<feature-slug>.md`
   - Deployment steps
   - Migration instructions
   - Monitoring/alerting
   - Runbooks
   - Infrastructure requirements

3. **Operator docs**: `docs/operator/<domain>/<feature-slug>.md`
   - High-level UI workflow
   - User guide
   - Troubleshooting
   - FAQ

**Validation**: Checks docs against current DB schema and API contracts. Material disagreement blocks publication and produces drift report.

**Prints**: `[STATUS] <domain>/<feature-slug> documented done|blocked: <reason>`

**Permissions**:
- Read: all
- Edit: `docs/**`

---

#### 9. spec-prompt-designer

**Command**: `/spec-prompt <description>`  
**Model**: (varies)

**Role**: Helps craft clear feature prompts

**Workflow**:
1. Ask clarifying questions about the feature
2. Help refine acceptance criteria
3. Suggest scenario structure
4. Write to `spec/features/<root-slug>.brief.md`

**Output**: Well-structured prompt ready for `/spec-flow`

---

## Commands Reference

### Primary Commands

#### `/spec-flow <feature description>`

**Master orchestration command** - runs entire workflow.

**Stages** (in order):
1. Gather → `.feature` file
2. Critique → `.review.md`
3. Design → contracts + `.contracts.md`
4. Test → red tests
5. Implement → green code
6. Review → `.code-review.md`
7. Document → audience docs

**Agent**: `spec-orchestrator`

**Example**:
```bash
/spec-flow Add a deposit approval workflow where admins can review and approve/reject player deposits over $1000. Include email notifications on status changes.
```

**Behavior**:
- Creates/updates `spec/features/<root-slug>.state.md` (progress tracking)
- Appends to `spec/features/<root-slug>.brief.md` (prompt history)
- Delegates to stage agents via `task` tool
- Auto-advances through stages
- Pauses after gather for user confirmation
- Stops on genuine blockers (surfaces to user)

---

#### `/spec-gather <domain>/<feature-slug> [--new|--revise]`

Standalone requirements gathering.

**Agent**: `spec-analyst`

**Modes**:
- **Default**: Map from `requirements.md` or legacy
- **--new**: Brand-new functionality (prompt-driven)
- **--revise**: Fix blocked feature (edit frozen `.feature`)

**Example**:
```bash
/spec-gather wallet/deposit
/spec-gather loyalty/points --new
/spec-gather auth/login --revise
```

---

#### `/spec-critique <domain>/<feature-slug>`

Standalone quality review.

**Agent**: `spec-critic`

**Example**:
```bash
/spec-critique wallet/deposit
```

---

#### `/spec-design <domain>/<feature-slug>`

Standalone architecture design.

**Agent**: `spec-architect`

**Example**:
```bash
/spec-design wallet/deposit
```

---

#### `/spec-test <domain>/<feature-slug>`

Standalone test authoring (red phase).

**Agent**: `spec-test-author`

**Example**:
```bash
/spec-test wallet/deposit
```

---

#### `/spec-implement <domain>/<feature-slug>`

Standalone implementation (if contracts/tests exist).

**Agent**: `spec-implementer`

**Example**:
```bash
/spec-implement wallet/deposit
```

---

#### `/spec-review <domain>/<feature-slug>`

Standalone code review.

**Agent**: `spec-reviewer`

**Example**:
```bash
/spec-review wallet/deposit
```

---

#### `/spec-document <domain>/<feature-slug>`

Refresh documentation independently (outside `/spec-flow`).

**Agent**: `spec-documenter`

**Example**:
```bash
/spec-document wallet/deposit
```

---

### Utility Commands

#### `/pre-push-verify`

Run lints, type checks, and tests before pushing.

**Example**:
```bash
/pre-push-verify
```

---

## Rules Reference

### core.md (Always On)

**Key constraints**:

#### Context Budget
- Hard cap: **170k tokens** per session/agent
- Load skills **on demand** via `skill` tool
- Compact early, prefer tools over pasting large files

#### Task Gates (mandatory)
1. **Preflight** - load `task-preflight` before implementation
2. **Atomic work** - one responsibility per change
3. **No guessing** - missing reqs/contracts/schema → stop and ask
4. **Tests with code** - every behavior change ships tests
5. **Done means green** - run lint/typecheck/tests before finishing

#### Package Manager & Types
- **yarn only** (Berry, never npm/pnpm)
- **Zod only** for validation (`z.infer<typeof Schema>` for types)
- Shared schemas in `packages/contracts`

#### Git Commits (when asked)
```
<ticket> <verb> <what>
```
- Ticket from branch name (e.g. `ULT40-4`)
- Verb imperative lowercase
- No period, no AI co-author lines
- Subject ≤100 chars
- Body only for **why**

#### Skills Map

| When | Skill |
|---|---|
| Any non-trivial task start | `task-preflight` |
| Nest/Drizzle/API work | `backend-conventions` |
| pam-ui feature/UI work | `frontend-conventions` |
| Backend tests | `test-backend` |
| Frontend tests / MSW | `test-frontend` |
| New/updated contracts | `add-contracts-feature` |
| New API capability | `add-backend-feature` |
| New UI feature | `add-frontend-feature` |
| Legacy→EARS / wireframes | `convert-legacy-domain-docs`, `markdown-ui-dsl` |

---

### backend.md

NestJS, Drizzle ORM, API patterns:
- Module structure: `src/modules/<domain_cluster>/`
- DI patterns (inject `DATABASE` token, `DbModule` is `@Global()`)
- Drizzle conventions (offset pagination, `getOrderFn` for sorting)
- Swagger/OpenAPI decorators (`@ApiOperation`, `@ApiOkResponse`)
- DTOs via `createZodDto` (thin wrappers)
- Controller guards (`@UseGuards(PlayerGuard)`, `@UseGuards(AdminGuard)`)

---

### frontend.md

React, Vite, Tailwind patterns:
- Component structure: `src/features/<domain>/`
- State management (Zustand, TanStack Query)
- Routing (React Router)
- Styling (Tailwind v4, shadcn/ui)
- Form handling (React Hook Form + Zod)

---

## Skills Reference

### Core Skills

#### task-preflight (MANDATORY)

**When**: Before any non-trivial implementation

**Checks**:
1. **Goal**: Concrete outcome defined?
2. **Acceptance**: How do we know done?
3. **Spec/source**: Named path (feature file, REQ ids, or user rules)?
4. **Placement**: Target module/folder known?
5. **Contracts**: Existing schemas identified or plan to add?
6. **Data**: DB tables/columns known if persistence involved?
7. **Authz**: Who may call it (admin/player/public)?
8. **Tests**: Which layers required?

**If any fail**: Stop, ask user for missing items (do not invent)

**Atomic Split**: If request spans multiple responsibilities, split and do **one** now

**Required Test Plan**:
- Service + DB → PGlite integration specs
- Controller/HTTP → supertest specs
- Pure util/guard → unit specs
- API contract shape → mock fixtures
- UI component → component specs (mocked hooks)
- UI journey/page → integration RTL+MSW
- Feature Gherkin → app feature e2e

**Skill Cascade**: Load only what this task needs (in order):
1. `add-contracts-feature` (if schemas/mocks missing)
2. `backend-conventions` then `add-backend-module` / `add-backend-feature` (API work)
3. `frontend-conventions` then `add-frontend-feature` (UI work)
4. `test-backend` / `test-frontend` (while/after implementation)

**Context Budget**: 170k hard cap. Prefer grep/read slices, one domain cluster in memory, summarize after large dumps, finish atomic unit if approaching limit.

**Exit**:
- **Blocked**: list missing info, wait
- **Ready**: one-line plan + skills + test plan, then proceed

---

#### backend-conventions

**When**: NestJS/Drizzle/API work

**Covers**:
- Module scaffolding (`nest g module modules/<domain>`)
- Drizzle patterns (schema, migrations, queries)
- Controller/service structure
- OpenAPI documentation
- Validation (Zod via `createZodDto`)
- Pagination (offset-based, `Promise.all` for list+count)
- Sorting (`getOrderFn` from `@/common/drizzle.utils`)

**Key Patterns**:
- `DbModule` is `@Global()` → inject `DATABASE` directly
- DTOs are thin wrappers: `extends createZodDto(Schema)`
- Every endpoint: `@ApiOperation`, `@ApiOkResponse({ type })`, auth error decorator, guards
- Lists: `Promise.all([query, countQuery])` for single round trip

---

#### frontend-conventions

**When**: React/Vite/UI work

**Covers**:
- Component patterns (functional, hooks)
- Hook usage (useState, useEffect, custom hooks)
- Form handling (React Hook Form + Zod validation)
- Tailwind utilities (spacing, colors, responsive)
- shadcn/ui integration (Button, Input, Form, Dialog, etc.)
- Routing (React Router loaders, actions)
- API clients (TanStack Query, custom hooks like `useCreateDispute`)

**Component Structure**:
```tsx
// src/features/<domain>/<Component>.tsx
import { useState } from 'react';
import { Button } from '@/components/ui/button';

export function MyComponent() {
  const [state, setState] = useState();
  
  return (
    <div className="p-4">
      <Button onClick={...}>Click</Button>
    </div>
  );
}
```

---

#### test-backend

**When**: Writing backend tests

**Covers**:
- PGlite integration tests (in-memory Postgres)
- Supertest controller tests (HTTP)
- Unit test patterns (service mocking)
- Mocking strategies (DI injection)
- Test structure (Given/When/Then)

**Example** (integration):
```typescript
describe('DisputesService', () => {
  let service: DisputesService;
  let db: PGlite;

  beforeAll(async () => {
    db = await createPGlite();
    // Apply migrations
  });

  it('creates dispute with pending state', async () => {
    // Given
    const txn = await db.insert(...);
    
    // When
    const result = await service.createDispute({ transactionId: txn.id });
    
    // Then
    expect(result.state).toBe('pending');
  });
});
```

---

#### test-frontend

**When**: Writing frontend tests / MSW mocks

**Covers**:
- React Testing Library patterns (render, screen, userEvent)
- MSW API mocking (http handlers)
- Component tests (unit-style, mocked hooks)
- Integration tests (e2e-style, real API calls via MSW)
- Assertion patterns (accessibility queries)

**Example** (MSW mock):
```typescript
// src/test/mocks/disputes.mock.ts
import { http, HttpResponse } from 'msw';

export const disputeHandlers = [
  http.post('/api/v1/disputes', async ({ request }) => {
    const body = await request.json();
    return HttpResponse.json({
      id: 'mock-id',
      state: 'pending',
      ...body,
    });
  }),
];
```

**Example** (component test):
```tsx
import { render, screen, userEvent } from '@testing-library/react';
import { DisputeForm } from './DisputeForm';

test('submits dispute on button click', async () => {
  render(<DisputeForm transactionId="txn-1" />);
  
  await userEvent.type(screen.getByPlaceholderText('Describe the issue'), 'Unauthorized charge');
  await userEvent.click(screen.getByText('Submit Dispute'));
  
  expect(screen.getByText('Dispute submitted')).toBeInTheDocument();
});
```

---

### Feature Skills

#### add-backend-module

**When**: Creating a new NestJS domain cluster module in pam-api (module folder doesn't exist yet)

**Cascade**: Invoked by `add-backend-feature` when needed

**Steps**:
```bash
cd apps/pam-api
nest g module modules/<feature>
```

Creates `<feature>.module.ts` and registers in `AppModule`.

**Next**: Use `add-backend-feature` for contracts, DB, service, controller, then `test-backend`.

---

#### add-backend-feature

**When**: Adding new backend feature, endpoint, or capability to pam-api

**Cascade order**:
1. `task-preflight` (stop if incomplete)
2. `backend-conventions` (patterns)
3. `add-backend-module` (if `apps/pam-api/src/modules/<domain_cluster>/` missing)
4. `add-contracts-feature` (if contracts/mocks missing)
5. Implementation (below)
6. `test-backend` (required before done)

**Steps**:

**0. Exists check**:
```bash
ls apps/pam-api/src/modules/<domain_cluster>/
ls packages/contracts/src/<domain_cluster>/
```

**1. Contracts**: Missing folder → `add-contracts-feature`. Else extend schemas.

**2. DB** (if needed):
```typescript
// Edit packages/db/src/schema/<domain_cluster>.ts
export const myTable = pgTable('my_table', { ... });
```

```bash
yarn db:generate --name <descriptive_name>
# Show SQL to user, ask confirmation
yarn db:migrate
```

**3. DTOs**:
```typescript
// apps/pam-api/src/modules/<domain_cluster>/<name>.dto.ts
import { createZodDto } from 'nestjs-zod';
import { SomeRequestSchema, SomeResponseSchema } from '@ultima/contracts';

export class SomeRequestDto extends createZodDto(SomeRequestSchema) {}
export class SomeResponseDto extends createZodDto(SomeResponseSchema) {}
```

**4. Service**:
```bash
nest g service modules/<domain_cluster>/<name> --flat --no-spec
```

```typescript
@Injectable()
export class MyService {
  constructor(@Inject(DATABASE) private db: Database) {}

  async someAction(params: SomeParams): Promise<SomeResponse> {
    // Drizzle query
  }
}
```

**5. Controller**:
```bash
nest g controller modules/<domain_cluster>/<name> --flat --no-spec
```

```typescript
@Controller('api/v1/<resource>')
@UseGuards(PlayerGuard) // or AdminGuard
export class MyController {
  constructor(private myService: MyService) {}

  @Post()
  @ApiOperation({ summary: '...' })
  @ApiOkResponse({ type: SomeResponseDto })
  async create(@Body() dto: SomeRequestDto): Promise<SomeResponseDto> {
    return this.myService.someAction(dto);
  }
}
```

**6. Tests + verify**: Load `test-backend`, run `check-types`.

---

#### add-contracts-feature

**When**: Adding/updating shared Zod schemas

**Location**: `packages/contracts/src/<domain>/`

**Pattern**:
```typescript
// <name>.schemas.ts
import { z } from 'zod';

export const SomeRequestSchema = z.object({
  field: z.string().min(1),
  amount: z.number().positive(),
});

export const SomeResponseSchema = z.object({
  id: z.string().uuid(),
  status: z.enum(['pending', 'approved', 'rejected']),
  createdAt: z.string().datetime(),
});

export type SomeRequest = z.infer<typeof SomeRequestSchema>;
export type SomeResponse = z.infer<typeof SomeResponseSchema>;
```

**Export** from `packages/contracts/src/<domain>/index.ts`.

**Mock Fixtures** (for tests):
```typescript
// <name>.mock.ts
import { SomeResponse } from './schemas';

export const mockSomeResponse: SomeResponse = {
  id: 'mock-id',
  status: 'pending',
  createdAt: new Date().toISOString(),
};
```

---

#### add-frontend-feature

**When**: Adding UI component/page

**Cascade order**:
1. `task-preflight`
2. `frontend-conventions`
3. Implementation
4. `test-frontend`

**Steps**:

**1. Create component**:
```tsx
// apps/pam-ui/src/features/<domain>/<Component>.tsx
import { useState } from 'react';
import { useMyHook } from '@/api/<domain>';
import { Button } from '@/components/ui/button';

export function MyComponent() {
  const [state, setState] = useState();
  const mutation = useMyHook();

  const handleAction = async () => {
    await mutation.mutateAsync({ ... });
  };

  return (
    <div className="p-4">
      <Button onClick={handleAction}>Action</Button>
    </div>
  );
}
```

**2. Create API hook**:
```tsx
// apps/pam-ui/src/api/<domain>.ts
import { useMutation } from '@tanstack/react-query';
import { SomeRequest, SomeResponse } from '@ultima/contracts';

export function useMyAction() {
  return useMutation({
    mutationFn: async (data: SomeRequest): Promise<SomeResponse> => {
      const res = await fetch('/api/v1/<resource>', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
      });
      return res.json();
    },
  });
}
```

**3. Add route** (if new page):
```tsx
// apps/pam-ui/src/routes.tsx
{
  path: '/<resource>',
  element: <MyComponent />,
}
```

**4. Tests**: Load `test-frontend`.

---

#### add-permission

**When**: Registering new RBAC permission key

**Workflow**:

**1. Add to registry**:
```typescript
// packages/contracts/src/permissions/permissions.ts
export const PERMISSION_KEYS = {
  // ... existing
  'disputes:create': 'disputes:create',
  'disputes:resolve': 'disputes:resolve',
} as const;
```

**2. Update seed map** (type-forced):
```typescript
// packages/db/src/seeds/permissions.seed.ts
const permissionDescriptions: Record<PermissionKey, string> = {
  // ... existing
  'disputes:create': 'Create transaction disputes',
  'disputes:resolve': 'Resolve disputes (admin)',
};
```

**3. Update mock map** (type-forced):
```typescript
// packages/contracts/src/permissions/permissions.mock.ts
export const mockPermissions: Record<PermissionKey, string> = {
  // ... existing
  'disputes:create': 'disputes:create',
  'disputes:resolve': 'disputes:resolve',
};
```

All three are `Record<PermissionKey, string>` → missing entry = type error.

**4. Use in controller**:
```typescript
@RequirePermissions('disputes:create')
@Post()
async create(...) { ... }
```

**Never** use `@RequirePermissions(...)` for an unregistered key.

---

#### add-db-migration

**When**: Database schema changes

**Steps**:

**1. Edit schema**:
```typescript
// packages/db/src/schema/<domain>.ts
export const newTable = pgTable('new_table', {
  id: uuid('id').primaryKey().defaultRandom(),
  // ... columns
});
```

**2. Generate migration**:
```bash
cd packages/db
yarn db:generate --name <descriptive_name>
```

**3. Review SQL**: Read generated `migrations/<NNNN>_<name>.sql`, show to user

**4. Ask confirmation**: Only run after explicit approval

**5. Run migration**:
```bash
yarn db:migrate
```

**Naming convention**: `add_<table>_table`, `add_<column>_to_<table>`, `create_<index>_index`

---

### Documentation Skills

#### convert-legacy-domain-docs

**When**: Migrating legacy docs → EARS requirements

**Process**:
1. Read `spec/legacy/<domain>.md`
2. Extract normative rules
3. Convert to EARS format (SHALL/SHOULD/MAY)
4. Write `spec/domains/<domain>/requirements.md`
5. Create `spec/domains/<domain>/traceability.md` (legacy-to-REQ mapping)

---

#### markdown-ui-dsl

**When**: Creating low-fidelity wireframes

**Format**: Markdown-UI DSL screens

**Location**: `spec/domains/<domain>/ui/<screen>.ui.md`

**Purpose**: Visual layout only (not behavioral source of truth)

---

#### review-stakeholder-docs

**When**: Validating stakeholder-facing docs

**Checks**:
- Plain-language (no jargon)
- EARS compliance (SHALL/SHOULD/MAY)
- Completeness (all scenarios covered)
- Consistency (no contradictions)

---

## Creating a New PAM Service: Complete Workflow

### Scenario: Transaction Dispute Service

**Goal**: Create a "Transaction Dispute" service where players can flag transactions as disputed, and admins can review and resolve them.

---

### Step 1: Craft the Feature Prompt

**Use `/spec-prompt` (optional)**:
```
/spec-prompt I need a transaction dispute system where players can report issues with their transactions and admins can review and resolve them
```

The agent will ask clarifying questions and write to `spec/features/txn-dispute.brief.md`.

**OR use `/spec-flow` directly**:
```
/spec-flow Create a transaction dispute feature:
- Players can flag a transaction as disputed with a reason
- Disputes have states: pending, under_review, resolved, rejected
- Admins can view all disputes, add notes, and mark them resolved/rejected
- Players can only dispute transactions from the last 90 days
- Email notifications on status changes
```

---

### Step 2: Run the Flow

```
/spec-flow <your detailed prompt>
```

#### 2.1 Gather Stage

**Agent**: `spec-analyst`

**Actions**:
1. Reads prompt (primary source)
2. Reads `spec/domains/transactions/requirements.md` (if exists)
3. Asks clarifying questions if needed
4. Writes `spec/features/transactions/txn-dispute.feature`:

```gherkin
# Analyst assumptions:
# - Domain: transactions
# - Requirements consulted:
#   - [PROMPT] Player can dispute transactions
#   - [REQ transactions#REQ-8] Transaction history retention (90 days)
#   - [DERIVED] Email notifications (no explicit prompt requirement)

Feature: Transaction Dispute Management
  As a player I want to dispute transactions
  So that I can report issues with my account

  @req:transactions#REQ-8
  @req:new#dispute-time-window
  Scenario: Player disputes recent transaction
    Given a player "Alice" with account
    And a completed transaction "TXN-001" from 30 days ago
    When Alice disputes transaction "TXN-001" with reason "Unauthorized charge"
    Then the dispute is created with state "pending"
    And an email is sent to Alice confirming the dispute
    And an email is sent to the admin team

  @req:new#dispute-time-limit
  Scenario: Player cannot dispute old transaction
    Given a completed transaction "TXN-002" from 95 days ago
    When the player attempts to dispute "TXN-002"
    Then the dispute is rejected with error "Transaction too old"

  @req:new#admin-resolution
  Scenario: Admin resolves dispute
    Given a dispute "DIS-001" in state "under_review"
    When admin "Bob" resolves dispute "DIS-001" with note "Verified refund processed"
    Then the dispute state is "resolved"
    And the player receives a resolution email
```

5. Runs `yarn spec:lint -- transactions/txn-dispute` (exits 0)
6. Prints `[STATUS] transactions/txn-dispute gathered done`
7. Appends to `spec/features/txn-dispute.log.md`

**Orchestrator pauses**: "Please review `spec/features/transactions/txn-dispute.feature`. Does it match your expectations?"

**You**: "Yes, looks good!"

---

#### 2.2 Critique Stage

**Agent**: `spec-critic`

**Actions**:
1. Checks scenarios for testability, contracts, coverage
2. Writes `spec/features/transactions/txn-dispute.review.md`:

```markdown
# Feature Review: Transaction Dispute

## Summary
Approved for architecture with warnings.

## Approval
✓ Scenarios are concrete and testable
✓ Boundaries are clear (player API, admin API, persistence, notifications)

## Warnings
- W1: Email notification templates not specified
- W2: Concurrent dispute attempts not covered

## Coverage Gaps
None blocking.

## Required Contracts
- API: POST /api/v1/disputes (player), GET/PATCH /api/v1/admin/disputes (admin)
- DB: disputes table (id, transaction_id, player_id, state, reason, created_at, resolved_at)
- Events: dispute.created, dispute.resolved (for email)
```

3. Prints `[STATUS] transactions/txn-dispute critiqued done`

**Flow auto-advances to Design.**

---

#### 2.3 Design Stage

**Agent**: `spec-architect`

**Actions**:
1. Reads `.feature` and `.review.md`
2. Classifies scenarios:
   - Cross-app (UI → API → DB → Email)
   - Host apps: `pam-api`, `pam-ui`
3. Decides placement:
   - Backend: `apps/pam-api/src/modules/disputes/` (new)
   - Frontend: `apps/pam-ui/src/features/disputes/` (new)
4. Creates thin contracts in both apps:

**Backend** (`pam-api`):
```typescript
// disputes.module.ts
@Module({
  controllers: [DisputesController],
  providers: [DisputesService],
})
export class DisputesModule {}

// disputes.dto.ts
export class CreateDisputeRequestDto extends createZodDto(CreateDisputeRequestSchema) {}
export class DisputeResponseDto extends createZodDto(DisputeResponseSchema) {}

// disputes.service.ts
@Injectable()
export class DisputesService {
  constructor(@Inject(DATABASE) private db: Database) {}
  
  async createDispute(params: any): Promise<any> {
    // TODO: implement
    return undefined;
  }
}

// disputes.controller.ts
@Controller('api/v1/disputes')
@UseGuards(PlayerGuard)
export class DisputesController {
  constructor(private disputesService: DisputesService) {}
  
  @Post()
  @ApiOperation({ summary: 'Create transaction dispute' })
  @ApiOkResponse({ type: DisputeResponseDto })
  async createDispute(@Body() dto: CreateDisputeRequestDto): Promise<DisputeResponseDto> {
    // TODO: implement
    return undefined as any;
  }
}
```

**Contracts** (`packages/contracts`):
```typescript
// disputes/dispute.schemas.ts
export const CreateDisputeRequestSchema = z.object({
  transactionId: z.string().uuid(),
  reason: z.string().min(10).max(500),
});

export const DisputeResponseSchema = z.object({
  id: z.string().uuid(),
  transactionId: z.string().uuid(),
  playerId: z.string().uuid(),
  state: z.enum(['pending', 'under_review', 'resolved', 'rejected']),
  reason: z.string(),
  createdAt: z.string().datetime(),
  resolvedAt: z.string().datetime().nullable(),
});
```

5. Outlines DB schema in `.contracts.md`:

```markdown
## Database Schema Changes

New table: `disputes`

```typescript
// packages/db/src/schema/disputes.ts
export const disputeStateEnum = pgEnum('dispute_state', [
  'pending', 'under_review', 'resolved', 'rejected'
]);

export const disputes = pgTable('disputes', {
  id: uuid('id').primaryKey().defaultRandom(),
  transactionId: uuid('transaction_id').notNull().references(() => transactions.id),
  playerId: uuid('player_id').notNull().references(() => players.id),
  state: disputeStateEnum('state').notNull().default('pending'),
  reason: text('reason').notNull(),
  resolution: text('resolution'),
  resolvedBy: uuid('resolved_by').references(() => admins.id),
  createdAt: timestamp('created_at').notNull().defaultNow(),
  resolvedAt: timestamp('resolved_at'),
});
```
```

6. Writes contracts manifest (`txn-dispute.contracts.md`):

```markdown
# Contracts Manifest: Transaction Dispute

## Scenario Mapping

| Scenario | Contract Path | Method | Host App | Reuse/New | Boundary | Requirements |
|---|---|---|---|---|---|
| Player disputes recent transaction | pam-api: disputes.controller.ts | createDispute | pam-api | New | API→DB | transactions#REQ-8, new#dispute-time-window |
| Player disputes recent transaction | pam-ui: features/disputes/DisputeForm.tsx | submitDispute | pam-ui | New | UI→API | new#dispute-time-window |
| Admin resolves dispute | pam-api: admin/disputes.controller.ts | resolveDispute | pam-api | New | API→DB | new#admin-resolution |
| Admin resolves dispute | pam-ui: admin/disputes/DisputeDetail.tsx | handleResolve | pam-ui | New | UI→API | new#admin-resolution |
```

7. Registers module in `app.module.ts`
8. Runs `yarn turbo run check-types --filter=pam-api` (passes)
9. Prints `[STATUS] transactions/txn-dispute designed done`

**Flow auto-advances to Test.**

---

#### 2.4 Test Stage

**Agent**: `spec-test-author`

**Actions**:
1. Reads contracts and feature file
2. Creates red tests:

**Backend e2e** (`apps/pam-api/src/test/features/transactions/txn-dispute.e2e-spec.ts`):
```typescript
describe('Feature: Transaction Dispute Management', () => {
  let app: INestApplication;
  let db: any;

  beforeAll(async () => {
    db = await setupTestDb();
    // Bootstrap app
  });

  describe('Scenario: Player disputes recent transaction', () => {
    it('creates dispute with pending state', async () => {
      // Given
      const player = await db.createPlayer({ username: 'Alice' });
      const txn = await db.createTransaction({ 
        playerId: player.id,
        createdAt: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) 
      });

      // When
      const response = await request(app.getHttpServer())
        .post('/api/v1/disputes')
        .set('Authorization', `Bearer ${player.token}`)
        .send({ transactionId: txn.id, reason: 'Unauthorized charge' })
        .expect(201);

      // Then
      expect(response.body).toMatchObject({
        transactionId: txn.id,
        state: 'pending',
        reason: 'Unauthorized charge',
      });
    });
  });

  describe('Scenario: Player cannot dispute old transaction', () => {
    it('rejects dispute for transaction older than 90 days', async () => {
      // Given
      const player = await db.createPlayer();
      const txn = await db.createTransaction({ 
        playerId: player.id,
        createdAt: new Date(Date.now() - 95 * 24 * 60 * 60 * 1000) 
      });

      // When/Then
      await request(app.getHttpServer())
        .post('/api/v1/disputes')
        .set('Authorization', `Bearer ${player.token}`)
        .send({ transactionId: txn.id, reason: 'Issue' })
        .expect(400)
        .expect((res) => {
          expect(res.body.message).toContain('Transaction too old');
        });
    });
  });
});
```

**Service unit test** (`disputes.service.spec.ts`):
```typescript
describe('DisputesService', () => {
  let service: DisputesService;
  let mockDb: any;

  beforeEach(async () => {
    mockDb = { /* mock DB */ };
    const module = await Test.createTestingModule({
      providers: [
        DisputesService,
        { provide: DATABASE, useValue: mockDb },
      ],
    }).compile();
    service = module.get(DisputesService);
  });

  it('validates transaction age', async () => {
    // Test 90-day validation
  });
});
```

**MSW mock** (`apps/pam-ui/src/test/mocks/disputes.mock.ts`):
```typescript
export const disputeHandlers = [
  http.post('/api/v1/disputes', async ({ request }) => {
    const body = await request.json();
    return HttpResponse.json({
      id: 'mock-dispute-id',
      state: 'pending',
      ...body,
      createdAt: new Date().toISOString(),
    });
  }),
];
```

3. Runs tests (should be **red**)
4. Prints `[STATUS] transactions/txn-dispute tested-red done`

**Flow auto-advances to Implement.**

---

#### 2.5 Implement Stage

**Agent**: `spec-implementer`

**Actions**:
1. Loads skill: `add-backend-feature`
2. Reads contracts manifest (sees both `pam-api` and `pam-ui` rows)
3. Writes `txn-dispute.impl-plan.md`:

```markdown
# Implementation Plan: Transaction Dispute

## Apps to Implement
1. pam-api (backend persistence + API)
2. pam-ui (player dispute form + admin resolution UI)

## pam-api
- [ ] DB migration (disputes table)
- [ ] DisputesService.createDispute (with 90-day validation)
- [ ] DisputesService.resolveDispute (admin)
- [ ] DisputesController endpoints
- [ ] Email event publishing

## pam-ui
- [ ] Player: DisputeForm component
- [ ] Admin: DisputesList + DisputeDetail pages
- [ ] API client hooks
```

4. **Backend implementation**:

**Generate migration**:
```bash
cd packages/db
# Add schema to disputes.ts
yarn db:generate --name add_disputes_table
# Show SQL, ask approval
yarn db:migrate
```

**Implement service**:
```typescript
async createDispute(params: CreateDisputeParams): Promise<Dispute> {
  const { transactionId, playerId, reason } = params;

  // Fetch transaction with age check
  const [txn] = await this.db
    .select()
    .from(transactions)
    .where(eq(transactions.id, transactionId))
    .limit(1);

  if (!txn) {
    throw new NotFoundException('Transaction not found');
  }

  const txnAge = Date.now() - new Date(txn.createdAt).getTime();
  const ninetyDaysMs = 90 * 24 * 60 * 60 * 1000;

  if (txnAge > ninetyDaysMs) {
    throw new BadRequestException('Transaction too old');
  }

  // Insert dispute
  const [dispute] = await this.db
    .insert(disputes)
    .values({ transactionId, playerId, reason, state: 'pending' })
    .returning();

  // Publish event
  await this.eventPublisher.publish('dispute.created', dispute);

  return dispute;
}
```

5. **Frontend implementation**:

**Dispute form** (`apps/pam-ui/src/features/disputes/DisputeForm.tsx`):
```tsx
import { useCreateDispute } from '@/api/disputes';
import { Button } from '@/components/ui/button';
import { Textarea } from '@/components/ui/textarea';

export function DisputeForm({ transactionId }: { transactionId: string }) {
  const [reason, setReason] = useState('');
  const createDispute = useCreateDispute();

  const handleSubmit = async () => {
    await createDispute.mutateAsync({ transactionId, reason });
  };

  return (
    <form onSubmit={handleSubmit}>
      <Textarea 
        value={reason} 
        onChange={(e) => setReason(e.target.value)}
        placeholder="Describe the issue..."
      />
      <Button type="submit">Submit Dispute</Button>
    </form>
  );
}
```

6. Runs tests until **green**:
```bash
yarn turbo run test:e2e --filter=pam-api
yarn turbo run test:e2e --filter=pam-ui
yarn turbo run lint check-types build --affected
```

7. Greps for TODOs (must tie to `@todo` scenarios)
8. Prints `[STATUS] transactions/txn-dispute implemented done`

**Flow auto-advances to Review.**

---

#### 2.6 Review Stage

**Agent**: `spec-reviewer`

**Actions**:
1. Checks implementation vs contracts
2. Runs full test suite (no regressions)
3. Writes `txn-dispute.code-review.md`:

```markdown
# Code Review: Transaction Dispute

## Summary
Approved for merge.

## Implementation Quality
✓ All contract methods implemented
✓ 90-day validation present
✓ Email events published
✓ Tests green

## Suggestions (non-blocking)
- Consider adding index on disputes.transaction_id
- Admin resolution audit log would be useful

## Approval
Ready for merge.
```

4. Prints `[STATUS] transactions/txn-dispute reviewed done`

**Flow auto-advances to Document (final stage).**

---

#### 2.7 Document Stage

**Agent**: `spec-documenter`

**Actions**:
1. Generates 3 audience docs:

**Developer docs** (`docs/dev/transactions/txn-dispute.md`):
```markdown
# Transaction Dispute System

## Database Schema
```sql
CREATE TABLE disputes (
  id UUID PRIMARY KEY,
  transaction_id UUID REFERENCES transactions(id),
  player_id UUID REFERENCES players(id),
  state dispute_state NOT NULL DEFAULT 'pending',
  reason TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
```

## API Endpoints
- `POST /api/v1/disputes` - Create dispute (player)
- `GET /api/v1/admin/disputes` - List disputes (admin)
- `PATCH /api/v1/admin/disputes/:id` - Resolve (admin)

## Events
- `dispute.created` → email to player + admin
- `dispute.resolved` → email to player

## Testing
Run: `yarn turbo run test:e2e --filter=pam-api`
```

**DevOps docs** (`docs/devops/transactions/txn-dispute.md`):
```markdown
# Transaction Dispute Deployment

## Database Migration
Run: `yarn db:migrate` (adds `disputes` table)

## Monitoring
Watch for:
- High dispute creation rate (potential fraud)
- Long-pending disputes (admin backlog)

## Runbook
If dispute emails fail: check `pam.events.main` RabbitMQ queue.
```

**Operator docs** (`docs/operator/transactions/txn-dispute.md`):
```markdown
# Resolving Transaction Disputes

## Admin Workflow
1. Navigate to Admin → Disputes
2. Click on pending dispute
3. Review player reason and transaction details
4. Add resolution note
5. Click "Resolve" or "Reject"
6. Player receives email notification
```

2. Validates docs against current schema/contracts
3. Prints `[STATUS] transactions/txn-dispute documented done`

**Flow complete!**

---

### Step 3: Orchestrator Final Report

```
✓ transactions/txn-dispute: documented
  - Feature file: spec/features/transactions/txn-dispute.feature
  - Contracts: 4 host-app boundaries implemented
  - Tests: green (pam-api + pam-ui)
  - Documentation: 3 audience docs published

Flow complete. Feature ready for merge.
```

---

### Step 4: Commit and Deploy

```bash
git add .
git commit -m "ULT40-123 add transaction dispute feature"
git push
gh pr create --title "Transaction Dispute Feature" --body "Implements ULT40-123"
```

---

## Best Practices

### 1. Start with a Clear Prompt

❌ Bad:
```
/spec-flow add disputes
```

✅ Good:
```
/spec-flow Create a transaction dispute system where:
- Players can flag transactions with a reason
- Disputes have states: pending, under_review, resolved, rejected
- Admins can resolve with notes
- 90-day time limit
- Email notifications on state changes
```

### 2. Review After Gather

The orchestrator pauses after gathering. **Always review the `.feature` file** - this is your chance to correct misunderstandings before implementation.

### 3. Let Agents Cascade Skills

Don't manually load all skills. Agents know which to cascade:
- `spec-implementer` → `add-backend-feature`
- `add-backend-feature` → `backend-conventions` + `test-backend`

### 4. Trust the Token Budget

Rules are minimal because 170k budget is strict. Load skills only when needed.

### 5. Don't Edit `.feature` Files Manually

Only `spec-analyst` (via `--revise`) can edit frozen `.feature` files. Provide feedback at post-gather gate or let downstream blockers trigger `--revise`.

### 6. Use Atomic Tasks

If request is too large, split it:
```
/spec-flow Add disputes table and API (no UI yet)
```

Then later:
```
/spec-flow Add disputes UI for players and admins
```

### 7. Check Logs

Progress tracked in `.log.md`:
```bash
cat spec/features/txn-dispute.log.md
```

Each stage appends a `[STATUS]` line.

### 8. Use Independent Commands

You don't always need `/spec-flow`:
- Just gather: `/spec-gather transactions/deposits`
- Just implement: `/spec-implement transactions/deposits`
- Refresh docs: `/spec-document transactions/deposits`

---

## Common Patterns

### Pattern 1: Cross-App Feature

**Scenario**: Feature spans `pam-api` and `pam-ui`.

**Workflow**:
- Architect creates contracts in **both** apps
- Test author creates tests in **both** apps
- Implementer implements **both** apps (not just one)

**Key**: Manifest has **one row per (scenario, host app)**.

---

### Pattern 2: Database-Only Feature

**Scenario**: Just schema change + migration.

**Workflow**:
1. Edit `packages/db/src/schema/<domain>.ts`
2. Run `yarn db:generate --name <descriptive_name>`
3. Review SQL, confirm
4. Run `yarn db:migrate`

Use `add-db-migration` skill.

---

### Pattern 3: UI-Only Feature

**Scenario**: New component, no backend changes.

**Workflow**:
- `/spec-flow` still works (architect sees no backend contract needed)
- Test author creates component tests
- Implementer fills UI contracts

---

### Pattern 4: Permission-Gated Feature

**Scenario**: New endpoint needs RBAC permission.

**Workflow**:
1. Implementer loads `add-permission` skill
2. Adds key to `PERMISSION_KEYS`
3. Updates seed map
4. Updates mock map
5. Uses `@RequirePermissions('new-key')` decorator

**Never** add `@RequirePermissions(...)` for unregistered key - type error.

---

### Pattern 5: Blocked by Missing Requirements

**Scenario**: Prompt unclear.

**Workflow**:
- `spec-analyst` asks questions via `question` tool
- User answers
- Analyst records in `# Analyst assumptions` block

**Never guess** domain rules.

---

### Pattern 6: Downstream Spec Change

**Scenario**: Architect realizes scenario needs rewording.

**Workflow**:
1. Architect appends `## Spec change required` to `.contracts.md`
2. Prints `[STATUS] ... designed blocked: spec-change-required`
3. Orchestrator **automatically** delegates `/spec-gather --revise`
4. Analyst updates `.feature`
5. Flow restarts from critique

---

## Troubleshooting

### Issue: "Context budget exceeded"

**Cause**: Session over 170k tokens.

**Fix**:
- Split task into smaller atomic units
- Use `grep`/`read` slices instead of full files
- Summarize and drop raw output
- Continue in new session

---

### Issue: "Spec change required" loop

**Cause**: Gherkin doesn't match implementation reality.

**Fix**:
- Let `spec-analyst --revise` update `.feature`
- Critique re-validates
- Architect/test/implement re-run

---

### Issue: "Tests still red after implement"

**Cause**: Implementation incomplete or test assumptions wrong.

**Fix**:
- Check implementer's `TODO` grep (should tie to `@todo` scenarios)
- If implementation correct but tests wrong, manual fix or re-run test stage

---

### Issue: "Agent didn't implement backend"

**Cause**: Implementer only made UI green, ignoring backend contracts.

**Fix**:
- Check `.contracts.md` manifest - if backend has rows, it **must** be implemented
- Implementer rule: "all boundary-owning apps must be green"

---

### Issue: "Permission key type error"

**Cause**: `@RequirePermissions('unregistered-key')` used.

**Fix**:
- Load `add-permission` skill
- Add to `PERMISSION_KEYS` + seed + mock

---

## Quick Reference

### Commands Cheat Sheet

| Command | Purpose | Example |
|---|---|---|
| `/spec-flow <prompt>` | Full workflow (gather→doc) | `/spec-flow Add KYC verification` |
| `/spec-gather <prompt>` | Just gather | `/spec-gather transactions/deposits` |
| `/spec-gather <slug> --new` | Brand-new feature | `/spec-gather loyalty/points --new` |
| `/spec-gather <slug> --revise` | Fix frozen feature | `/spec-gather auth/login --revise` |
| `/spec-critique <slug>` | Review quality | `/spec-critique wallet/withdraw` |
| `/spec-design <slug>` | Create contracts | `/spec-design player/kyc` |
| `/spec-test <slug>` | Write red tests | `/spec-test rg-limits/set-limit` |
| `/spec-implement <slug>` | Fill contracts | `/spec-implement payments/deposit` |
| `/spec-review <slug>` | Code review | `/spec-review admin/reports` |
| `/spec-document <slug>` | Generate docs | `/spec-document auth/2fa` |
| `/pre-push-verify` | Run all checks | `/pre-push-verify` |

---

### Skill Load Decision Tree

```
Starting task?
├─ Non-trivial? → load `task-preflight`
│  └─ Preflight passes?
│     ├─ Backend work? → load `backend-conventions`
│     │  ├─ New module? → load `add-backend-module`
│     │  ├─ New feature? → load `add-backend-feature`
│     │  ├─ New contracts? → load `add-contracts-feature`
│     │  ├─ DB changes? → load `add-db-migration`
│     │  └─ New permission? → load `add-permission`
│     ├─ Frontend work? → load `frontend-conventions`
│     │  └─ New feature? → load `add-frontend-feature`
│     └─ Tests?
│        ├─ Backend? → load `test-backend`
│        └─ Frontend? → load `test-frontend`
└─ Trivial? → proceed directly
```

---

### File Locations Quick Map

```
PAM/
├── agent/                  # Agent definitions
├── command/                # Slash commands
├── rules/                  # Always-on constraints
├── skills/                 # On-demand patterns
├── AGENTS.md               # Always-loaded baseline
├── spec/
│   ├── features/           # Executable specs
│   │   └── <domain>/
│   │       ├── <slug>.feature       # Frozen Gherkin
│   │       ├── <slug>.review.md     # Critique
│   │       ├── <slug>.contracts.md  # Design
│   │       ├── <slug>.impl-plan.md  # Implement plan
│   │       └── <slug>.code-review.md# Review
│   ├── domains/            # EARS requirements
│   └── legacy/             # Historical docs
├── apps/
│   ├── pam-api/            # Backend (NestJS)
│   │   └── src/
│   │       ├── modules/<domain>/
│   │       └── test/features/<domain>/
│   └── pam-ui/             # Frontend (React)
│       └── src/
│           ├── features/<domain>/
│           └── test/features/<domain>/
├── packages/
│   ├── contracts/          # Zod schemas
│   ├── db/                 # Drizzle schemas/migrations
│   └── backend-shared/     # Shared backend code
└── docs/
    ├── dev/<domain>/       # Developer docs
    ├── devops/<domain>/    # Operations docs
    └── operator/<domain>/  # End-user docs
```

---

### Visual Flow Diagram

```
YOU type: /spec-flow Add login feature
       ↓
ORCHESTRATOR: "I'll manage this"
       ↓
ANALYST: "I'll write scenarios"
  → Creates password-reset.feature
       ↓
CRITIC: "I'll check quality"
  → Creates password-reset.review.md
       ↓
ARCHITECT: "I'll design code"
  → Creates empty templates
       ↓
TEST AUTHOR: "I'll write tests"
  → Creates test files
       ↓
IMPLEMENTER: "I'll build it"
  → Fills templates, tests pass!
       ↓
REVIEWER: "I'll inspect"
  → Approves code
       ↓
DOCUMENTER: "I'll write docs"
  → Creates 3 manuals
       ↓
ORCHESTRATOR: "All done! ✓"
       ↓
YOU: Commit and deploy!
```

---

## Creating Agents, Commands, and Skills

### Creating a New Agent (Step-by-Step)

**Example**: Security checker agent

**Step 1**: Create `agent/security-checker.md`

**Step 2**: Write the header:

```markdown
---
description: Checks code for security vulnerabilities
model: kilo/anthropic/claude-sonnet-4.5
variant: high
steps: 50
permission:
  bash: allow
  edit:
    "spec/features/**/*.security.md": allow
    "apps/**": deny
---
```

**Step 3**: Write the instructions:

```markdown
You are the **security-checker** agent.

## Your Job
Check code for common security problems.

## Steps
1. Read the code that was just written
2. Check for these issues:
   - Passwords in code
   - Missing input validation
   - SQL injection risks
   - Unsafe file uploads
3. Write report in `spec/features/<domain>/<feature>.security.md`
4. List each problem found
5. Say if code is "SAFE" or "NEEDS FIXES"
6. Print: `[STATUS] <domain>/<feature> security-checked done`

## What to Look For

### Passwords in Code
BAD: `password = "secret123"`
GOOD: `password = process.env.PASSWORD`

### SQL Injection
BAD: Raw SQL with concatenation
GOOD: Use Drizzle ORM

### File Uploads
BAD: Accept any file type
GOOD: Check file type and size

## Permissions
Read all; write only `*.security.md` files.
```

**Step 4**: Save the file.

**Step 5**: Create command (optional):

```markdown
---
description: Run security check on a feature
agent: security-checker
arguments: <domain>/<feature-slug>
---

Run the security-checker agent:

$ARGUMENTS
```

Now use: `/security-check wallet/deposit`

---

### Creating a Command (Step-by-Step)

**Example**: Quick test command

**Step 1**: Create `command/quick-test.md`

**Step 2**: Write:

```markdown
---
description: Run tests for one feature
agent: spec-test-author
arguments: <domain>/<feature-slug>
---

Run the test-author agent for this feature:

$ARGUMENTS

This will write and run tests just for this feature.
```

**Step 3**: Save and use:

```
/quick-test wallet/deposit
```

---

### Creating a Skill (Step-by-Step)

**Example**: Add API endpoint skill

**Step 1**: Create `skills/add-api-endpoint/SKILL.md`

**Step 2**: Write instructions:

```markdown
---
name: add-api-endpoint
description: How to add a new API endpoint to the backend
---

# Adding an API Endpoint

Use this when you need to add a new URL that accepts requests.

## Before You Start
Know:
- What data comes IN (request)
- What data goes OUT (response)
- Who can use it (admin/player/public)

## Steps

### 1. Create Schema
File: `packages/contracts/src/<domain>/<name>.schemas.ts`

```typescript
export const CreateDepositRequestSchema = z.object({
  amount: z.number().min(1).max(10000),
  currency: z.string().length(3),
});
```

### 2. Create DTO
File: `apps/pam-api/src/modules/<domain>/<name>.dto.ts`

```typescript
export class CreateDepositRequestDto extends createZodDto(CreateDepositRequestSchema) {}
```

### 3. Create Service
File: `apps/pam-api/src/modules/<domain>/<name>.service.ts`

```typescript
@Injectable()
export class DepositsService {
  constructor(@Inject(DATABASE) private db: Database) {}
  
  async createDeposit(params: CreateDepositRequest): Promise<DepositResponse> {
    // Logic here
  }
}
```

### 4. Create Controller
File: `apps/pam-api/src/modules/<domain>/<name>.controller.ts`

```typescript
@Controller('api/v1/deposits')
export class DepositsController {
  @Post()
  async createDeposit(@Body() dto: CreateDepositRequestDto): Promise<DepositResponseDto> {
    return this.depositsService.createDeposit(dto);
  }
}
```

### 5. Register in Module
Add controller and provider to module.

## Done!
Now you have: `POST /api/v1/deposits`
```

**Step 3**: Save. Agents will load via `skill` tool when needed.

---

### Creating a Rule (Step-by-Step)

**Example**: Security rules

**Step 1**: Create `rules/security.md`

**Step 2**: Write short, clear rules:

```markdown
# Security Rules (Always Enforced)

## Passwords
- NEVER hardcode passwords
- Always use environment variables

## API Keys
- NEVER commit API keys to git
- Store in `.env` file

## User Input
- ALWAYS validate with Zod schemas
- NEVER trust user data

## SQL Queries
- ALWAYS use Drizzle ORM
- NEVER write raw SQL

## File Uploads
- Check file type
- Limit file size (max 10MB)
- Scan for viruses

## Authentication
- ALWAYS require auth for sensitive endpoints
- Use `@UseGuards(PlayerGuard)` or `@UseGuards(AdminGuard)`

## Logging
- NEVER log passwords, tokens, or personal data
- Log user actions for audit trail
```

**Step 3**: Save. Now **every agent** follows these rules automatically.

---

## Summary

### The Golden Rules

1. **You describe WHAT, agents figure out HOW**
   - You: "I want password reset"
   - Agents: *write all the code*

2. **Start with `/spec-flow`** - the "easy button"

3. **Agents are just text files** - you can read/edit/create them

4. **Don't create agents unless you need a new worker type**
   - Use existing 99% of the time
   - Create skills (manuals) more often
   - Create commands (shortcuts) occasionally

5. **Review after the Analyst** - your chance to correct early

6. **Trust the process** - agents check each other, tests must pass

7. **Check the log file** when confused - shows what each agent did

---

## Your Learning Path

### Day 1: Watch
```
/spec-flow Add a simple "Contact Us" form
```
Watch agents work. Read the files they create.

### Day 2: Read
Open these files and read them:
- `agent/spec-analyst.md`
- `agent/spec-implementer.md`
- `command/spec-flow.md`

### Day 3: Create Simple Command
```markdown
---
description: Test command
agent: spec-analyst
arguments: <what-i-want>
---

$ARGUMENTS
```

### Day 4: Create Simple Skill
```markdown
---
name: my-checklist
description: Personal checklist
---

# Checklist
- [ ] Understand what's needed?
- [ ] Have examples?
- [ ] Know who to ask?
```

### Day 5: Create Simple Agent
```markdown
---
description: Simple reviewer
model: kilo/anthropic/claude-sonnet-4.5
variant: medium
steps: 20
permission:
  edit:
    "*.review.md": allow
---

Read code, check basics, write report.
```

---

## Congratulations!

You now understand:
- ✓ What agents are and how they work
- ✓ The 4 file types (agents, commands, rules, skills)
- ✓ How to use `/spec-flow` to create features
- ✓ How to create your own agents/commands/skills
- ✓ The complete workflow from prompt to deployment
- ✓ All 9 specialized agents and their roles
- ✓ How to troubleshoot common issues

**You don't need to be a programmer to use agents. Just describe what you want in plain English.**

---

## Need Help?

1. **Read the log**: `spec/features/<feature>.log.md`
2. **Check for errors**: Look for `[STATUS] ... blocked: <reason>`
3. **Ask your team**: Show them the log file
4. **Start simple**: Try a small feature first

The more you use agents, the more natural it becomes. Start small, experiment, and have fun! 🚀
