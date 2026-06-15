---
name: compound-engineering
description: "Methodology entry point for the compound engineering loop. Routes a request to the right skill (ce-strategy, ce-ideate, ce-brainstorm, ce-plan, ce-work, ce-code-review, ce-compound, ce-compound-refresh, ce-product-pulse, ce-setup). Use when the user mentions 'compound engineering', asks what to use for a given dev task, or wants the full workflow. The loop is: ideate -> brainstorm -> plan -> work -> review -> compound (capture lesson) -> repeat."
argument-hint: "[optional: which skill you need, or describe the task]"
version: 1.0.0
author: Hermes Agent (ported from EveryInc/compound-engineering-plugin, MIT)
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [methodology, workflow, delegation, planning, review, knowledge]
    related_skills: [ce-strategy, ce-ideate, ce-brainstorm, plan, writing-plans, subagent-driven-development, requesting-code-review, ce-compound, ce-compound-refresh, ce-product-pulse, ce-setup]
---

# Compound Engineering (Hermes Port)

**Methodology, not ceremony.** 80% planning + review, 20% execution. Each unit of engineering work should make the next one *easier*, not harder.

## The loop

```
ideate -> brainstorm -> plan -> work -> review -> compound -> repeat
                                       ^--------------------|
```

Every step compounds. A well-captured learning today shortens planning tomorrow. A well-grounded plan reduces rework during work. A well-run review surfaces patterns worth documenting.

## What each skill does

| Skill | Question it answers | When to use it |
|---|---|---|
| `ce-strategy` | "What is this product and what are we investing in?" | Starting a new product, refreshing direction, or grounding other skills in `STRATEGY.md` |
| `ce-ideate` | "What are the strongest ideas worth exploring?" | Open-ended: "give me ideas", "what should I improve", "surprise me" |
| `ce-brainstorm` | "What exactly should one chosen idea mean?" | Vague feature request, scope unclear, need a requirements doc before planning |
| `plan` (Hermes built-in) | "How should this be built, step by step?" | A scope exists; need tasks with file paths, paths through code, verification steps |
| `subagent-driven-development` (Hermes) | "How do I execute a plan efficiently with quality gates?" | Plan is in hand; dispatch fresh subagents per task with two-stage review |
| `requesting-code-review` (Hermes) | "Is this change ready to merge?" | Before committing/merging; tiered review agents |
| `ce-compound` | "What did we just learn, and how do we capture it?" | After a hard problem is solved — produces a solution doc into `docs/solutions/` and possibly updates `CONCEPTS.md` |
| `ce-compound-refresh` | "Are my old solution docs still trustworthy?" | Periodic maintenance; consolidates, updates, replaces, or deletes stale docs |
| `ce-product-pulse` | "How is the product actually performing?" | Time-windowed usage/quality/error report; reads analytics, tracing, payments, DB |
| `ce-setup` | "Is my environment ready for compound engineering?" | One-shot diagnostic; checks CLI tools, config, gitignore, suggests fixes |

## Routing — which skill to load

If the user says any of these, load the matching skill with `skill_view` before proceeding:

| Trigger | Load |
|---|---|
| "compound engineering", "ce-...", "what's the loop" | (this skill — already loaded) |
| "strategy", "STRATEGY.md", "what are we working on", "write our strategy" | `ce-strategy` |
| "give me ideas", "what should I improve", "ideate on X", "surprise me" | `ce-ideate` |
| "let's brainstorm", "what should we build", "help me think through X", vague feature | `ce-brainstorm` |
| "plan this", "how should we build it", "create a plan", "break this down" | `plan` (Hermes built-in) |
| "execute the plan", "start work", "run the tasks" | `subagent-driven-development` |
| "review this", "code review", "is this ready" | `requesting-code-review` |
| "that worked", "it's fixed", "working now", "problem solved", "document this" | `ce-compound` |
| "refresh my learnings", "audit docs/solutions", "stale learnings", "consolidate docs" | `ce-compound-refresh` |
| "run a pulse", "weekly recap", "how are we doing", "show me 24h" | `ce-product-pulse` |
| "setup", "diagnose my env", "check CE install" | `ce-setup` |

If unclear, ask the user which step of the loop they're on. Don't guess.

## What compound engineering is NOT

- **Not a list of plugins to install.** It's a methodology. The skills are tools; the value is in the loop.
- **Not a replacement for Hermes's existing skills.** `plan`, `subagent-driven-development`, `requesting-code-review`, `systematic-debugging`, `simplify-code` — those are already great. The CE skills sit *upstream* (strategy, ideate, brainstorm) and *downstream* (compound, refresh, pulse) of that core.
- **Not ceremony for ceremony's sake.** If a doc is overkill for a 5-minute fix, skip it. `ce-compound` runs in a "lightweight" single-pass mode for exactly that case.

## Porting notes (vs. upstream EveryInc/compound-engineering-plugin)

This is a Hermes port. The methodology is identical; the mechanics are platform-specific:

| Upstream (Claude Code) | Hermes |
|---|---|
| `AskUserQuestion` | `clarify` tool |
| `Skill` invocation | `skill_view(name=...)` + skill name in the prompt |
| `${CLAUDE_SKILL_DIR}` | `~/.hermes/skills/compound-engineering/<skill>/` (resolved at runtime) |
| `ce-sessions` (sub-skill) | Inline in the orchestrator: `session_search(query=..., limit=...)` |
| `git rev-parse --show-toplevel` pre-resolution | Same — the skill checks for a resolved value first, falls back to running the command |
| 30 vertical/framework skills (Rails, Xcode, iOS) | **Skipped** — they're Claude Code specific. |
| `auto_invoke` triggers ("that worked") | **Skipped** — Hermes skills are user-invoked explicitly. |
| Subagent model tiering (`haiku`/`sonnet`/ceiling) | Hermes provider/model override — use cheap model for scouts, ceiling for synthesis |

The complete porting translation table (including the `delegate_task` output caps, the subdir-shape gotcha, the `_shared/` mirroring pattern, and the smoke-test sequence) lives in `~/.hermes/skills/software-development/hermes-agent-skill-authoring/references/port-claude-skills-to-hermes.md`. Read that reference if you're porting this bundle further or porting a different bundle.

## Install

This skill and its siblings live in `~/.hermes/skills/compound-engineering/`. No install step needed beyond placing the files. The bundled `ce-compound/scripts/validate-frontmatter.py` is a stdlib-only Python script; run it via `python3` on any solution doc before declaring the doc complete.

## Where knowledge lives

Compound engineering writes to your project repo, not to Hermes home:

- `STRATEGY.md` (repo root) — product strategy anchor
- `CONCEPTS.md` (repo root) — shared domain vocabulary
- `docs/solutions/<category>/<slug>.md` — individual learnings
- `docs/solutions/patterns/<slug>.md` — derived pattern docs
- `docs/brainstorms/<slug>-requirements.md` — requirements docs from `ce-brainstorm`
- `docs/plans/<slug>-plan.md` — plans from `plan` (or upstream's `ce-plan`)
- `docs/ideation/<slug>-ideation.{md,html}` — ideation artifacts from `ce-ideate`
- `docs/pulse-reports/YYYY-MM-DD_HH-MM.md` — pulse reports from `ce-product-pulse`
- `.compound-engineering/config.local.yaml` (repo root) — per-project CE config (gitignored)
