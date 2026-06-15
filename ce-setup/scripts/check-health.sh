#!/usr/bin/env bash
# ce-setup health check
# Diagnoses the compound-engineering environment for this machine.
# Pure shell + standard Unix tools (command -v, ls, cat, grep).
# Returns a colored report. Exits 0 always — this is a diagnostic, not a gate.

set -u

VERSION="unknown"
# parse --version 1.0.0
while [ $# -gt 0 ]; do
  case "$1" in
    --version) VERSION="$2"; shift 2;;
    *) shift;;
  esac
done
CE_ROOT="${CE_ROOT:-$HOME/.hermes/skills/compound-engineering}"
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Colors only when stdout is a tty
if [ -t 1 ]; then
  GREEN="\033[0;32m"; YELLOW="\033[0;33m"; RED="\033[0;31m"; BLUE="\033[0;34m"; NC="\033[0m"
else
  GREEN=""; YELLOW=""; RED=""; BLUE=""; NC=""
fi

ok()   { printf "  ${GREEN}🟢${NC} %s\n" "$1"; }
warn() { printf "  ${YELLOW}🟡${NC} %s\n" "$1"; }
fail() { printf "  ${RED}🔴${NC} %s\n" "$1"; }
hdr()  { printf "\n${BLUE}== %s ==${NC}\n" "$1"; }

# -------- Plugin bundle --------
hdr "Compound Engineering bundle (v$VERSION)"
if [ -d "$CE_ROOT" ]; then
  ok "Bundle present at $CE_ROOT"
else
  fail "Bundle MISSING at $CE_ROOT — reinstall: cp -r compound-engineering/ ~/.hermes/skills/"
  echo
  echo "Bundle check failed. Re-run after copying the skills bundle to $CE_ROOT"
  exit 1
fi

# -------- Skills (each ce-* subdir must have a SKILL.md) --------
hdr "Skills"
expected_skills=(
  compound-engineering
  ce-strategy
  ce-ideate
  ce-brainstorm
  ce-plan
  ce-execute
  ce-compound
  ce-compound-refresh
  ce-product-pulse
  ce-setup
)
missing_skills=()
# Entry-point skill is compound-engineering/ at the bundle root; others live in ce-*/ subdirs.
for s in "${expected_skills[@]}"; do
  if [ "$s" = "compound-engineering" ]; then
    skill_path="$CE_ROOT/SKILL.md"
  else
    skill_path="$CE_ROOT/$s/SKILL.md"
  fi
  if [ -f "$skill_path" ]; then
    ok "$s"
  else
    warn "$s — SKILL.md missing"
    missing_skills+=("$s")
  fi
done

# -------- CLI tools --------
hdr "Tools"
check_tool() {
  local name="$1"
  local desc="$2"
  if command -v "$name" >/dev/null 2>&1; then
    ok "$name — $desc"
  else
    warn "$name — $desc (install: see tool docs)"
  fi
}
check_tool gh    "GitHub CLI for issues and PRs"
check_tool jq    "JSON processor (used by validate-frontmatter and pulse config)"
check_tool git   "Required for git rev-parse in all CE skills"

# -------- Project-local config --------
hdr "Repo-local CE config (project: $PROJECT_ROOT)"
if [ -d "$PROJECT_ROOT/.compound-engineering" ]; then
  ok ".compound-engineering/ exists"
  if [ -f "$PROJECT_ROOT/.compound-engineering/config.local.yaml" ]; then
    ok "config.local.yaml present"
  else
    warn "config.local.yaml missing — run ce-setup Phase 2 to bootstrap"
  fi
  if [ -f "$PROJECT_ROOT/.compound-engineering/config.local.example.yaml" ]; then
    ok "config.local.example.yaml present (committed template)"
  else
    warn "config.local.example.yaml missing — copy from $CE_ROOT/ce-setup/references/config-template.yaml"
  fi
  if [ -f "$PROJECT_ROOT/.compound-engineering/.gitignore" ] || grep -qF ".compound-engineering/" "$PROJECT_ROOT/.gitignore" 2>/dev/null; then
    ok "gitignore covers .compound-engineering/"
  else
    warn ".gitignore does not cover .compound-engineering/ — add: .compound-engineering/*.local.yaml"
  fi
else
  warn ".compound-engineering/ does not exist — Phase 2 will create it"
fi

# -------- Obsolete legacy file --------
if [ -f "$PROJECT_ROOT/compound-engineering.local.md" ]; then
  warn "compound-engineering.local.md present at repo root (obsolete — review-agent selection is automatic; safe to delete)"
fi

# -------- Validator sanity --------
hdr "Validator"
if [ -x "$CE_ROOT/ce-compound/scripts/validate-frontmatter.py" ]; then
  if command -v python3 >/dev/null 2>&1; then
    ok "validate-frontmatter.py executable and python3 available"
  else
    warn "validate-frontmatter.py present but python3 not on PATH — fallback to manual YAML checks"
  fi
else
  fail "validate-frontmatter.py not executable — chmod +x $CE_ROOT/ce-compound/scripts/validate-frontmatter.py"
fi

# -------- Summary --------
hdr "Summary"
if [ ${#missing_skills[@]} -eq 0 ]; then
  printf "${GREEN}Bundle healthy.${NC} All ${#expected_skills[@]} skills present.\n"
else
  printf "${YELLOW}Bundle has ${#missing_skills[@]} missing skill(s):${NC} %s\n" "${missing_skills[*]}"
fi
echo
echo "If anything above is yellow/red, run /ce-setup and pick Phase 2 to install/fix."
