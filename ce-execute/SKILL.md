---
name: ce-execute
description: "Execute an approved plan from docs/plans/<slug>.md to completion. Runs the plan step-by-step, captures verification evidence (test output, smoke test, manual confirmation), and writes a solution doc at docs/solutions/<category>/<slug>.md that cross-references the plan. Hard rule: this skill runs UNTIL DONE AND VERIFIED. It does not stop early for clarification unless the goal is genuinely ambiguous, an action is destructive with no rollback, or external input is required. Use when the user says 'execute this plan', 'run it', 'go', 'ship it', or 'ce-execute' after a plan has been approved."
argument-hint: "[optional: path to plan file] [mode:headless]"
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [execution, methodology, plans, verification]
    related_skills: [ce-compound, ce-plan, ce-brainstorm, ce-strategy, systematic-debugging, requesting-code-review]
---

# Execute an Approved Plan (`ce-execute`)

Run a plan from `docs/plans/<slug>.md` (or a plan inlined in the chat) to **completion and verification**. This is the second half of the two-phase compound-engineering workflow: plan → review → execute.

**The hard rule:** this skill runs UNTIL DONE AND VERIFIED. It does not stop early for "is this OK?" or "do you want me to continue?" checks. It only stops for:
- A genuinely ambiguous goal (not just uncertain)
- A destructive action with no rollback (force pushes, mass deletes, prod deploys without a backup)
- External input that's truly required (credentials, a user click, a paid service confirmation)
- Verification fails and the failure cannot be fixed by adjusting the approach

When this skill stops, it has either shipped the change with green verification, or it has a concrete blocker that needs your call.

## When to use

- After `ce-plan` (or any other planning) has produced a plan doc and you've said "go" / "execute" / "ship it"
- When you want a non-trivial change made end-to-end without hand-holding through every step
- When you want verification evidence (test output, smoke test, manual screenshot) captured as part of the run

## What it produces

For every execution, the deliverable is a **solution doc** at `docs/solutions/<category>/<slug>.md` with:

1. **Plan cross-reference** — links back to the approved plan
2. **What actually happened** — every step that ran, including pivots from the original plan
3. **Verification evidence** — test output, smoke test results, manual confirmation, or screenshots
4. **CONCEPTS.md** — qualifying domain terms added (if not already present)
5. **Discoverability check** — `AGENTS.md` / `CLAUDE.md` updated if `docs/solutions/` isn't surfaced (silent edit, no prompt)

If the run hits a true blocker, the solution doc captures the blocker instead and what was tried.

## Usage

```
ce-execute                                       # Execute the most recent plan
ce-execute path/to/plan.md                       # Execute a specific plan file
ce-execute [context hint]                        # Inline plan description
ce-execute mode:headless                         # Non-interactive (for cron/automations)
```

## Mode Detection

Same as `ce-compound` — `mode:headless` in arguments means no blocking questions. Only use headless for automations; the interactive mode is safer for human-driven runs because it'll surface real blockers via `clarify` instead of guessing.

## Pre-resolved context

**Project root (pre-resolved):** !`git rev-parse --show-toplevel 2>/dev/null || pwd`

If the line above resolved to a directory path, use it as `<project-root>` for all subsequent operations. If it shows the literal backtick command string, resolve at runtime with `git rev-parse --show-toplevel` (falling back to `pwd`).

## Workflow

### Phase 0: Load the plan

1. Find the plan file:
   - If a path was passed in the arguments, use it
   - Otherwise, look for the most recently modified `docs/plans/*.md` (sorted by mtime)
   - If no plan is found, ask once: *"No plan found. Do you want to (a) point me to one, (b) describe the plan inline, or (c) cancel and run `ce-plan` first?"*
2. Read the plan thoroughly. Confirm you understand:
   - The goal (one sentence)
   - The changes (files, functions, lines)
   - The risk surface
   - The verification plan
3. **If the plan is ambiguous or contradicts itself, stop and ask.** This is one of the legitimate "stop early" cases. Don't guess.

### Phase 1: Set up the working environment

1. Check git state: is the working tree clean? If not, decide: stash, commit, or abort. Don't silently lose uncommitted work.
2. Identify the branch. If the plan says "branch: fix/foo", check it out (or create it). If on main and the plan doesn't say, **create a feature branch** (e.g. `ce-execute/<plan-slug>`). Don't push to main without explicit approval — the user pref says "Byron accepts direct pushes to main after explicit approval, with verification first."
3. Note the starting commit SHA so you can diff later.

### Phase 2: Execute the plan

For each step in the plan, in order:

1. **Make the change** — code, config, docs, whatever the plan calls for
2. **Verify the change locally** — lint, type-check, unit tests if they exist
3. **Move to the next step** — don't stop to narrate every line, just keep going

If a step fails:
- Read the error carefully
- Try the obvious fix (typo, missing import, wrong path)
- If the fix is within the plan's intent, apply it and continue
- If the fix requires changing the plan, note the deviation and continue (capture it in the solution doc later)

If a step is blocked by missing infrastructure (a service isn't running, a dependency isn't installed, a credential is needed):
- Note the blocker
- Try the next step that doesn't depend on it
- If everything depends on it, stop and report the blocker

### Phase 3: Run the verification plan

The plan's verification section is a contract. Run it.

For a typical project, verification means:
- **Linting passes** (ruff, eslint, phpcs, etc. — whatever the project uses)
- **Type checks pass** (mypy, tsc, phpstan)
- **Unit tests pass** (`pytest`, `npm test`, `phpunit`)
- **Smoke test passes** — actually start the app/service/plugin and confirm it works
  - For a CLI: `python -m my_cli --help` returns 0
  - For a web app: a curl request to a health endpoint returns 200
  - For a WordPress plugin: the plugin's admin page loads without errors
  - For a desktop app: it launches and a core action works
- **Manual spot-check** — if the change is user-facing, verify the UX works as intended (e.g. click the button, see the right thing happen)

**If verification fails, the run isn't done.** Debug, fix, re-verify. Loop until it passes or you hit a true blocker.

### Phase 4: Capture evidence

For the solution doc, you need concrete evidence:
- Test output (last 20 lines of the test run)
- Linter output ("ruff check: All checks passed!")
- Smoke test output (the curl response, the --help output, the screenshot path)
- The git diff stat (how many files changed, how many lines)

Save these to `docs/solutions/<category>/<slug>.md` as quoted blocks under "Verification evidence."

### Phase 5: Write the solution doc

Use the `ce-compound` skill's `assets/resolution-template.md` as the template. Fill in:
- `plan:` (cross-reference to the plan doc)
- `what_happened:` (every step, with pivots noted)
- `verification:` (the evidence from Phase 4)
- `deviations_from_plan:` (anything that changed)
- `next_time:` (what you'd do differently, or what to look out for)

Frontmatter:
```yaml
---
title: "<one-line summary>"
date: YYYY-MM-DD
category: docs/solutions/<category>
plan: docs/plans/<slug>.md       # cross-ref
module: <module>
problem_type: <type>
root_cause: <cause>
resolution_type: code_fix | config_change | refactor | new_feature
severity: low | medium | high
tags: [...]
---
```

### Phase 6: Discoverability check

If `docs/solutions/` is not referenced in `<project-root>/AGENTS.md` or `<project-root>/CLAUDE.md`, add a one-line pointer. Silent edit — don't prompt for it.

### Phase 7: Commit and (optionally) push

1. Stage all changes
2. Commit with a conventional commit message:
   ```
   <type>(<scope>): <summary>

   [body — what changed, why, what was verified]

   Plan: docs/plans/<slug>.md
   Solution: docs/solutions/<category>/<slug>.md
   ```
3. **If the user pre-authorized push (their pref says yes, with verification), push.**
4. **If not pre-authorized, do not push.** Report the local commit and ask.

### Phase 8: Report

Final response includes:
- One-line summary of what shipped
- Path to the solution doc
- Path to the commit(s)
- Verification status (green check, with the evidence)
- Any open follow-ups

## Stop conditions (the only legitimate ones)

| Condition | Action |
|---|---|
| Verification passes | Ship it. Report. |
| Plan is ambiguous / contradicts itself | Ask once with `clarify`. If answered, continue. If not answered, abort with a clear blocker. |
| Destructive action with no rollback | **Stop.** Force pushes, mass deletes, prod deploys, schema migrations on real data. Always ask. |
| External input required | **Stop.** Credentials, paid service confirmation, manual user click, OAuth flow. Ask via `clarify` with concrete options. |
| Verification fails and the failure cannot be fixed by reasonable means | Stop. Report what was tried. |

If none of these apply, **keep going.** Don't ask "should I continue?" Don't narrate every step. Run it to done.

## Related

- `ce-plan` — generates the plan this skill executes (companion skill, same workflow)
- `ce-compound` — the original single-phase skill; `ce-execute` is the execute-half refactor
- `ce-compound-refresh` — for maintaining an existing `docs/solutions/` tree
- `systematic-debugging` — use when verification fails and you need to root-cause
- `requesting-code-review` — use before merging to main if the project has reviewers

## License

MIT — see project root.
