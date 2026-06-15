# Universal (Non-Software) Brainstorming

Loaded by `ce-brainstorm` when Phase 0.1b classifies the task as non-software (the user wants to explore, decide, or think through something in a non-software domain — naming, narrative, personal decisions, physical-product design, non-digital business strategy).

The **Core Principles and Interaction Rules from `ce-brainstorm/SKILL.md` still apply unchanged** — including one-question-per-turn and the default to the `clarify` tool. This file replaces Phases 0.2–4 with a domain-agnostic flow.

## When to use this

Both conditions must be true:

- None of the software signals (code, repos, APIs, databases, build/modify/debug/deploy) are present
- The task describes something the user wants to explore, decide, or think through in a non-software domain

If only one is true, fall through to the software flow in `SKILL.md`.

## Domain framing (replaces Phase 0.3 scope assessment)

Classify the topic into one of these frames and tailor the dialogue accordingly:

- **Naming** — brand, product, project, code-name. Push for sound + meaning, retire synonyms, suggest domain-fit tests.
- **Narrative / creative writing** — story, copy, positioning, voice. Explore tone, audience, structure.
- **Personal decision** — career, life, tradeoff. Explore values, constraints, reversibility.
- **Non-digital business strategy** — pricing, partnerships, org design, market entry. Explore the crux, the choice, the test.
- **Physical product / craft** — furniture, fashion, food, art. Explore materials, function, aesthetics, intent.

## Execution Flow

### Phase 1: Frame the Decision

Use one or two questions to pin down what kind of decision this is and what would count as a good outcome. Don't ask the user to define the problem in academic terms — let them describe it in their own words, then reflect the frame back.

### Phase 2: Surface Constraints and Preferences

Ask about constraints the user might not mention unprompted: deadlines, audience, reversibility, prior commitments, sensitivities. Use `clarify` single-select for routing, open-ended for substantive answers.

### Phase 3: Generate Options

Generate 3-5 options in the main conversation. For each, name the tradeoff clearly. Don't bury the recommendation — lead with it.

### Phase 4: Test the Options

For each top option, name one test or thought experiment that would tell the user whether this is the right choice. Examples:

- Naming: read the name out loud in three contexts (a headline, a conversation, a search box). Does it still feel right?
- Pricing: would a rational customer pay this without negotiation? If you had to defend the number to a board, what's the line?
- Personal decision: imagine it's six months from now and you made the call. What do you see?

### Phase 5: Write the Artifact

Same as `ce-brainstorm` Phase 3 — write to `docs/brainstorms/<slug>-requirements.{md,html}`. For non-software topics, the frontmatter is simpler:

```yaml
---
title: [Clear decision title]
date: [YYYY-MM-DD]
type: brainstorm
domain: [naming | narrative | personal | business | craft]
status: draft
---
```

Adapt the section structure to the domain:

- **Naming:** Candidate names, retire list, sound + meaning notes, domain-availability notes (if known), recommendation
- **Narrative:** Audience, voice, structure, draft beats, recommendation
- **Personal decision:** Context, options, tradeoffs, reversibility, recommendation
- **Business strategy:** Diagnosis, approach, options, tests, recommendation
- **Physical product / craft:** Function, materials, form, alternatives, recommendation

### Phase 6: Handoff

Same as `ce-brainstorm` Phase 4. The "what's next" menu is the same minus the `plan` option (planning doesn't apply to non-software topics).
