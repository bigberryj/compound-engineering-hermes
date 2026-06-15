# Compound Engineering bundle (port for Hermes)

A port of [EveryInc/compound-engineering](https://github.com/EveryInc/compound-engineering) (the methodology + companion plugin, MIT licensed) for use as a set of Hermes skills. ~296K, 8 skills, 21K+ words of methodology, no LLM required for the core loop.

## What it does

Compound engineering is a methodology: solve a hard problem → write a solution doc → use it as raw material for the next problem. The bundle turns this into a set of skills you load into an agent:

- `compound-engineering` — entry point, methodology, routing table
- `ce-strategy` — generate a STRATEGY.md (good strategy / bad strategy framework)
- `ce-brainstorm` — vague idea → requirements doc (lightweight/standard/deep)
- `ce-ideate` — generate + critique ideas before brainstorming
- `ce-compound` — the core: solution doc + CONCEPTS.md + discoverability check + overlap detection
- `ce-compound-refresh` — maintenance: Keep/Update/Consolidate/Replace/Delete
- `ce-product-pulse` — time-windowed usage/quality/error report
- `ce-setup` — environment diagnostic (disable-invocation, user-only)

## Install

This bundle is meant to live at `~/.hermes/skills/compound-engineering/`. The skills are discovered automatically by Hermes at session start.

```bash
# Clone
git clone https://github.com/bigberryj/compound-engineering-hermes.git
cd compound-engineering-hermes

# Install (creates ~/.hermes/skills/compound-engineering/ as a symlink to this checkout)
./install.sh
```

## Verify

```bash
bash ~/.hermes/skills/compound-engineering/ce-setup/scripts/check-health.sh
```

Should report: `Bundle healthy. All 8 skills present.`

## Use

In a chat with your agent, just say:

- *"Set up the compound engineering loop for this project"* → `ce-setup` + `ce-strategy`
- *"Brainstorm this"* / *"Let's brainstorm"* → `ce-brainstorm`
- *"Compound this"* / *"Document this problem we just fixed"* → `ce-compound`
- *"Refresh the docs in docs/solutions"* → `ce-compound-refresh`
- *"Give me a product pulse for last week"* → `ce-product-pulse`

## What's different from upstream

The upstream compound-engineering-plugin is a Claude Code plugin (~30 commands + ~30 vertical/framework skills). This port:

- Replaces `AskUserQuestion` with `clarify` (Hermes equivalent)
- Replaces `Skill` with `skill_view` (Hermes equivalent)
- Replaces `Task` / `Agent` with `delegate_task` (Hermes equivalent)
- Replaces `ce-sessions` (custom command) with `session_search` (Hermes built-in)
- Resolves all path variables to absolute `~/.hermes` paths
- Drops the 30 vertical/framework skills (Rails, Xcode, iOS, Slack, etc.) — they're Claude Code specific
- Uses stdlib Python for `validate-frontmatter.py` (upstream uses Node)

Everything else (methodology, prompts, schema, decision trees) is faithful to the original.

## License

MIT — see [LICENSE](LICENSE). Original methodology copyright Every Inc.
