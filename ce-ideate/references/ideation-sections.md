# Ideation Sections (Reference)

Loaded by `ce-ideate` at Phase 4 to assemble the ideation artifact.

## Section order (markdown)

```markdown
---
title: [Clear, descriptive title — the topic + "ideation"]
date: [YYYY-MM-DD]
type: ideation
status: draft
subject: [the subject of ideation, 1 sentence]
frames: [list of frames run, e.g. "direct, adjacent, pain-point, persona, constraint, cross-domain"]
survivors: [N]
total_considered: [N]
---

# [Title]

## Subject

[1-2 sentences restating the subject and any focus hint applied.]

## Frames run

[Bullet list of the frames that produced ideas. Frame names match the SKILL.md Phase 2 list.]

## Top ideas

[For each top 5-7 survivor, one section:]

### [Idea name]

[1-2 sentence description of the idea.]

**Why it survived:** [the one-line reason it made the cut]

**Basis:** [1-2 lines citing the grounding that supports it — file:line if codebase-grounded, otherwise the source]

**Tradeoff:** [the cost or risk of pursuing this idea]

## Honorable mentions

[Brief list of ideas that just missed the top cut but were worth generating. One line each. The point is to show the work, not to second-guess the ranking.]

## Rejection summary

[Grouped by rejection reason. The point is to show the discipline, not to re-litigate.]

- **Weak basis** (N ideas): [one-line example of why this category]
- **Conflicts with strategy** (N ideas): [one-line example]
- **Out of scope for the focus** (N ideas): [one-line example]
- **Already covered by an existing solution doc** (N ideas): [one-line example]

## Grounding

[Source list — what Phase 1 produced that the ideas were checked against. Bullet list of files / URLs / research artifacts.]

## What's next

[Pointer to the post-ideation menu — picked up by the orchestrator in Phase 5.]
```

## Frontmatter (HTML)

Same shape, but emitted inside a `<script type="application/json">` block in the HTML head. Section content is the same; rendering differs.

## Rules

- All file references in the doc must be repo-relative paths
- Set `date` to today's ISO date (YYYY-MM-DD)
- Top ideas: 5-7, not 10. Quality matters more than completeness here.
- Rejection summary is required, not optional — the discipline of explicit rejection is what makes the survivors trustworthy
- Grounding list is required — every top idea should have a basis you can trace

## Post-write checklist

- [ ] Frontmatter present
- [ ] `date` is today in ISO format
- [ ] Top ideas section has 5-7 entries
- [ ] Every top idea has a basis line
- [ ] Rejection summary is present and grouped by reason
- [ ] No absolute paths in the doc
