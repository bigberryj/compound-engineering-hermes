---
name: ce-setup
description: "Diagnose and configure the compound-engineering environment for this machine. Checks CLI dependencies, the skills bundle, and the repo-local config. Offers guided installation for missing tools. Use when troubleshooting missing skills, verifying setup, or before onboarding a new repo to compound engineering."
disable-invocation: true
version: 1.0.0
author: Hermes Agent (ported from EveryInc/compound-engineering-plugin, MIT)
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [setup, diagnostic, health-check, onboarding]
    related_skills: [compound-engineering, ce-strategy, ce-compound, ce-product-pulse]
---

# Compound Engineering Setup (`ce-setup`)

User-invoked diagnostic for the compound-engineering environment. Checks CLI dependencies, the skills bundle on disk, and the repo-local CE config. Offers guided installation for missing pieces. The agent should NOT auto-load this skill — it's a user-invoked tool.

## Interaction Method

Use `clarify` for each question. Never silently skip or auto-configure. For multiSelect questions, accept comma-separated numbers (e.g. `1, 3`).

Interactive setup for compound-engineering — diagnoses environment health, cleans obsolete repo-local CE config, and helps configure required tools.

## Phase 1: Diagnose

### Step 1: Determine Plugin Version

Detect the installed compound-engineering bundle version by reading the `version` field in `~/.hermes/skills/compound-engineering/SKILL.md`. This is platform-specific — use `read_file` on that path. If the version cannot be determined, skip this step.

If a version is found, pass it to the check script via `--version`. Otherwise omit the flag.

### Step 2: Run the Health Check Script

Before running the script, display: "Compound Engineering — checking your environment..."

Run the bundled check script. Do not perform manual dependency checks — the script handles all CLI tools, skill presence, repo-local CE file checks, and `.gitignore` guidance in one pass.

```bash
bash ~/.hermes/skills/compound-engineering/ce-setup/scripts/check-health.sh --version <VERSION>
```

Or without version if Step 1 could not determine it:

```bash
bash ~/.hermes/skills/compound-engineering/ce-setup/scripts/check-health.sh
```

Script reference: `scripts/check-health.sh`

Display the script's output to the user.

### Step 3: Evaluate Results

After the diagnostic report, check whether:

- any CLI tools are missing (reported as yellow in the Tools section)
- any agent skills are missing (reported as yellow in the Skills section)
- `compound-engineering.local.md` is present at the repo root and needs cleanup
- `.compound-engineering/config.local.yaml` does not exist or is not safely gitignored
- `.compound-engineering/config.local.example.yaml` is missing or outdated

If everything is installed, no repo-local cleanup is needed, and `.compound-engineering/config.local.yaml` already exists and is gitignored, display the tool and skill list and completion message. Parse the tool and skill names from the script output and list each with a green circle.

```
✅ Compound Engineering setup complete

   Tools:  🟢 gh  🟢 jq
   Skills: 🟢 compound-engineering  🟢 ce-strategy  🟢 ce-compound  🟢 ce-product-pulse
   Config: ✅

   Run /ce-setup anytime to re-check.
```

Stop here.

Otherwise proceed to Phase 2 to resolve any issues. Handle repo-local cleanup (Step 4) first, then config bootstrapping (Step 5), then missing dependencies (Step 6).

## Phase 2: Fix

### Step 4: Resolve Repo-Local CE Issues

Resolve the repository root with `git rev-parse --show-toplevel` (fall back to `pwd`). If `compound-engineering.local.md` exists at the repo root, explain that it is obsolete because review-agent selection is automatic and CE now uses `.compound-engineering/config.local.yaml` for any surviving machine-local state. Ask via `clarify` whether to delete it now. Use the repo-root path when deleting.

### Step 5: Bootstrap Project Config

Resolve the repository root with `git rev-parse --show-toplevel` (fall back to `pwd`). All paths below are relative to the repo root, not the current working directory.

**Example file (always refresh):** Copy `references/config-template.yaml` to `<project-root>/.compound-engineering/config.local.example.yaml`, creating the directory if needed. This file is committed to the repo and always overwritten with the latest template so teammates can see available settings.

**Local config (create once):** If `.compound-engineering/config.local.yaml` does not exist, ask via `clarify` whether to create it:

```
Set up a local config file for this project?
This saves your Compound Engineering preferences (like which tools to use and how workflows behave).
Everything starts commented out — you only enable what you need.

1. Yes, create it (Recommended)
2. No thanks
```

If the user approves, copy `references/config-template.yaml` to `<project-root>/.compound-engineering/config.local.yaml`. If `.compound-engineering/config.local.yaml` is not already covered by `.gitignore`, offer to add the entry:

```
.compound-engineering/*.local.yaml
```

If the local config already exists, check whether it is safely gitignored. If not, offer to add the `.gitignore` entry as above.

### Step 6: Offer Installation

Present the missing tools and skills using a multiSelect question with all items pre-selected. Use the install commands and URLs from the script's diagnostic output. Group items under `Tools:` and `Skills:` so the user can see which runtime each item targets; omit a group whose items are all installed.

```
The following items are missing. Select which to install:
(All items are pre-selected)

Tools:
  [x] gh - GitHub CLI for issues and PRs
  [x] jq - JSON processor

Skills:
  [x] ce-compound-refresh - Maintain docs/solutions/ over time
```

Only show items that are actually missing. Omit installed ones.

### Step 7: Install Selected Dependencies

For each selected dependency, in order:

1. **Show the install command** (from the diagnostic output) and ask for approval via `clarify`:

   ```
   Install gh?
   Command: sudo pacman -S github-cli (CachyOS/Arch)  /  brew install gh (macOS)

   1. Run this command
   2. Skip — I'll install it manually
   ```

2. **If approved:** Run the install command. After it completes, verify installation:
   - For a CLI tool, run `command -v <tool>` to confirm.
   - For a skill, check that `~/.hermes/skills/compound-engineering/<skill-name>/SKILL.md` exists.

3. **If verification succeeds:** Report success.

4. **If verification fails or install errors:** Display the project URL as fallback and continue to the next dependency.

### Step 8: Summary

Display a brief summary:

```
✅ Compound Engineering setup complete

   Installed: jq, gh
   Skipped:   ffmpeg

   Run /ce-setup anytime to re-check.
```
