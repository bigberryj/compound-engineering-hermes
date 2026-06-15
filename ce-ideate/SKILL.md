---
name: ce-ideate
description: "Generate and critically evaluate grounded ideas about a topic. Use when asking what to improve, requesting idea generation, exploring surprising directions, or wanting the AI to proactively suggest strong options before brainstorming one in depth. Triggers on phrases like 'what should I improve', 'give me ideas', 'ideate on X', 'surprise me', 'what would you change', or any request for AI-generated suggestions rather than refining the user's own idea."
argument-hint: "[feature, focus area, or constraint] [output:md|html]"
version: 1.0.0
author: Hermes Agent (ported from EveryInc/compound-engineering-plugin, MIT)
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [ideation, brainstorming, ideas, methodology, scope]
    related_skills: [compound-engineering, ce-strategy, ce-brainstorm, ce-compound, plan]
---

# Generate Improvement Ideas (`ce-ideate`)

**Note: The current year is 2026.** Use this when dating ideation documents and checking recent ideation artifacts.

`ce-ideate` precedes `ce-brainstorm`.

- `ce-ideate` answers: "What are the strongest ideas worth exploring?"
- `ce-brainstorm` answers: "What exactly should one chosen idea mean?"
- `plan` answers: "How should it be built?"

This workflow produces a ranked ideation artifact — written to `docs/ideation/` when present, else a CE temp path (see Phase 4). It does **not** produce requirements, plans, or code.

## Interaction Method

Use `clarify` for blocking questions. Ask one question at a time. Prefer concise single-select choices when natural options exist.

## Focus Hint

<focus_hint> #$ARGUMENTS </focus_hint>

Interpret any provided argument as optional context. It may be:

- a concept such as `DX improvements`
- a path such as `plugins/compound-engineering/skills/`
- a constraint such as `low-complexity quick wins`
- a volume hint such as `top 3`, `100 ideas`, or `raise the bar`

If no argument is provided, proceed with open-ended ideation.

## Core Principles

1. **Ground before ideating** — Scan the actual codebase first. Do not generate abstract product advice detached from the repository.
2. **Generate many → critique all → explain survivors only** — The quality mechanism is explicit rejection with reasons, not optimistic ranking.
3. **Route action into brainstorming** — Ideation identifies promising directions; `ce-brainstorm` defines the selected one precisely enough for planning.

## Model Tiers (Hermes Adaptation)

Sub-agent dispatch is tiered by task shape, never hardcoded to a model name:

- **Extraction tier** — evidence scouts and other retrieval/quoting work. Use MiniMax M3 (cheapest capable model in Hermes).
- **Generation tier** — evidence-driven ideation frames and basis verification. Use the mid-tier model in Hermes.
- **Ceiling tier** — ceiling ideation frames, cross-cutting synthesis, and final arbitration. Inherit the orchestrator's model.

**Degradation rule.** When the subagent primitive does not support per-agent model selection, dispatch everything on the inherited model and keep the read budgets and dossier caps.

**Surprise-me mode** raises the whole ideation fleet to the ceiling tier — subject discovery is judgment-heavy and is the mode's whole value.

## Execution Flow

### Phase 0: Resume and Scope

#### 0.0 Resolve Output Mode

Determine `OUTPUT_FORMAT` for the ideation artifact this run might persist. Output mode is **exclusive** — markdown (`.md`) OR HTML (`.html`), never both. Precedence: CLI arg > config > default (`md`).

**Resolution steps:**

1. **CLI arg.** Scan arguments for a token starting with the literal prefix `output:`. If found, strip and match against `md` and `html` (case-insensitive).
2. **Config.** If step 1 did not resolve and `.compound-engineering/config.local.yaml` has an **active (non-commented)** `ideate_output:` key matching `md` or `html`, use it. Commented lines must be ignored.
3. **Default.** Otherwise `OUTPUT_FORMAT=md` (Hermes default — see note below).

**Hermes adaptation note:** Upstream defaults `ce-ideate` to `html` because humans read ideation artifacts. In Hermes, where markdown is the dominant format for chat and code review, we default to `md` to keep the artifact readable in any text tool. Set `ideate_output: html` in `.compound-engineering/config.local.yaml` to restore the HTML default.

**Token-parsing convention:** only literal-prefix flag tokens (`output:`) are consumed and stripped. Other `<word>:<word>` tokens — including conventional commit prefixes like `feat:`, `fix:`, `chore:` — pass through verbatim.

#### 0.1 Check for Recent Ideation Work

Look in `docs/ideation/` for ideation documents (`*.md` or `*.html`) created within the last 30 days.

Treat a prior ideation doc as relevant when:

- the topic matches the requested focus
- the path or subsystem overlaps the requested focus
- the request is open-ended and there is an obvious recent open ideation doc

If a relevant doc exists, ask via `clarify` whether to:

1. continue from it
2. start fresh

If continuing:

- read the document
- summarize what has already been explored
- preserve the previous ideas and rejection summary
- update the existing file instead of creating a duplicate
- **write the update back in the existing file's format**, overriding the Phase 0.0 baseline.

#### 0.2 Subject-Identification Gate

Before classifying mode or dispatching any grounding, check whether the subject of ideation is identifiable. Every downstream agent — grounding and ideation — needs to know what it's working on.

**Questioning principles:**

- Questions exist only to supply what sub-agents need: an identifiable subject (this phase) and enough context for the agent to say something specific about it.
- Never ask about solution direction, constraints, audience, tone, or success criteria — those belong to `ce-brainstorm`.
- Always keep "Surprise me" (letting the agent decide the focus) as a real option, not a fallback for when the user can't name a subject.
- Stop as soon as the subject is identifiable or the user has delegated to "Surprise me." More than 3 total questions across 0.2 and 0.4 is a smell that ideation is not the right workflow.

**The scope question.** Ask via `clarify`:

- **Stem:** "What should the agent ideate about?"
- **Options:**
  - "Specify a subject the agent should ideate on"
  - "Surprise me — let the agent decide what to focus on"
  - "Cancel — let me rephrase"

**Routing:**

- **Specify** → accept the user's follow-up as the subject. Re-apply the identifiability check once. If still ambiguous, ask once more with "Surprise me" still on the menu.
- **Surprise me** → mark the run as **surprise-me mode**. The agent will discover subjects from Phase 1 material rather than carry a user-specified subject. This is a first-class mode — it changes how Phase 1 scans and how Phase 2 sub-agents operate. **Dispatch routing for surprise-me is deterministic:** if CWD is inside a git repo, route to repo-grounded (the codebase supplies substance); otherwise refuse with a one-line message that says "surprise me outside a repo needs a URL, description, or paste — give me something to surprise you about."
- **Cancel** → exit cleanly.

#### 0.3 Mode Classification

Classify the **subject of ideation** into one of three modes for dispatch routing.

**For specified subjects**, make two sequential binary decisions:

**Decision 1 — repo-grounded vs elsewhere.** Weigh prompt content first, topic-repo coherence second.

- Positive signals for **repo-grounded**: prompt references repo files, code, architecture, modules, tests, or workflows; topic is clearly bounded by the current codebase.
- Negative signals (push toward **elsewhere**): prompt names things absent from the repo (pricing, naming, narrative, business model, personal decisions, brand, content, market positioning).

**Decision 2 (only fires if Decision 1 = elsewhere) — software vs non-software.** Classify by whether the *subject* of ideation is a software artifact or system.

State the inferred approach in one sentence at the top, using plain language the user will recognize. Never print the internal taxonomy label (`repo-grounded`, `elsewhere-software`, `elsewhere-non-software`) to the user.

#### 0.5 Interpret Focus and Volume

Infer two things from the argument and any intake so far:

- **Focus context** — concept, path, constraint, or open-ended
- **Volume override** — any hint that changes candidate or survivor counts

Default volume:

- each ideation frame yields about 6-8 ideas (~36-48 raw across the six frames in the default path; roughly 25-30 survivors after dedupe)
- keep the top 5-7 survivors

Honor clear overrides such as `top 3`, `100 ideas`, `raise the bar`.

**Depth override.** `go deep` (or equivalent) opts into maximum depth deliberately: every ideation agent moves to the ceiling tier, the Phase 2 verification read budget doubles, and Phase 3 adds a second critic. The default is the mixed-tier fleet.

**Tactical scope detection.** Parse the focus hint for tactical signals: `polish`, `typo`, `typos`, `quick wins`, `small improvements`, `cleanup`, `small fixes`. When present, lower the Phase 2 ambition floor — the user has explicitly opted into tactical scope.

### Phase 1: Mode-Aware Grounding

Before generating ideas, gather grounding. The dispatch set depends on the mode chosen in Phase 0.3.

**Repo-grounded (default for code-adjacent focus):**

- 1 codebase-scan subagent — sample representative files per top-level area, surface recent PR/commit activity
- 1 learnings-researcher — read `docs/solutions/` and `CONCEPTS.md` for established patterns
- Up to 5 evidence scouts (extraction tier) — targeted reads on axes the topic touches
- The output is a dossier written to `/tmp/compound-engineering/ce-ideate/<run-id>/grounding.md`

**Elsewhere-software (subject lives outside this repo but is software-shaped):**

- 1 user-context synthesis subagent — extracts themes from whatever the user supplied
- 1 web researcher — broadens beyond narrow prior-art toward the domain's landscape
- 1 learnings-researcher (read-only) — pattern transfer from this repo's docs/solutions/, used carefully

**Elsewhere-non-software (naming, narrative, personal, non-digital business):**

- 1 user-context synthesis subagent
- 1 web researcher
- NO learnings-researcher (rarely transfers; the CWD's `docs/solutions/` is engineering-pattern heavy)

**Surprise-me mode** raises Phase 1 depth — Phase 2 sub-agents will discover their own subjects from what Phase 1 returns, so texture matters.

When the user supplied a research artifact (URL, paste, draft, brief), the user-supplied research handling also runs in all modes.

### Phase 2: Ideation Frames

Six frames by default. Each frame runs as a subagent. Each generates 6-8 ideas. Each idea is returned with a short rationale.

1. **Direct improvements** — the most obvious ways to make the subject better
2. **Adjacent expansion** — natural extensions into neighboring territory
3. **Pain-point reversal** — for each friction surfaced, the inverse feature that would remove it
4. **Persona shift** — how the subject would change if it prioritized a different user
5. **Constraint removal** — ideas that only become possible if a current constraint is dropped
6. **Cross-domain import** — patterns from outside the subject's domain that could be applied here

After generation, dispatch a **basis verifier** (generation tier) to check each idea's rationale against the grounding dossier. Ideas with no dossier support get a "weak basis" flag.

### Phase 3: Critique + Rank

All generated ideas go through critique. The quality mechanism is explicit rejection with reasons — do not just rank optimistically. Each idea gets:

- **Keep** with one-line rationale, OR
- **Reject** with the specific reason (not enough support, conflicts with strategy, out of scope, etc.)

Then rank the survivors and explain only the top 5-7 (not the rejects — the rejection summary is what proves the discipline).

### Phase 4: Write the Artifact

Read `references/ideation-sections.md` (load with `read_file ~/.hermes/skills/compound-engineering/ce-ideate/references/ideation-sections.md`) for the section structure. Write the artifact to:

- `docs/ideation/<slug>-ideation.md` (markdown) or
- `docs/ideation/<slug>-ideation.html` (HTML)

Create the directory if needed. Slug is short, kebab-case, topic-derived.

For HTML output, follow the rendering rules in `references/html-rendering.md`. For markdown, follow `references/markdown-rendering.md`.

### Phase 5: Post-Ideation Handoff

After writing, surface in chat:

- The artifact path
- A 2-3 line summary of the top-ranked ideas
- The "what's next" menu, using `clarify` for blocking questions

What's next menu:

1. **Brainstorm the top idea (recommended)** — Hand off to `ce-brainstorm` with the top idea as the focus. The brainstorm will define that idea precisely enough for planning.
2. **Brainstorm a different survivor** — Pick another idea from the top list
3. **Refine this ideation** — Re-run ideation with a tighter focus or volume override
4. **Done for now** — Save the artifact; user will pick this up later

## What This Skill Does Not Do

- Does not write code or plan implementation
- Does not pick the *best* idea — it ranks, but the user picks
- Does not duplicate `ce-brainstorm` — brainstorm defines one chosen idea; ideation identifies the candidates

## Related Skills

- `ce-strategy` — strategic anchor that grounds the ideation
- `ce-brainstorm` — what comes after this, for the chosen idea
- `plan` (Hermes built-in) — what comes after brainstorm

## Hermes Adaptation Notes

The upstream `ce-ideate` defaults to `html` output. We default to `md` to fit the Hermes/markdown-native ecosystem; users who want HTML can set `ideate_output: html` in `.compound-engineering/config.local.yaml`.

The upstream has a long Phase 1 about PostHog, Sentry, Slack research integrations. In Hermes, we replace those with the simpler dispatch taxonomy above (codebase scan, learnings researcher, evidence scouts, web researcher, user-context synthesis). The web researcher and Slack integrations are not pre-wired — users can add them via custom MCP servers or pre-fetched research artifacts.
