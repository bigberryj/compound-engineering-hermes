---
name: ce-plan
description: "Generate an execution plan for a problem and stop for review. Writes a plan doc at docs/plans/<slug>.md with: goal, files/functions affected, risk surface, verification plan, and rollback strategy. Sends a TLDR in chat and stops — does not execute. Use when the user says 'plan this', 'plan a fix', 'plan a change', or before kicking off 'ce-execute'. Companion skill to ce-execute (which runs the plan to completion)."
argument-hint: "[optional: brief problem statement] [mode:headless]"
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [planning, methodology, review, documentation]
    related_skills: [ce-execute, ce-compound, ce-brainstorm, ce-strategy, ce-ideate, plan]
---

# Plan a Change (`ce-plan`)

Generate an execution plan for a problem, write it down for review, and **stop**. This is the first half of the two-phase compound-engineering workflow: plan → review → execute.

**The hard rule:** this skill does NOT execute. It plans, documents, and reports. The next step is your call: "ce-execute" to run it, or edit the plan first.

## When to use

- Before a non-trivial code change, schema change, or config change
- When the user wants to review the approach before approving
- When you want a paper trail for compliance / future reference
- As a stand-in for "let me think about this" — instead of meandering, force a structured plan

## When NOT to use

- Trivial changes (typo fixes, version bumps, one-line tweaks) — just do them
- Pure research questions (use `ce-brainstorm` or `ce-ideate` instead)
- Emergency hotfixes where planning is overhead — do it, then `ce-compound` to document afterward

## What it produces

A plan doc at `docs/plans/<slug>.md` with:

1. **Goal** (1-2 sentences — what success looks like)
2. **Current state** (what's broken or missing, with file:line references)
3. **Proposed change** (files, functions, before/after snippets)
4. **Risk surface** (what could break, blast radius)
5. **Rollback** (how to undo, what to back up first)
6. **Verification plan** (tests, smoke tests, manual checks)
7. **Effort estimate** (S/M/L/XL — be honest)
8. **Open questions** (anything the reviewer should weigh in on)

After writing the plan, this skill sends a TLDR in chat (1-3 sentences + path) and stops. It does not start executing.

## Usage

```
ce-plan                                          # Plan the most recent problem
ce-plan [problem statement]                      # Plan a specific problem
ce-plan mode:headless [problem]                  # Non-interactive (for automations)
```

## Workflow

### Phase 1: Gather context

1. Understand the problem. If the user gave you one, use it. If not, look at recent git history, recent issues, recent chat context.
2. Read the relevant code. Don't skim — actually read the functions you'll be touching.
3. Note any constraints: backward compatibility, deploy timing, external dependencies.

### Phase 2: Decide the scope

Ask once, with `clarify`, if the scope is genuinely ambiguous:
- "Full plan with verification + rollback, or quick plan (just the change)?"

Don't ask if the answer is obvious from the problem statement. Default to "full plan" for non-trivial work.

### Phase 3: Write the plan doc

Use this template (also at `assets/plan-template.md`):

```markdown
---
title: "<one-line summary>"
date: YYYY-MM-DD
status: draft | approved | rejected | superseded
category: docs/plans
slug: <slug>
---

# Plan: <title>

## Goal

<1-2 sentences. What does "done" look like?>

## Current state

<What's broken or missing. File:line references.>

## Proposed change

<Files, functions, before/after.>

## Risk surface

<What could break. Blast radius.>

## Rollback

<How to undo. What to back up first.>

## Verification plan

<Tests, smoke tests, manual checks.>

## Effort estimate

<S / M / L / XL>

## Open questions

<Anything the reviewer should weigh in on.>
```

### Phase 4: TLDR + stop

After writing the plan, send a TLDR in chat:

> **Plan ready:** `<one-line goal>`
> Path: `docs/plans/<slug>.md`
> Effort: <S/M/L/XL>
> Open questions: <0 / 1 / 2+>
> **Reply "execute" or "ce-execute" to run it. Edit the plan first if you want changes.**

Then **stop**. Do not start executing. Do not preemptively start work. The next move is yours.

## Common mistakes to avoid

- **Plan is too vague.** "Fix the bug" isn't a plan. "Add a `try/except` around the line 47 `requests.get` call and log the error" is.
- **Plan is too long.** If the plan is bigger than 200 lines, scope it down. Plans are commitments, not essays.
- **No verification plan.** "It works" isn't verification. "Run `pytest tests/test_foo.py::test_bar` and see it pass" is.
- **No rollback.** Every plan needs a "if this goes wrong, here's how to undo" section. Even if rollback is trivial.
- **Open questions left in the chat, not the doc.** If you have a question, put it in the plan doc, not in a follow-up message.

## Related

- `ce-execute` — runs the plan to completion + verification (companion skill)
- `ce-compound` — older single-phase skill; replaced by `ce-plan` + `ce-execute` for non-trivial work
- `plan` — the generic Hermes plan skill, used for sub-task breakdowns
- `ce-strategy` — for product-level strategic planning (different scale)
- `ce-brainstorm` — for design exploration when the plan isn't clear yet
