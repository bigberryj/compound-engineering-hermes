---
name: ce-compound
description: "Document a recently solved problem to compound your team's knowledge. Writes a YAML-frontmatted solution doc into docs/solutions/<category>/<slug>.md (bug track or knowledge track), updates CONCEPTS.md with qualifying domain terms, runs an overlap check against existing docs, and surfaces docs/solutions/ in the project's AGENTS.md/CLAUDE.md if it isn't already discoverable. Use when the user says 'document this', 'compound this', 'capture the learning', 'write it up', or after solving a hard problem. The single deliverable is the solution doc; CONCEPTS.md and instruction-file edits are maintenance side effects, not additional artifacts."
argument-hint: "[optional: brief context] [mode:headless] "
version: 1.0.0
author: Hermes Agent (ported from EveryInc/compound-engineering-plugin, MIT)
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [knowledge, documentation, methodology, yml, session-history]
    related_skills: [compound-engineering, ce-compound-refresh, ce-strategy, systematic-debugging, requesting-code-review, session_search]
---

# Compound a Solved Problem (`ce-compound`)

Capture a recently solved problem into a structured solution document so the team doesn't have to rediscover it next time. The single deliverable is `docs/solutions/<category>/<slug>.md`. `CONCEPTS.md` updates and instruction-file discoverability edits are maintenance side effects, not additional deliverables.

**Why "compound"?** Each documented solution compounds your team's knowledge. The first time you solve a problem takes research. Document it, and the next occurrence takes minutes. Knowledge compounds.

## Usage

```
/ce-compound                            # Document the most recent fix
/ce-compound [brief context]            # Provide additional context hint
/ce-compound mode:headless              # Non-interactive run for automations
/ce-compound mode:headless [context]    # Non-interactive run with context hint
```

## Mode Detection

Check arguments for a `mode:headless` token. Tokens starting with `mode:` are flags, not context — strip `mode:headless` from arguments before treating the remainder as the brief context hint.

| Mode | When | Behavior |
|---|---|---|
| **Interactive** (default) | No mode token present | Ask Full vs Lightweight, ask about session history (Full only), prompt for Discoverability Check consent, end with "What's next?" |
| **Headless** | `mode:headless` in arguments | No blocking questions. Run **Full mode without session history**. Apply the Discoverability Check edit silently if a gap exists. Skip Phase 3 specialized reviews. End with a structured terminal report — no "What's next?" menu. |

Headless mode is intended for automations and skill-to-skill invocation where no human is present to answer questions. The doc itself is identical to what an interactive Full run would produce.

## CONCEPTS.md bootstrap requests

If invoked specifically to create or bootstrap `CONCEPTS.md` from scratch rather than to document a solved problem, do not run the normal phases — `ce-compound` populates `CONCEPTS.md` only as a side effect of documenting a real learning (it seeds the *learning's area*, not the whole repo; see Phase 2.4). Repo-wide concept-map creation is `ce-compound-refresh`'s job. Redirect a standalone bootstrap request to `ce-compound-refresh` (which asks whether to build the concept map or run a refresh cycle), then exit.

## Pre-resolved context

**Project root (pre-resolved):** !`git rev-parse --show-toplevel 2>/dev/null || pwd`

If the line above resolved to a directory path, use it as `<project-root>` for all subsequent operations. If it shows the literal backtick command string, resolve at runtime with `git rev-parse --show-toplevel` (falling back to `pwd`).

**Git branch (pre-resolved):** !`git rev-parse --abbrev-ref HEAD 2>/dev/null || true`

If the line above resolved to a plain branch name (like `feat/my-branch`), include it in the `session_search` query in Phase 1 so the search doesn't waste a turn deriving it.

## Support Files

Read these on demand at the step that needs them — do not bulk-load at skill start.

- `references/schema.yaml` — canonical frontmatter fields and enum values (read when validating YAML)
- `references/yaml-schema.md` — category mapping from problem_type to directory (read when classifying)
- `references/concepts-vocabulary.md` — `CONCEPTS.md` format and inclusion rules (read in Phase 2.4 when domain terms surface)
- `assets/resolution-template.md` — section structure for new docs (read when assembling)
- `scripts/validate-frontmatter.py` — frontmatter parser-safety validator (run in Phase 2 step 8)

When spawning subagents, pass the relevant file contents into the task prompt so they have the contract without needing cross-skill paths.

**Note on the shared assets:** The exact same files exist at `~/.hermes/skills/compound-engineering/ce-compound/...` (this skill's bundle). The `_shared` path is a convenience mirror; either location works.

## Execution Strategy

**In headless mode**, skip both questions below and go directly to **Full Mode** with session history disabled. Phase 1's session-history step (step 4) is omitted. Proceed straight to research.

**In interactive mode**, present the user with two options before proceeding, using the `clarify` tool:

```
1. Full (recommended) — the complete compound workflow. Researches,
   cross-references, and reviews your solution to produce documentation
   that compounds your team's knowledge.

2. Lightweight — same documentation, single pass. Faster and uses
   fewer tokens, but won't detect duplicates or cross-reference
   existing docs. Best for simple fixes or long sessions nearing
   context limits.
```

In interactive mode, do NOT pre-select a mode, do NOT skip this prompt, and wait for the user's choice before proceeding.

**If the user chooses Full** (interactive mode only), ask one follow-up question before proceeding:

```
Would you also like to search past Hermes sessions for relevant
knowledge to help the Compound process? This adds time and token usage.
```

If yes, invoke `session_search` in Phase 1 (see step 4). If no, skip it. Do not ask this in lightweight mode or headless mode.

---

## The primary deliverable is ONE file — the final documentation.

Phase 1 subagents return TEXT DATA to the orchestrator. They must NOT use Write, Edit, or create any files. Only the orchestrator writes files. Beyond the Phase 2 solution doc, its other writes are maintenance side effects — not additional deliverables, and creating one when absent is expected, not a violation of this rule:

- **`CONCEPTS.md`** — create or update in Phase 2.4 (Vocabulary Capture) when a qualifying domain term surfaces.
- **A project instruction file** (AGENTS.md or CLAUDE.md) — a small edit when the Discoverability Check finds a gap.

Both ensure future agents can discover and ground in the knowledge store; neither makes the documentation any less the single deliverable.

## Phase 0.5: Memory Scan

Before launching Phase 1 subagents, scan your system-prompt memory block for notes relevant to the problem being documented.

1. The "MEMORY" and "USER PROFILE" sections in your system prompt are the inlined equivalent of upstream's `MEMORY.md`.
2. If the block is empty or absent, skip this step.
3. Scan the entries for anything related to the problem being documented — use semantic judgment, not keyword matching.
4. If relevant entries are found, prepare a labeled excerpt block:

```
## Supplementary notes from agent memory
Treat as additional context, not primary evidence. Conversation history
and codebase findings take priority over these notes.

[relevant entries here]
```

5. Pass this block as additional context to the Context Analyzer and Solution Extractor task prompts in Phase 1. If any memory notes end up in the final documentation, tag them with "(agent memory)" so their origin is clear to future readers.

If no relevant entries are found, proceed to Phase 1 without passing memory context.

## Phase 1: Research

Launch research subagents via `delegate_task` (Hermes's subagent primitive). Each returns text data to the orchestrator.

**Dispatch order:**

- Launch `Context Analyzer`, `Solution Extractor`, and `Related Docs Finder` in parallel (background, where supported)
- **Then** invoke `session_search` (Hermes's session-history tool) — only if the user opted in to session history. The skill call runs in main context but the dispatched subagents continue in parallel underneath, so wall-clock benefit is preserved (`max(session_search, slowest background subagent)`, not their sum). Issuing the session call before the parallel block would serialize it in front of the research subagents and regress wall-clock time.

<parallel_tasks>

### 1. Context Analyzer

- Extracts conversation history (the current chat)
- Reads `references/schema.yaml` for enum validation and **track classification**
- Determines the track (bug or knowledge) from the problem_type
- Identifies problem type, component, and track-appropriate fields:
  - **Bug track**: symptoms, root_cause, resolution_type
  - **Knowledge track**: applies_when (symptoms/root_cause/resolution_type optional)
- Incorporates memory excerpts (if provided by the orchestrator) as supplementary evidence
- Reads `references/yaml-schema.md` for category mapping into `docs/solutions/`
- Suggests a filename using the pattern `[sanitized-problem-slug].md` — no date suffix, even if existing files in the target directory have one; the `date:` frontmatter field is the canonical creation date
- Returns: YAML frontmatter skeleton (must include `category:` field mapped from problem_type), category directory path, suggested filename, and which track applies
- Does not invent enum values, categories, or frontmatter fields from memory; reads the schema and mapping files above
- Does not force bug-track fields onto knowledge-track learnings or vice versa

**Suggested subagent toolsets:** `["file", "terminal"]` — needs `read_file` to load the schema references and the conversation context.

### 2. Solution Extractor

- Reads `references/schema.yaml` for track classification (bug vs knowledge)
- Adapts output structure based on the problem_type track
- Incorporates memory excerpts (if provided by the orchestrator) as supplementary evidence — conversation history and the verified fix take priority; if memory notes contradict the conversation, note the contradiction as cautionary context

**Bug track output sections:**

- **Problem**: 1-2 sentence description of the issue
- **Symptoms**: Observable symptoms (error messages, behavior)
- **What Didn't Work**: Failed investigation attempts and why they failed
- **Solution**: The actual fix with code examples (before/after when applicable)
- **Why This Works**: Root cause explanation and why the solution addresses it
- **Prevention**: Strategies to avoid recurrence, best practices, and test cases. Include concrete code examples where applicable (e.g., gem configurations, test assertions, linting rules)

**Knowledge track output sections:**

- **Context**: What situation, gap, or friction prompted this guidance
- **Guidance**: The practice, pattern, or recommendation with code examples when useful
- **Why This Matters**: Rationale and impact of following or not following this guidance
- **When to Apply**: Conditions or situations where this applies
- **Examples**: Concrete before/after or usage examples showing the practice in action

### 3. Related Docs Finder

- Searches `docs/solutions/` for related documentation
- Identifies cross-references and links
- Finds related GitHub issues (via `gh` CLI when available)
- Flags any related learning or pattern docs that may now be stale, contradicted, or overly broad
- **Assesses overlap** with the new doc being created across five dimensions: problem statement, root cause, solution approach, referenced files, and prevention rules. Score as:
  - **High**: 4-5 dimensions match — essentially the same problem solved again
  - **Moderate**: 2-3 dimensions match — same area but different angle or solution
  - **Low**: 0-1 dimensions match — related but distinct
- Returns: Links, relationships, refresh candidates, and overlap assessment (score + which dimensions matched)

**Search strategy (grep-first filtering for efficiency):**

1. Extract keywords from the problem context: module names, technical terms, error messages, component types
2. If the problem category is clear, narrow search to the matching `docs/solutions/<category>/` directory
3. Use the platform's content-search tool (`search_files target=content` in Hermes) to pre-filter candidate files BEFORE reading any content. Run multiple searches in parallel, case-insensitive, targeting frontmatter fields.
4. If search returns >25 candidates, re-run with more specific patterns. If <3, broaden to full content search
5. Read only frontmatter (first 30 lines) of candidate files to score relevance
6. Fully read only strong/moderate matches
7. Return distilled links and relationships, not raw file contents

**GitHub issue search:**

Prefer the `gh` CLI for searching related issues: `gh issue list --search "<keywords>" --state all --limit 5`. If `gh` is not installed, skip GitHub issue search and note it was skipped in the output.

</parallel_tasks>

### 4. Session History via `session_search` (only if the user opted in)

- **Skip entirely** if the user declined session history in the follow-up question, if running in lightweight mode, or if running in headless mode.
- **Hermes adaptation:** Upstream has this as a sub-skill (`ce-sessions`). In Hermes, the orchestrator calls `session_search` directly.

**Search call shape (keep tight — long payloads cause the search to widen):**

```
session_search(
  query="<problem topic — one sentence naming the concrete issue, error message, module name>",
  limit=5,
  sort="newest"
)
```

- **Time window:** recent (default). Override with `session_search` time filters if the problem clearly spans a longer arc.
- **Filter rule:** Focus on findings directly relevant to the specific problem. Ignore unrelated work from the same sessions.

**Output the findings in a labeled block:**

```
## Session history findings
- What was tried before
- What didn't work
- Key decisions
- Related context
```

A "no relevant prior sessions" return is still a valid input; the documentation gets written without session context.

## Phase 2: Assembly & Write

**WAIT for all Phase 1 inputs to complete before proceeding** — the three parallel subagents and, when the user opted in, the synchronous `session_search` call.

The orchestrating agent (main conversation) performs these steps:

1. Collect all text results from Phase 1 subagents
2. **Check the overlap assessment** from the Related Docs Finder before deciding what to write:

   | Overlap | Action |
   |---------|--------|
   | **High** — existing doc covers the same problem, root cause, and solution | **Update the existing doc** with fresher context (new code examples, updated references, additional prevention tips) rather than creating a duplicate. The existing doc's path and structure stay the same. |
   | **Moderate** — same problem area but different angle, root cause, or solution | **Create the new doc** normally. Flag the overlap for Phase 2.5 to recommend consolidation review. |
   | **Low or none** | **Create the new doc** normally. |

   The reason to update rather than create: two docs describing the same problem and solution will inevitably drift apart. The newer context is fresher and more trustworthy, so fold it into the existing doc rather than creating a second one that immediately needs consolidation.

   When updating an existing doc, preserve its file path and frontmatter structure. Update the solution, code examples, prevention tips, and any stale references. Add a `last_updated: YYYY-MM-DD` field to the frontmatter. Do not change the title unless the problem framing has materially shifted.

3. **Incorporate session history findings** (if available). When `session_search` returned relevant prior-session context:
   - Fold investigation dead ends and failed approaches into the **What Didn't Work** section (bug track) or **Context** section (knowledge track)
   - Use cross-session patterns to enrich the **Prevention** or **Why This Matters** sections
   - Tag session-sourced content with "(session history)" so its origin is clear to future readers
   - If findings are thin or "no relevant prior sessions," proceed without session context
4. Assemble complete markdown file from the collected pieces, reading `assets/resolution-template.md` for the section structure of new docs
5. Validate YAML frontmatter against `references/schema.yaml`, including the YAML-safety quoting rule for array items (see `references/yaml-schema.md` > YAML Safety Rules)
6. Create directory if needed: `mkdir -p docs/solutions/<category>/`
7. Write the file: either the updated existing doc or the new `docs/solutions/<category>/<filename>.md`
8. **Validate parser-safety of the written frontmatter** to catch silent-corruption issues the prose rules miss: malformed `---` delimiter lines, unquoted ` #` in scalar values (silent comment truncation), and unquoted `: ` in scalar values (silent mapping confusion).

   **Run the bundled validator with the resolved path:**

   ```bash
   python3 ~/.hermes/skills/compound-engineering/ce-compound/scripts/validate-frontmatter.py <output-path>
   ```

   The path is resolved absolutely (Hermes's `~/.hermes` rather than the upstream `${CLAUDE_SKILL_DIR}` env var, which Hermes does not set).

   - **If the script ran:** exit 0 means parser-safe; exit 1 means stderr names the offending field(s) — quote the value(s), re-write the doc, and re-run until exit 0. Do not declare success while validation fails.
   - **If the script did not run** (e.g., Python missing): apply the validator's checks by hand, matching its exact scope — checking more broadly risks edits the validator would not require. Fix any violation by quoting the whole value before continuing:
     1. The opening and closing frontmatter delimiters are each a line whose content is `---` (trailing whitespace is fine; `----` or `---extra` is not a valid delimiter).
     2. For each **top-level** mapping entry (`key: value`, no leading indentation) whose value is **not already quoted or structured** (does not start with `"`, `'`, `[`, `{`, `|`, or `>`): the value must contain no unquoted ` #` (space-then-hash — YAML treats it as a comment and silently truncates) and no unquoted `: ` (colon-then-space — strict YAML may read it as a nested mapping). Quote the whole value if either appears.

     Nested values, array items, and already-quoted values are out of scope here (array-item quoting is handled by the schema/YAML-safety step above). Then state in the completion output that the bundled script validator was unavailable on this platform and the checks were applied manually.

When creating a new doc, preserve the section order from `assets/resolution-template.md` unless the user explicitly asks for a different structure.

### Phase 2.4: Vocabulary Capture

**First, read `references/concepts-vocabulary.md`.** This is unconditional. Do not pre-judge from memory that nothing qualifies — the reference's criteria are non-obvious and qualifying terms often live in the surrounding conversation rather than the new doc itself. Reading the reference is what makes the rest of the phase possible.

Then, applying those criteria, scan the new doc **and** the surrounding conversation for qualifying domain terms. If `CONCEPTS.md` exists at repo root, add missing qualifying terms and refine existing entries when new precision surfaced. If it does not exist and at least one qualifying term surfaced, create it.

**Seed the learning's area at creation — don't write a lone term.** When `CONCEPTS.md` does not yet exist, alongside the surfaced term also seed the core domain nouns of the area this learning touched, following the **Seed goal** and **Scope of a seed** rules in `references/concepts-vocabulary.md`. The seed is scoped to the learning's area (the modules and domain the fix touched) and defines only terms investigated here — it does not reach for repo-wide nouns. This anchors the surfaced term so it does not dangle against undefined siblings. A repo-wide concept map is `ce-compound-refresh`'s bootstrap path, not this one.

**At creation, hold the qualifying bar conservatively for borderline terms.** A borderline term, or a class/table/file name dressed up as an entity, defers to a later run — clear core nouns are seeded, borderline ones wait.

**When bootstrapping the file, start with this preamble under the `# Concepts` heading**, then add the qualifying entries below it:

> Shared domain vocabulary for this project — entities, named processes, and status concepts with project-specific meaning. Seeded with core domain vocabulary, then accretes as ce-compound and ce-compound-refresh process learnings; direct edits are fine. Glossary only, not a spec or catch-all.

**Refresh the coherence neighborhood of any entry you touch.** When adding or editing an entry, also inspect its *coherence neighborhood* — its cluster siblings and the terms it cross-references or that reference it. Within that neighborhood, do two things: fix glossary violations (implementation specifics — file paths, class names, function signatures, current-config values), and refresh entries the learning's own evidence shows have drifted. Bounds: neighborhood only, never a full-file audit; refresh only on evidence already in hand; if judging a neighbor would require investigation this learning did not do, flag it for `ce-compound-refresh` rather than editing on a guess. The test: after the edit, would a reader find the touched entry's siblings or referenced terms inconsistent with it? Broader audit is `ce-compound-refresh`'s job.

If no terms qualified after applying the reference's criteria, record that outcome explicitly in the success output (e.g., "Vocabulary capture: scanned, no qualifying terms"). Do not silently skip — the visible scan-and-no-result record is the audit signal that the reference was consulted.

**Apply edits silently in every mode — no user prompt in interactive, lightweight, or headless.** Vocabulary capture is a side effect of compounding, not a decision the user makes per run.

### Phase 2.5: Selective Refresh Check

After writing the new learning, decide whether this new solution is evidence that older docs should be refreshed.

`ce-compound-refresh` is **not** a default follow-up. Use it selectively when the new learning suggests an older learning or pattern doc may now be inaccurate.

It makes sense to invoke `ce-compound-refresh` when one or more of these are true:

1. A related learning or pattern doc recommends an approach that the new fix now contradicts
2. The new fix clearly supersedes an older documented solution
3. The current work involved a refactor, migration, rename, or dependency upgrade that likely invalidated references in older docs
4. A pattern doc now looks overly broad, outdated, or no longer supported by the refreshed reality
5. The Related Docs Finder surfaced high-confidence refresh candidates in the same problem space
6. The Related Docs Finder reported **moderate overlap** with an existing doc — there may be consolidation opportunities that benefit from a focused review

It does **not** make sense to invoke `ce-compound-refresh` when:

1. No related docs were found
2. Related docs still appear consistent with the new learning
3. The overlap is superficial and does not change prior guidance
4. Refresh would require a broad historical review with weak evidence

Use these rules:

- If there is **one obvious stale candidate**, invoke `ce-compound-refresh` with a narrow scope hint after the new learning is written
- If there are **multiple candidates in the same area**, ask the user whether to run a targeted refresh for that module, category, or pattern set
- If context is already tight or you are in lightweight mode, do not expand into a broad refresh automatically; instead recommend `ce-compound-refresh` as the next step with a scope hint
- **In headless mode**, never invoke `ce-compound-refresh` and never ask the user. Surface the recommended scope hint in the terminal report's "Refresh recommendation" line and let the caller decide

When invoking or recommending `ce-compound-refresh`, be explicit about the argument to pass. Prefer the narrowest useful scope:

- Specific file when one learning or pattern doc is the likely stale artifact
- Module or component name when several related docs may need review
- Category name when the drift is concentrated in one solutions area
- Pattern filename or pattern topic when the stale guidance lives in `docs/solutions/patterns/`

Do not invoke `ce-compound-refresh` without an argument unless the user explicitly wants a broad sweep.

Always capture the new learning first. Refresh is a targeted maintenance follow-up, not a prerequisite for documentation.

### Discoverability Check

After the learning is written and the refresh decision is made, check whether the project's instruction files would lead an agent to discover and search `docs/solutions/` before starting work in a documented area. This runs every time — the knowledge store only compounds value when agents can find it.

1. Identify which root-level instruction files exist (AGENTS.md, CLAUDE.md, or both). Read the file(s) and determine which holds the substantive content — one file may just be a shim that `@`-includes the other (e.g., `CLAUDE.md` containing only `@AGENTS.md`, or vice versa). The substantive file is the assessment and edit target; ignore shims. If neither file exists, skip this check entirely.
2. Assess whether an agent reading the instruction files would learn three things:
   - That a searchable knowledge store of documented solutions exists
   - Enough about its structure to search effectively (category organization, YAML frontmatter fields like `module`, `tags`, `problem_type`)
   - When to search it (before implementing features, debugging issues, or making decisions in documented areas — learnings may cover bugs, best practices, workflow patterns, or other institutional knowledge)

   This is a semantic assessment, not a string match. The information could be a line in an architecture section, a bullet in a gotchas section, spread across multiple places, or expressed without ever using the exact path `docs/solutions/`. Use judgment — if an agent would reasonably discover and use the knowledge store after reading the file, the check passes.

3. If the spirit is already met, no action needed — move on.
4. If not:
   a. Based on the file's existing structure, tone, and density, identify where a mention fits naturally. Before creating a new section, check whether the information could be a single line in the closest related section — an architecture tree, a directory listing, a documentation section, or a conventions block. A line added to an existing section is almost always better than a new headed section. Only add a new section as a last resort when the file has clear sectioned structure and nothing is even remotely related.
   b. Draft the smallest addition that communicates the three things. Match the file's existing style and density. The addition should describe the knowledge store itself, not the plugin — an agent without the plugin should still find value in it.

      Keep the tone informational, not imperative. Express timing as description, not instruction — "relevant when implementing or debugging in documented areas" rather than "check before implementing or debugging."

      Examples of calibration (not templates — adapt to the file):

      When there's an existing directory listing or architecture section — add a line:
      ```
      docs/solutions/  # documented solutions to past problems (bugs, best practices, workflow patterns), organized by category with YAML frontmatter (module, tags, problem_type)
      ```

      When nothing in the file is a natural fit — a small headed section is appropriate:
      ```
      ## Documented Solutions

      `docs/solutions/` — documented solutions to past problems (bugs, best practices, workflow patterns), organized by category with YAML frontmatter (`module`, `tags`, `problem_type`). Relevant when implementing or debugging in documented areas.
      ```
   c. In full interactive mode, explain to the user why this matters — agents working in this repo (including fresh sessions, other tools, or collaborators without the plugin) won't know to check `docs/solutions/` unless the instruction file surfaces it. Show the proposed change and where it would go, then use `clarify` to get consent before making the edit. In lightweight mode, output a one-liner note and move on. In headless mode, apply the edit directly without prompting and surface it in the terminal report under "Instruction-file edit"

5. **If `CONCEPTS.md` exists at repo root, run a parallel discoverability check for it.** Assess whether the instruction file would lead an agent to discover the project's shared domain vocabulary. Use the same workflow as the `docs/solutions/` check above: same target file, same edit-placement judgment, same consent-then-edit interaction shape per mode. A line in an existing section is almost always better than a new headed section. Example calibration when nothing else fits:

   ```
   CONCEPTS.md  # shared domain vocabulary (entities, named processes, status concepts) — relevant when orienting to the codebase or discussing domain concepts
   ```

   **Skip this step entirely if `CONCEPTS.md` does not exist** — never nag for an artifact the project has not adopted. When skipped, this step produces no output and no edit.

## Phase 3: Optional Enhancement

**WAIT for Phase 2 to complete before proceeding.**

**Skip Phase 3 entirely in headless mode** to bound token usage — the caller does not have a human-in-the-loop to act on reviewer findings, and downstream automations can run specialized reviewers themselves if they want that pass.

<parallel_tasks>

Based on problem type, optionally invoke specialized agents to review the documentation:

- **performance_issue** → `delegate_task` goal: validate query optimization approach
- **security_issue** → `delegate_task` goal: review solution for vulnerabilities
- **database_issue** → `delegate_task` goal: review migrations and queries for data integrity
- Any code-heavy issue → always run a code-simplicity reviewer for minimal, clear examples.

Each review agent should receive the new doc and the relevant `schema.yaml` + `resolution-template.md` so it can flag violations.

</parallel_tasks>

---

## Lightweight Mode

**Single-pass alternative — same documentation, fewer tokens.**

This mode skips parallel subagents entirely. The orchestrator performs all work in a single pass, producing the same solution document without cross-referencing or duplicate detection.

Headless mode forces Full and does not enter Lightweight — automations get the cross-reference and overlap detection benefits without the interactive overhead.

The orchestrator (main conversation) performs ALL of the following in one sequential pass:

1. **Extract from conversation**: Identify the problem and solution from conversation history. Also scan the system-prompt memory block, if present — use any relevant notes as supplementary context alongside conversation history. Tag any memory-sourced content incorporated into the final doc with "(agent memory)"
2. **Classify**: Read `references/schema.yaml` and `references/yaml-schema.md`, then determine track (bug vs knowledge), category, and filename
3. **Write minimal doc**: Create `docs/solutions/<category>/<filename>.md` using the appropriate track template from `assets/resolution-template.md`, with:
   - YAML frontmatter with track-appropriate fields, applying the YAML-safety quoting rule for array items (see `references/yaml-schema.md` > YAML Safety Rules)
   - Bug track: Problem, root cause, solution with key code snippets, one prevention tip
   - Knowledge track: Context, guidance with key examples, one applicability note
4. **Vocabulary capture (update-only)**: if `CONCEPTS.md` exists at repo root, read `references/concepts-vocabulary.md`, then scan the new doc and the conversation for qualifying terms and add/refine entries silently (same criteria as Phase 2.4). Do **not** bootstrap or seed in lightweight mode — if `CONCEPTS.md` does not exist, defer creation to a Full run, which owns seeding. Record the outcome in the output (e.g., "Vocabulary: 1 entry refined" or "scanned, no qualifying terms"). If you refined `CONCEPTS.md` and a quick read of `AGENTS.md`/`CLAUDE.md` shows it isn't surfaced there, add the discoverability tip to the output below — lightweight **tips**, it does not edit instruction files (a Full run owns that edit).
5. **Skip specialized agent reviews** (Phase 3) to conserve context

**Lightweight output:**

```
✓ Documentation complete (lightweight mode)

File created:
- docs/solutions/<category>/<filename>.md

[If discoverability check found instruction files don't surface the knowledge store:]
Tip: Your AGENTS.md/CLAUDE.md doesn't surface docs/solutions/ to agents —
a brief mention helps all agents discover these learnings.

[If CONCEPTS.md was refined this run and isn't surfaced in the instruction files:]
Tip: Your AGENTS.md/CLAUDE.md doesn't surface CONCEPTS.md —
a one-line mention helps agents find the shared vocabulary.

Note: This was created in lightweight mode. For richer documentation
(cross-references, detailed prevention strategies, specialized reviews),
re-run /ce-compound in a fresh session.
```

**No subagents are launched. No parallel tasks. The solution doc is the one deliverable** (Phase 2.4's update-only vocabulary capture may also refine an existing `CONCEPTS.md`).

In lightweight mode, the overlap check is skipped (no Related Docs Finder subagent). This means lightweight mode may create a doc that overlaps with an existing one. That is acceptable — `ce-compound-refresh` will catch it later. Only suggest `ce-compound-refresh` if there is an obvious narrow refresh target. Do not broaden into a large refresh sweep from a lightweight session.

---

## What It Captures

- **Problem symptom**: Exact error messages, observable behavior
- **Investigation steps tried**: What didn't work and why
- **Root cause analysis**: Technical explanation
- **Working solution**: Step-by-step fix with code examples
- **Prevention strategies**: How to avoid in future
- **Cross-references**: Links to related issues and docs

## Preconditions

- Problem has been solved (not in-progress)
- Solution has been verified working
- Non-trivial problem (not simple typo or obvious error)

## What It Creates

**Organized documentation:**

- File: `docs/solutions/<category>/<filename>.md`

**Categories auto-detected from problem:**

Bug track:
- build-errors/
- test-failures/
- runtime-errors/
- performance-issues/
- database-issues/
- security-issues/
- ui-bugs/
- integration-issues/
- logic-errors/

Knowledge track:
- architecture-patterns/ — architectural or structural patterns (agent/skill/pipeline/workflow shape decisions)
- design-patterns/ — reusable non-architectural design approaches (content generation, interaction patterns, prompt shapes)
- tooling-decisions/ — language, library, or tool choices with durable rationale
- conventions/ — team-agreed way of doing something, captured so it survives turnover
- workflow-issues/
- developer-experience/
- documentation-gaps/
- best-practices/ — fallback only, use when no narrower knowledge-track value applies

## Common Mistakes to Avoid

| ❌ Wrong | ✅ Correct |
|---|---|
| Subagents write files like `context-analysis.md`, `solution-draft.md` | Subagents return text data; orchestrator writes one final file |
| Research and assembly run in parallel | Research completes → then assembly runs |
| Multiple files created during workflow | One solution doc written or updated: `docs/solutions/<category>/<filename>.md` (plus optional maintenance writes: a `CONCEPTS.md` create/update from Phase 2.4 and a small instruction-file edit for discoverability) |
| Creating a new doc when an existing doc covers the same problem | Check overlap assessment; update the existing doc when overlap is high |

## Success Output

### Headless mode

Emit a structured terminal report and end the turn. No "What's next?" question, no blocking prompt. End with `Documentation complete` as the terminal signal so callers can detect completion.

```
✓ Documentation complete (headless mode)

File: docs/solutions/<category>/<filename>.md  (created | updated)
Track: <bug | knowledge>
Category: <category>
Overlap: <none | low | moderate — see <path> | high — existing doc updated>
Instruction-file edit: <none needed | applied to <path> | gap noted, not applied>
CONCEPTS.md: <scanned, no qualifying terms | created with N entries (M seeded from the learning's area) | updated — N added, N refined>
Refresh recommendation: <none | scope hint for /ce-compound-refresh>

Documentation complete
```

When no doc was written (e.g., headless invoked on a session where the problem is not yet solved), emit a structured failure instead and end with `Documentation skipped`:

```
✗ Documentation skipped (headless mode)

Reason: <one-sentence explanation — e.g., "no solved problem detected in
conversation history" or "solution not yet verified">

Documentation skipped
```

### Interactive mode

```
✓ Documentation complete

[Memory: N relevant entries used as supplementary evidence]

Subagent Results:
  ✓ Context Analyzer: Identified <problem_type> in <module>, category: <category>/
  ✓ Solution Extractor: <N> code fixes, prevention strategies
  ✓ Related Docs Finder: <N> related issues
  ✓ Session History: <N> prior sessions on same branch, <N> failed approaches surfaced

Specialized Agent Reviews (Auto-Triggered):
  ✓ <reviewer>: <one-line summary>

Files written:
- docs/solutions/<category>/<slug>.md (created)
- CONCEPTS.md (created with N entries: <list>)

This documentation will be searchable for future reference when similar
issues occur in the <module> module.

What's next?
1. Continue workflow (recommended)
2. Link related documentation
3. Update other references
4. View documentation
5. Other
```

**After displaying the interactive success output above, present the "What's next?" options using the `clarify` tool.**

**Alternate interactive output (when updating an existing doc due to high overlap):**

```
✓ Documentation updated (existing doc refreshed with current context)

Overlap detected: docs/solutions/<category>/<existing>.md
  Matched dimensions: problem statement, root cause, solution, referenced files
  Action: Updated existing doc with fresher code examples and prevention tips

File updated:
- docs/solutions/<category>/<existing>.md (added last_updated: 2026-06-15)
```

## The Compounding Philosophy

This creates a compounding knowledge system:

1. First time you solve "N+1 query in brief generation" → Research (30 min)
2. Document the solution → `docs/solutions/performance-issues/n-plus-one-briefs.md` (5 min)
3. Next time similar issue occurs → Quick lookup (2 min)
4. Knowledge compounds → Team gets smarter

The feedback loop:

```
Build → Test → Find Issue → Research → Improve → Document → Validate → Deploy
    ↑                                                                      ↓
    └──────────────────────────────────────────────────────────────────────┘
```

**Each unit of engineering work should make subsequent units of work easier — not harder.**

## Related Commands

- `ce-strategy` — strategy anchor that grounds this skill
- `ce-compound-refresh` — maintenance: refresh stale docs in this knowledge store
- `plan` (Hermes built-in) — references documented solutions during planning
