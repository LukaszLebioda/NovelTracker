# Always-on rules — NovelTracker

## Start of every session — check permissions

At the start of every conversation or when resuming work, read
`.kilo/kilo.json` to understand what permissions you have. Do not ask
permission for actions that are already set to "allow" in kilo.json.

## Documentation sync — start of every task

Before doing anything else, check that `AGENTS.md` and `README.md` still
match reality, and update them first when needed:

- `AGENTS.md` — update when the project's stack, structure, conventions, or
  domain mapping change.
- `README.md` — append to the progress log anything worth remembering:
  decisions, completed steps, new files and their purpose.

## PAM is the reference — the user decides the style

Always check and refer to `PAM/` and `COMPLETE_PAM_AGENT_GUIDE.md` when
shaping this project's workflow, agent definitions, or conventions. How we
actually proceed is the user's explicit decision: PAM-style, or an
alternative the agent suggests. Never introduce PAM machinery (or any new
file) without proposing it and getting approval first.

## Spec-driven workflow — user provides requirements

The workflow for gathering feature specifications:

1. **User provides feature description** — The user describes features in plain
   language in the chat dialogue. The agent does NOT invent or create feature
   descriptions.
2. **Agent may ask questions** — The agent can ask clarifying questions or
   suggest improvements if requirements are unclear or incomplete.
3. **spec-analyst converts to Gherkin** — Once requirements are clear, the
   spec-analyst agent converts them into executable Gherkin scenarios in
   `spec/features/<domain>/<feature-slug>.feature`.
4. **User reviews and approves** — The user reviews the generated spec file
   before it becomes frozen. Once frozen, changes go only through spec-analyst
   in revise mode.

### Two documentation layers (both come from the user)

The user's plain-language input is the single source for BOTH documents; the
difference is form and timing, not origin:

- **`spec/domains/<domain>/requirements.md`** — the canonical, numbered list of
  rules (`REQ-001`, `REQ-002`, …) in EARS form ("When …, the system must …").
  Written down once per domain and kept stable; it is the source of truth for
  business rules.
- **`spec/features/<domain>/<feature-slug>.feature`** — executable Gherkin
  examples of those rules. Many examples may prove one rule. Each scenario
  carries `@req:<domain>#REQ-nnn` pointing back at the rule it proves.

Flow: user describes → the analyst writes/updates the numbered requirements →
the analyst writes Gherkin examples that trace to those numbers → the user
reviews and freezes the `.feature`. Requirements are never invented by the
agent; they are the user's intent recorded in canonical form.

## Future option — automatic driver ("foreman" / orchestrator)

Recorded for a future decision; NOT adopted yet. PAM runs its whole pipeline
(gather → critique → design → test → implement → review → document)
automatically through an orchestrator agent plus one chain command
(`/spec-flow`), handing work stage-to-stage on its own. The alternative — and
our current choice — is running each stage by hand, one command at a time, so
the user controls the pace. The automatic driver can be adopted later if the
pipeline grows enough to justify it.

## Live rules — update them as we talk

Rules are not static. During any interaction, watch for anything that should
change how we work and propose a rule update:

- A new convention, decision, or constraint the user states → propose adding
  or amending a rule in `.kilo/rules/core.md`.
- A recurring correction or an instruction the agent keeps getting wrong →
  propose a rule so it sticks for future sessions.
- A rule that no longer matches how we actually work → propose removing or
  rewriting it.

The agent always proposes the change (showing the exact text) and applies it
only after the user approves. Rules live in `.kilo/rules/` (always-on) and
`.kilo/agent/` (per-agent); permission settings live in `.kilo/kilo.json`.

## Design inputs — docs and wireframes

External design material is an input to the spec-driven loop, never the
behavioral source of truth:

- **Written requirements / specification documents** are gather-stage inputs.
  The user provides them (or places them under `spec/domains/<domain>/`) and
  the spec-analyst converts them into `.feature` scenarios. The frozen
  `.feature` remains the source of truth.
- **UI designs and wireframes** (e.g. Figma, low-fidelity sketches) are
  implementation inputs for the `client/` UI and may inform the wording of
  UI-facing scenarios. When kept in-repo they live under
  `spec/domains/<domain>/ui/`. Visual layout is never the behavioral source of
  truth — the Gherkin scenarios are.

Never treat a design document or wireframe as a requirement that overrides a
frozen `.feature`: when they disagree, the `.feature` wins until it is revised
through the spec-analyst.

## Done means documented

A task is not complete until both files are up to date. Judge "needs update?"
once before starting the task and again before declaring it done.
