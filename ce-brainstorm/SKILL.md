---
name: ce-brainstorm
description: "Explore requirements and approaches through collaborative dialogue, then write a right-sized requirements document. Use when the user says 'let's brainstorm', 'what should we build', or 'help me think through X', presents a vague or ambitious feature request, or seems unsure about scope or direction — even without explicitly asking to brainstorm."
argument-hint: "[feature idea or problem to explore] [output:md|html]"
version: 1.0.0
author: Hermes Agent (ported from EveryInc/compound-engineering-plugin, MIT)
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [brainstorm, requirements, planning, scope, dialogue]
    related_skills: [compound-engineering, ce-strategy, ce-ideate, ce-compound, plan, subagent-driven-development]
---

# Brainstorm a Feature or Improvement (`ce-brainstorm`)

**Note: The current year is 2026.** Use this when dating requirements documents.

Brainstorming helps answer **WHAT** to build through collaborative dialogue. It precedes the `plan` skill (or upstream's `ce-plan`), which answers **HOW** to build it.

The durable output of this workflow is a **requirements document**. In other workflows this might be called a lightweight PRD or feature brief. In compound engineering, keep the workflow name `brainstorm`, but make the written artifact strong enough that planning does not need to invent product behavior, scope boundaries, or success criteria.

This skill does not implement code. It explores, clarifies, and documents decisions for later planning or execution.

**IMPORTANT: All file references in generated documents must use repo-relative paths (e.g., `src/models/user.rb`), never absolute paths. Absolute paths break portability across machines, worktrees, and teammates.**

## Core Principles

1. **Assess scope first** — Match the amount of ceremony to the size and ambiguity of the work.
2. **Be a thinking partner** — Suggest alternatives, challenge assumptions, and explore what-ifs instead of only extracting requirements.
3. **Resolve product decisions here** — User-facing behavior, scope boundaries, and success criteria belong in this workflow. Detailed implementation belongs in planning.
4. **Keep implementation out of the requirements doc by default** — Do not include libraries, schemas, endpoints, file layouts, or code-level design unless the brainstorm itself is inherently about a technical or architectural change.
5. **Right-size the artifact** — Simple work gets a compact requirements document or brief alignment. Larger work gets a fuller document. Do not add ceremony that does not help planning.
6. **Apply YAGNI to carrying cost, not coding effort** — Prefer the simplest approach that delivers meaningful value. Avoid speculative complexity and hypothetical future-proofing, but low-cost polish or delight is worth including when its ongoing cost is small and easy to maintain.

## Interaction Rules

These rules apply to every brainstorm.

1. **Ask one question at a time** — One question per turn, even when sub-questions feel related. Stacking produces diluted answers; pick the single most useful one and ask it.
2. **Prefer single-select multiple choice** — Use `clarify` single-select when choosing one direction, one priority, or one next step.
3. **Use multi-select rarely and intentionally** — Use it only for compatible sets such as goals, constraints, non-goals, or success criteria that can all coexist. If prioritization matters, follow up by asking which selected item is primary.
4. **Default to the `clarify` tool** for blocking questions. The tool includes a free-text fallback, so well-chosen options scaffold the answer without confining it. Fall back to numbered options in chat only when `clarify` errors or is unavailable.
5. **Use an open-ended question only when the question is genuinely open** — Drop the blocking tool when the answer is inherently narrative, when presented options would steer a diagnostic or introspective answer, or when you cannot write 3-4 genuinely distinct, plausibly-correct options without padding.

## Output Guidance

- **Keep outputs concise** — Prefer short sections, brief bullets, and only enough detail to support the next decision.
- **Use repo-relative paths** — When referencing files, use paths relative to the repo root (e.g., `src/models/user.rb`), never absolute paths.

## Model Tiers (Hermes Adaptation)

Sub-agent dispatch is tiered by task shape, never hardcoded to a model name:

- **Extraction tier** — the grounding scout: retrieval and quoting work. Use the cheapest capable model in Hermes (MiniMax M3 / scout profile). "Capable" is part of the spec — escalate to the generation tier when the repo is large or the stack obscure.
- **Generation tier** — the claim verifier: evidence-driven mechanical verification. Use the mid-tier model in Hermes.
- **Ceiling tier** — the dialogue itself. Questions, approaches, synthesis, and the requirements doc run in the main conversation on the orchestrator's model; nothing is dispatched for them.

**Degradation rule.** When the subagent primitive does not support per-agent model selection, dispatch the scout and verifier on the inherited model and keep their read budgets and output caps — cost control then comes from structure, not tiering.

## Feature Description

<feature_description> #$ARGUMENTS </feature_description>

**If the feature description above is empty, ask the user:** "What would you like to explore? Please describe the feature, problem, or improvement you're thinking about."

Do not proceed until you have a feature description from the user.

## Execution Flow

### Phase 0: Resume, Assess, and Route

#### 0.0 Resolve Output Mode

Determine `OUTPUT_FORMAT` before any other phase fires. Output mode is **exclusive** — the requirements doc is written as either markdown (`.md`) OR HTML (`.html`), never both. Precedence: CLI arg > config > default (`md`).

**Resolution steps:**

1. **CLI arg.** Scan arguments for a token starting with the literal prefix `output:`. If found, strip it from arguments and match its value case-insensitively against `md` and `html`.
   - `output:` alone (no value) → no-op, fall through to step 2.
   - `output:<unknown>` (e.g., `output:pdf`) → drop the token, fall through, remember to emit a one-line note above the post-generation menu: `Ignored unknown output: value '<value>' — using <resolved_format> instead.`
2. **Config.** If step 1 did not resolve and `.compound-engineering/config.local.yaml` at the project root has an **active (non-commented)** `brainstorm_output:` key matching `md` or `html`, use it. Commented lines starting with `#` must be ignored.
3. **Default.** Otherwise `OUTPUT_FORMAT=md`.

**Token-parsing convention:** only literal-prefix flag tokens (`output:`) are consumed and stripped. Other `<word>:<word>` tokens — including conventional commit prefixes like `feat:`, `fix:`, `chore:` — pass through verbatim.

#### 0.1 Resume Existing Work When Appropriate

If the user references an existing brainstorm topic or document, or there is an obvious recent matching `*-requirements.{md,html}` file in `docs/brainstorms/`:

- Read the document
- Confirm with the user before resuming: "Found an existing requirements doc for [topic]. Should I continue from this, or start fresh?"
- If resuming, summarize the current state briefly, continue from its existing decisions and outstanding questions, and update the existing document instead of creating a duplicate
- **Resume preserves the existing artifact's format.** Write back in whatever format the existing artifact uses. Explicit `output:` arguments override.

#### 0.1b Classify Task Domain

Before proceeding, classify whether this is a software task. The key question is: **does the task involve building, modifying, or architecting software?** — not whether the task *mentions* software topics.

- **Software** (continue to Phase 0.2) — the task references code, repositories, APIs, databases, or asks to build/modify/debug/deploy software.
- **Non-software brainstorming** — Both: (a) none of the software signals above are present, AND (b) the task describes something the user wants to explore, decide, or think through in a non-software domain. For these, follow `references/universal-brainstorming.md` instead of Phases 0.2–4.
- **Neither** — the input is a quick-help request, error message, factual question, or single-step task. Respond directly, skip all brainstorming phases.

**If non-software brainstorming is detected:** Read `~/.hermes/skills/compound-engineering/ce-brainstorm/references/universal-brainstorming.md` and follow it. The Core Principles and Interaction Rules above still apply unchanged.

#### 0.2 Assess Whether Brainstorming Is Needed

**Clear requirements indicators:**

- Specific acceptance criteria provided
- Referenced existing patterns to follow
- Described exact expected behavior
- Constrained, well-defined scope

**If requirements are already clear:** Keep the interaction brief. Confirm understanding and present concise next-step options rather than forcing a long brainstorm. Only write a short requirements document when a durable handoff to planning or later review would be valuable. Skip Phase 1.1 and 1.2 entirely — go straight to Phase 1.3 or Phase 2.5, then to Phase 3.

#### 0.3 Assess Scope

Use the feature description plus a light repo scan to classify the work:

- **Lightweight** — small, well-bounded, low ambiguity
- **Standard** — normal feature or bounded refactor with some decisions to make
- **Deep** — cross-cutting, strategic, or highly ambiguous

If the scope is unclear, ask one targeted question to disambiguate and then proceed.

**Deep sub-mode: feature vs product.** For Deep scope, also classify whether the brainstorm must establish product shape or inherit it:

- **Deep — feature** (default): existing product shape anchors decisions. Primary actors, core outcome, positioning, and primary flows are already established. The brainstorm extends or refines within that shape.
- **Deep — product**: the brainstorm must establish product shape rather than inherit it. Primary actors, core outcome, positioning against adjacent products, or primary end-to-end flows are materially unresolved.

Product-tier triggers additional Phase 1.2 questions and additional sections in the requirements document.

### Phase 1: Understand the Idea

#### 1.1 Existing Context Scan

Scan the repo before substantive brainstorming. Match depth to scope.

**Lightweight** — Search for the topic, check if something similar already exists, and move on.

**Standard and Deep** — Two passes:

*Constraint Check (inline)* — Check project instruction files (`AGENTS.md`, and `CLAUDE.md` only if retained as compatibility context) for workflow, product, or scope constraints that affect the brainstorm. Also read `STRATEGY.md` if it exists — the product's target problem, approach, persona, and active tracks are direct input to what this brainstorm should deliver. Also read `CONCEPTS.md` at repo root if it exists — the project's authoritative vocabulary. Use these names in dialogue, approaches, and the requirements doc; map user-offered synonyms back. If any of these add nothing, move on. This pass stays in the main conversation — the dialogue needs this material in context to shape its questions.

*Topic Scan (grounding scout)* — Create a scratch dir at `/tmp/compound-engineering/ce-brainstorm/<run-id>/` (short unique slug), then dispatch one extraction-tier sub-agent via `delegate_task` (with `toolsets=["file", "terminal"]`) — in the background where supported — and proceed to Phase 1.2/1.3 **without waiting**: the scout runs during the user's think-time on the opening questions. Scout prompt:

> Gather grounding for a requirements brainstorm about **{topic}** in this repo. Search first with the native file-search and content-search tools, then read targeted sections — budget ~20 reads, preferring ranges over whole files. Find: whether something similar already exists, the most relevant existing artifacts (brainstorms, plans, specs, feature docs), adjacent examples of similar behavior, and the current state of anything the topic would touch (tables, routes, config, dependencies). Write a **grounding dossier** to `{scratch-dir}/grounding.md`: at most 150 lines of verbatim quotes and short code snippets, each with a `file:line` pointer. Extraction only — quote what the repo says; do not interpret or propose. If the topic has little footprint, write less rather than padding. Return only a gist: 3-5 lines summarizing what the dossier holds, plus its absolute path.

Carry only the gist in the dialogue. When the conversation needs specifics the gist can't answer — the user challenges a claim, an approach needs grounding — read the dossier on demand. Downstream consumers (the Phase 2.6 verifier, the plan handoff) receive the dossier path, not its contents.

**Two rules govern technical depth during the scan:**

1. **Verify before claiming** — When the brainstorm touches checkable infrastructure (database tables, routes, config files, dependencies, model definitions), read the relevant source files to confirm what actually exists. Any claim that something is absent — a missing table, an endpoint that doesn't exist, a dependency not in the Gemfile, a config option with no current value — must be backed by a direct read.
2. **Quote file:line, not memory** — File paths and class names get stale. When claiming a feature exists at a path, quote the path. When claiming a class has a method, quote the method signature.

#### 1.2 Establish the Frame

For Standard and Deep scope, the early questions should pin down the foundational frame before drilling into behavior. The frame is what makes the brainstorm a brainstorm and not a requirements interrogation.

For each frame question, lead with the sharpest one. Skip questions the user has already answered.

**Founders / goals**

- What is the user trying to accomplish? What is the job they are hiring the product to do?
- What is the smallest version that delivers the outcome? What does "done" look like?
- Who specifically is the user? (Persona, situation, not demographic.)

**Scope**

- What is in scope for this brainstorm? What is explicitly NOT in scope?
- Are there adjacent areas this could expand into that we are deliberately deferring?

**Approaches (when there are real choices)**

- Are there multiple ways to satisfy the goal? Name the top 2-3 approaches you see, with the tradeoffs.
- What did you try before that didn't work? What's the constraint or assumption behind each?

**For Deep — product tier only:** also explore primary actors, core outcome, positioning against adjacent products, and primary end-to-end flow. The product shape must exist before the feature.

#### 1.3 Fill the Open Questions

Continue with the user-facing dialogue, one question at a time, until the open questions are answered. Match question depth to the remaining ambiguity — at this point most of the work is closing specific gaps, not exploring the frame.

For Standard and Deep, dispatch a generation-tier subagent as a "claim verifier" to check the dossier-backed claims about the current codebase. Pass the dossier path and the brainstorm's emerging spec; the verifier returns:

- Verified: each claim that's actually true against the current code
- Contradicted: each claim that conflicts with the current code (with the contradicting `file:line`)
- Unverifiable: claims that can't be checked from the dossier

Do not start Phase 2 until the verifier has returned.

#### 1.5 / 1.6 Section-Building

For Standard/Deep scope, run a short subagent pass to draft the per-section bodies (goals, non-goals, scope, success criteria, examples, open questions, references) from the conversation transcript and the dossier. Return text, not files. The orchestrator assembles the final doc in Phase 3.

For Lightweight scope, the orchestrator writes the doc inline in Phase 3 with no subagent assistance.

### Phase 2: Synthesis

Assemble the requirements document. Read `assets/requirements-template.md` (`~/.hermes/skills/compound-engineering/ce-brainstorm/assets/requirements-template.md`) for the section structure and frontmatter.

Section content is the same in either format; presentation differs. If `OUTPUT_FORMAT=html`, load `references/html-rendering.md` for the HTML rendering rules.

### Phase 2.5 Announce-Mode

For Lightweight scope, or when requirements are already clear and the user did not want a long brainstorm, run this phase in announce-mode: emit a brief synthesis of the conversation into chat for visibility, no blocking confirmation, then write the doc. This avoids forcing a confirmation round when the user already said "just write it up."

### Phase 2.6 Final Verification

Before writing the doc, dispatch a final generation-tier subagent to cross-check the assembled doc against the grounding dossier. Pass the dossier path and the draft doc text. The verifier flags:

- Unsupported claims (any assertion in the doc not grounded in the dossier or the conversation)
- Stale references (paths, class names, function signatures that have drifted)
- Missing constraints (scope items the user named that did not make it into the doc)
- Drift from STRATEGY.md / CONCEPTS.md (uses a name the project's vocabulary doesn't recognize, or contradicts a strategic anchor)

If the verifier flags anything, the orchestrator resolves it before writing.

### Phase 3: Write the Document

Write the assembled doc to:

- `docs/brainstorms/<slug>-requirements.md` (markdown) or
- `docs/brainstorms/<slug>-requirements.html` (HTML)

Create the directory if needed. Slug is a short, kebab-case topic derived from the feature description. Run `validate-frontmatter.py` if the chosen format has frontmatter:

```bash
python3 ~/.hermes/skills/compound-engineering/ce-compound/scripts/validate-frontmatter.py <doc-path>
```

### Phase 4: Handoff

After writing, surface in chat:

- The doc path
- A 2-3 line summary of the doc's main decisions
- The "what's next" menu, using `clarify` for blocking questions

What's next menu:

1. **Plan it (recommended)** — Hand off to the `plan` skill (or upstream `ce-plan`) with the requirements doc as input. The plan will reference the doc throughout.
2. **Refine this doc** — Re-run the brainstorm with a specific section to revisit
3. **Brainstorm another** — Start a new brainstorm on a different topic
4. **Done for now** — Save the doc; user will pick this up later

## What This Skill Does Not Do

- Does not write code or plan implementation steps
- Does not update the issue tracker or commit anything
- Does not pick the *best* approach when there are multiple — the doc captures the tradeoffs and surfaces the decision for planning
- Does not duplicate `plan` (Hermes built-in) — plan answers "how should this be built"; brainstorm answers "what exactly should this mean"

## Related Skills

- `ce-ideate` — precede brainstorm with this when the user wants options to choose from
- `ce-strategy` — anchor for STRATEGY.md that grounds this brainstorm
- `plan` (Hermes built-in) — what comes after this
- `ce-compound` — what comes after the work, when something hard was learned

## Learn More

The Requirements doc format is deliberately lightweight — long PRDs rot. The sections track the decisions a planner needs to make, not the documentation a future maintainer might want. If a section earns its keep, it's because a planner would have invented the same thing in its absence.
