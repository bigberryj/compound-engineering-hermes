# Requirements Document Template

Loaded by `ce-brainstorm` at Phase 2. Fill it in and write to `docs/brainstorms/<slug>-requirements.md`.

## Rules

- Use the user's own language where possible. Do not paraphrase into generic PM-speak.
- Each section stays compact. The whole doc should read in under 10 minutes.
- Required sections are the minimum. Optional sections only if they earn their keep.
- All file references in the doc must be repo-relative paths (e.g., `src/models/user.rb`).
- Set `date` in the YAML frontmatter to today's ISO date (YYYY-MM-DD).

## Frontmatter (markdown)

```yaml
---
title: [Clear feature/decision title]
date: [YYYY-MM-DD]
type: requirements
status: draft
scope: [lightweight | standard | deep-feature | deep-product]
---
```

## Sections (Standard / Deep — feature tier)

```markdown
# [Title]

## Summary

[1-2 sentence summary of the feature and the user value. The "what and why" in two lines.]

## Problem

[What is happening today that this feature fixes? The user pain, the gap, the cost of not fixing it. 1-3 sentences.]

## Goals

- [Primary outcome the user gets]
- [Secondary outcome]
- [Tertiary, if any]

## Non-goals

- [What is explicitly out of scope for this brainstorm / first version]

## Users

**Primary:** [Persona + situation, one sentence each]

## User-facing behavior

- [What the user does, what they see, what they get]
- [Step-by-step for the primary flow, if it has shape]

## Success criteria

- [How the team will know the feature worked]
- [Measurable signals where possible]
- [Mix leading and lagging indicators]

## Open questions

- [Question 1 that the planner will need to answer]
- [Question 2]
- [Question 3]

## References

- [Related docs, code paths, decisions — all repo-relative]
- [STRATEGY.md section if this anchors to a track]
- [Existing related learnings from docs/solutions/]

## Conversation log

[Optional: brief log of the dialogue moves, useful for handoff to the planner. Skip if the dialogue was short.]
```

## Sections (Lightweight)

```markdown
# [Title]

## What

[2-3 sentences: the feature, the user, the value.]

## Why

[1-2 sentences: the gap being filled, the cost of not filling it.]

## Acceptance

- [Acceptance criterion 1]
- [Acceptance criterion 2]
- [Acceptance criterion 3]
```

## Sections (Deep — product tier)

Adds to Standard/Deep-feature:

```markdown
## Product shape

[Primary actors, core outcome, positioning, primary end-to-end flow. Only present in product-tier brainstorms.]

## Adjacent / deferred

[Areas this could expand into that we are deliberately not tackling in this brainstorm. Naming them keeps the conversation honest about scope.]
```

## YAML safety

Array items starting with reserved indicator characters (`` ` ``, `[`, `*`, `&`, `!`, `|`, `>`, `%`, `@`, `?`) or containing `": "` must be wrapped in double quotes. See `~/.hermes/skills/compound-engineering/ce-compound/references/yaml-schema.md` for the full quoting rules.

## Post-write checklist

- [ ] Frontmatter present at the top
- [ ] `date` is today in ISO format
- [ ] No absolute paths anywhere in the doc — all repo-relative
- [ ] All required sections are present for the chosen scope
- [ ] At least one Goals item is a measurable outcome, not a feature description
- [ ] Open questions are real questions, not "TBD" placeholders
