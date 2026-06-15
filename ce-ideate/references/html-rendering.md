# HTML Rendering for `ce-ideate`

Use this when `OUTPUT_FORMAT=html` for the ideation artifact. Set `ideate_output: html` in `.compound-engineering/config.local.yaml` or pass `output:html` to the skill.

This file is a placeholder. The default Hermes port of `ce-ideate` writes markdown. If you want the upstream HTML rendering rules (rich self-contained HTML with embedded styles and optional diagrams for the top candidates), the source is at:

`https://github.com/EveryInc/compound-engineering-plugin/tree/main/plugins/compound-engineering/skills/ce-ideate/references/html-rendering.md`

Pull that file and place it at:

`~/.hermes/skills/compound-engineering/ce-ideate/references/html-rendering.md`

…then update the assembly code in `SKILL.md` Phase 4 to load and apply it. Until then, `output:html` falls back to markdown with a one-line note in the chat output.
