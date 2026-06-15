# Markdown Rendering for `ce-ideate`

Use this when `OUTPUT_FORMAT=md` for the ideation artifact. The default Hermes port is markdown; load this only when assembling the doc.

## Format rules

- The artifact is a single `.md` file with YAML frontmatter
- Use `#`, `##`, `###` for headings (no custom anchors, no emoji decoration)
- Code blocks (```) for any code sample, command, or file path
- Use `-` for bullets, not `*`
- Tables only when the comparison genuinely fits a table — when in doubt, use bullets
- Section order follows `references/ideation-sections.md` exactly

## Frontmatter quoting

The frontmatter is the same as the markdown version. Use double quotes for any value that:

- starts with a backtick, `[`, `*`, `&`, `!`, `|`, `>`, `%`, `@`, or `?`
- contains ` #` (space then hash) — silent comment truncation
- contains `: ` (colon then space) — silent mapping confusion

## What to avoid

- No inline HTML
- No embedded images
- No external CSS or JS
- No tables wider than 5 columns
- No emoji in headings or section titles

The doc is meant to be diffable, greppable, and readable in any text tool. If a richer rendering is needed, the user can request `output:html` for the HTML version.
