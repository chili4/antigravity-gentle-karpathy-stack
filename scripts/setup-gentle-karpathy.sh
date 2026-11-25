#!/usr/bin/env bash
# ==============================================================================
# setup-gentle-karpathy.sh
# Idempotent Global Provisioning for Google Antigravity + Gentle AI +
# Karpathy Guidelines + Full-Stack UI, Security, and Database Layers.
# ==============================================================================
set -euo pipefail

INFO()    { printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
SUCCESS() { printf '\033[1;32m[SUCCESS]\033[0m %s\n' "$*"; }
WARN()    { printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
ERROR()   { printf '\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2; exit 1; }

WITH_FRONTEND=true
WITH_SECURITY=true
WITH_DB_SKILL=true
RUN_DOCTOR=true

usage() {
  cat << 'EOF'
Usage: ./scripts/setup-gentle-karpathy.sh [OPTIONS]

Options:
  --full           Install all layers: core + frontend + security + db skill (default)
  --core-only      Install only Gentle AI + Karpathy core (skip frontend, security, db skill)
  --no-frontend    Skip Playwright Chromium and Impeccable skill
  --no-security    Skip Semgrep CLI and Trail of Bits security skills
  --no-db-skill    Skip supabase-postgres-best-practices skill
  --with-db-skill  Include supabase-postgres-best-practices skill
  --skip-doctor    Skip final ./scripts/doctor.sh run
  -h, --help       Show this help message
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --full)
      WITH_FRONTEND=true
      WITH_SECURITY=true
      WITH_DB_SKILL=true
      ;;
    --core-only)
      WITH_FRONTEND=false
      WITH_SECURITY=false
      WITH_DB_SKILL=false
      ;;
    --no-frontend)
      WITH_FRONTEND=false
      ;;
    --no-security)
      WITH_SECURITY=false
      ;;
    --no-db-skill)
      WITH_DB_SKILL=false
      ;;
    --with-db-skill)
      WITH_DB_SKILL=true
      ;;
    --skip-doctor)
      RUN_DOCTOR=false
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      ERROR "Unknown option: $1 (use --help for usage)"
      ;;
  esac
  shift
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

GEMINI_DIR="$HOME/.gemini"
GEMINI_CONFIG_DIR="$GEMINI_DIR/config"
RULES_DIR="$GEMINI_CONFIG_DIR/rules"
SKILLS_DIR="$GEMINI_CONFIG_DIR/skills"
TEMPLATES_DIR="$GEMINI_DIR/templates"

OS_RAW="$(uname -s 2>/dev/null || echo unknown)"
case "$OS_RAW" in
  Linux*)               OS_TYPE="linux" ;;
  Darwin*)              OS_TYPE="macos" ;;
  MINGW*|MSYS*|CYGWIN*) OS_TYPE="windows-bash" ;;
  *)                    OS_TYPE="other" ;;
esac
INFO "Detected environment: $OS_TYPE ($OS_RAW)"

# ------------------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------------------
ensure_json_tool() {
  if command -v jq >/dev/null 2>&1; then
    JSON_TOOL="jq"
  elif command -v python3 >/dev/null 2>&1 && python3 -c "import sys" >/dev/null 2>&1; then
    JSON_TOOL="python3"
  elif command -v python >/dev/null 2>&1 && python -c "import sys" >/dev/null 2>&1; then
    JSON_TOOL="python"
  elif command -v node >/dev/null 2>&1; then
    JSON_TOOL="node"
  else
    ERROR "A JSON processor (jq, python3, or node) is required for safe config management."
  fi
  INFO "JSON processor available: $JSON_TOOL"
}

sync_dir_clean() {
  local src="$1"
  local dst="$2"
  rm -rf "$dst"
  mkdir -p "$dst"
  cp -R "$src/." "$dst/"
}

sparse_clone_repo() {
  local repo_url="$1"
  local tmp_dir="$2"
  shift 2
  git clone --depth 1 --filter=blob:none --sparse "$repo_url" "$tmp_dir" >/dev/null 2>&1
  git -C "$tmp_dir" sparse-checkout set "$@" >/dev/null 2>&1
}

ensure_semgrep() {
  if command -v semgrep >/dev/null 2>&1; then
    INFO "Semgrep CLI already installed: $(semgrep --version 2>/dev/null | head -n 1)"
  else
    INFO "Installing Semgrep CLI..."
    if command -v uv >/dev/null 2>&1; then
      uv tool install semgrep
    elif command -v pipx >/dev/null 2>&1; then
      pipx install semgrep
    elif command -v brew >/dev/null 2>&1; then
      brew install semgrep
    else
      ERROR "Could not auto-install semgrep (requires uv, pipx, or brew). Install semgrep manually and re-run."
    fi
  fi

  command -v semgrep >/dev/null 2>&1 || ERROR "semgrep binary not found on PATH after installation."
  semgrep --version >/dev/null 2>&1 || ERROR "semgrep --version failed."
  if ! semgrep mcp --help >/dev/null 2>&1; then
    ERROR "Installed semgrep does not support 'semgrep mcp'. Upgrade semgrep to a modern version."
  fi
  SUCCESS "Semgrep CLI + 'semgrep mcp' verified."
}

ensure_playwright_chromium() {
  local cache_found=false
  local dir
  for dir in \
    "$HOME/.cache/ms-playwright" \
    "$HOME/Library/Caches/ms-playwright" \
    "${LOCALAPPDATA:-}/ms-playwright"; do
    if [ -n "$dir" ] && [ -d "$dir" ] && ls "$dir"/chromium* >/dev/null 2>&1; then
      cache_found=true
      break
    fi
  done

  if [ "$cache_found" = true ]; then
    INFO "Playwright Chromium browser already cached."
  else
    INFO "Installing Playwright Chromium browser (headless verification)..."
    npx -y playwright install chromium
  fi
}

install_trailofbits_skills() {
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  # Clean temporary clone on return
  trap 'rm -rf "$tmp_dir"' RETURN

  INFO "Fetching 4 surgical security skills from trailofbits/skills..."
  sparse_clone_repo \
    "https://github.com/trailofbits/skills.git" \
    "$tmp_dir" \
    "plugins/differential-review/skills/differential-review" \
    "plugins/sharp-edges/skills/sharp-edges" \
    "plugins/fp-check/skills/fp-check" \
    "plugins/insecure-defaults"

  sync_dir_clean "$tmp_dir/plugins/differential-review/skills/differential-review" "$SKILLS_DIR/differential-review"
  sync_dir_clean "$tmp_dir/plugins/sharp-edges/skills/sharp-edges" "$SKILLS_DIR/sharp-edges"
  sync_dir_clean "$tmp_dir/plugins/fp-check/skills/fp-check" "$SKILLS_DIR/fp-check"

  # plugins/insecure-defaults ships commands/audit.md + references/ without SKILL.md.
  # Stage its files and add a progressive-disclosure SKILL.md entrypoint for Antigravity.
  rm -rf "$SKILLS_DIR/insecure-defaults"
  mkdir -p "$SKILLS_DIR/insecure-defaults"
  cp -R "$tmp_dir/plugins/insecure-defaults/commands" "$SKILLS_DIR/insecure-defaults/commands"
  cp -R "$tmp_dir/plugins/insecure-defaults/references" "$SKILLS_DIR/insecure-defaults/references"
  if [ -d "$tmp_dir/plugins/insecure-defaults/workflows" ]; then
    cp -R "$tmp_dir/plugins/insecure-defaults/workflows" "$SKILLS_DIR/insecure-defaults/workflows"
  fi
  if [ -f "$tmp_dir/plugins/insecure-defaults/README.md" ]; then
    cp "$tmp_dir/plugins/insecure-defaults/README.md" "$SKILLS_DIR/insecure-defaults/README.md"
  fi

  cat << 'EOF' > "$SKILLS_DIR/insecure-defaults/SKILL.md"
---
name: insecure-defaults
description: >-
  Audit code and configuration for insecure default settings: fail-open security,
  default credentials, fallback secrets, weak cryptography, permissive access
  controls, and debug leakage. Load when creating or auditing routes, auth
  guards, middleware, or runtime configurations.
---

# Insecure Defaults Audit

Follow the structured audit procedure in [commands/audit.md](./commands/audit.md)
and consult the pattern catalogs under [references/](./references/) before
confirming findings:

- [fail-open-security.md](./references/fail-open-security.md)
- [default-credentials.md](./references/default-credentials.md)
- [fallback-secrets.md](./references/fallback-secrets.md)
- [permissive-access.md](./references/permissive-access.md)
- [weak-crypto.md](./references/weak-crypto.md)
- [debug-features.md](./references/debug-features.md)
EOF

  # Verify no extra skills from trailofbits/skills were copied
  local installed_tob_count=0
  local name
  for name in differential-review insecure-defaults sharp-edges fp-check; do
    [ -f "$SKILLS_DIR/$name/SKILL.md" ] || ERROR "Missing expected Trail of Bits skill: $name"
    installed_tob_count=$((installed_tob_count + 1))
  done
  INFO "Verified $installed_tob_count/4 Trail of Bits skills installed (zero bloat)."
}

# ------------------------------------------------------------------------------
# 1. Prerequisites
# ------------------------------------------------------------------------------
INFO "Checking core prerequisites..."
command -v git >/dev/null 2>&1 || ERROR "git is required but not installed."
command -v curl >/dev/null 2>&1 || ERROR "curl is required but not installed."
ensure_json_tool

if [ "$WITH_FRONTEND" = true ]; then
  if ! command -v node >/dev/null 2>&1 || ! command -v npx >/dev/null 2>&1; then
    if [ "$OS_TYPE" = "macos" ] && command -v brew >/dev/null 2>&1; then
      INFO "Installing Node.js via Homebrew..."
      brew install node
    else
      ERROR "Node.js and npx are required for shadcn MCP and Playwright MCP. Install Node.js LTS and re-run."
    fi
  fi
  ensure_playwright_chromium
fi

if [ "$WITH_SECURITY" = true ]; then
  ensure_semgrep
fi

# ------------------------------------------------------------------------------
# 2. Gentle AI Installation & Sync
# ------------------------------------------------------------------------------
INFO "Verifying Gentle AI installation..."
if ! command -v gentle-ai >/dev/null 2>&1; then
  INFO "Installing Gentle AI via official installer..."
  installer_script="$(mktemp)"
  curl -fsSL https://gentlemanprogramming.com/install.sh -o "$installer_script"
  [ -s "$installer_script" ] || ERROR "Downloaded Gentle AI installer is empty."
  bash "$installer_script"
  rm -f "$installer_script"
  export PATH="$HOME/.local/bin:$PATH"
fi

command -v gentle-ai >/dev/null 2>&1 || ERROR "gentle-ai executable not found in PATH."

INFO "Ensuring gentle-ai is at version >= 4.4.0..."
gentle-ai upgrade || WARN "Could not run gentle-ai upgrade automatically; check gentle-ai --version."

INFO "Syncing Antigravity managed components and rules..."
gentle-ai sync

# ------------------------------------------------------------------------------
# 3. Install Modular Rules (< 24 KB each)
# ------------------------------------------------------------------------------
INFO "Installing modular rules in $RULES_DIR/..."
mkdir -p "$RULES_DIR"

cp "$REPO_ROOT/rules/karpathy-rules.md" "$RULES_DIR/karpathy-rules.md"
cp "$REPO_ROOT/rules/stack-routing.md" "$RULES_DIR/stack-routing.md"

for rule_file in "$RULES_DIR/karpathy-rules.md" "$RULES_DIR/stack-routing.md"; do
  byte_size=$(wc -c < "$rule_file" | tr -d ' ')
  if [ "$byte_size" -ge 24000 ]; then
    ERROR "Rule $rule_file is $byte_size bytes, violating the 24 KB Antigravity quota!"
  fi
  INFO "Rule verified: $(basename "$rule_file") ($byte_size bytes < 24000 bytes)"
done

# ------------------------------------------------------------------------------
# 4. Install Global Skills in ~/.gemini/config/skills/ (Progressive Disclosure)
# ------------------------------------------------------------------------------
INFO "Installing global skills in $SKILLS_DIR/..."
mkdir -p "$SKILLS_DIR"

# Ensure ~/.gemini/config/skills.json points to ~/.gemini/config/skills if missing
if [ ! -f "$GEMINI_CONFIG_DIR/skills.json" ]; then
  cat << 'EOF' > "$GEMINI_CONFIG_DIR/skills.json"
{
  "entries": [
    {
      "path": "~/.gemini/config/skills"
    }
  ]
}
EOF
fi

sync_dir_clean "$REPO_ROOT/skills/karpathy-guidelines" "$SKILLS_DIR/karpathy-guidelines"

if [ "$WITH_FRONTEND" = true ]; then
  INFO "Installing Impeccable skill from pbakaus/impeccable..."
  tmp_imp="$(mktemp -d)"
  sparse_clone_repo "https://github.com/pbakaus/impeccable.git" "$tmp_imp" ".agents/skills/impeccable"
  sync_dir_clean "$tmp_imp/.agents/skills/impeccable" "$SKILLS_DIR/impeccable"
  rm -rf "$tmp_imp"
fi

if [ "$WITH_SECURITY" = true ]; then
  install_trailofbits_skills
fi

if [ "$WITH_DB_SKILL" = true ]; then
  INFO "Installing supabase-postgres-best-practices skill..."
  tmp_pg="$(mktemp -d)"
  sparse_clone_repo "https://github.com/supabase/agent-skills.git" "$tmp_pg" "skills/supabase-postgres-best-practices"
  sync_dir_clean "$tmp_pg/skills/supabase-postgres-best-practices" "$SKILLS_DIR/supabase-postgres-best-practices"
  rm -rf "$tmp_pg"
fi

# ------------------------------------------------------------------------------
# 5. Copy Reusable Templates to ~/.gemini/templates/
# ------------------------------------------------------------------------------
INFO "Installing project templates in $TEMPLATES_DIR/..."
mkdir -p "$TEMPLATES_DIR"
cp "$REPO_ROOT/templates/AGENTS.md" "$TEMPLATES_DIR/AGENTS.md"

for sub in design shadcn mcp hooks; do
  sync_dir_clean "$REPO_ROOT/templates/$sub" "$TEMPLATES_DIR/$sub"
done
chmod +x "$TEMPLATES_DIR/hooks/pre-commit-semgrep.sh" 2>/dev/null || true

# ------------------------------------------------------------------------------
# 6. Refresh Skill Registry & Run Doctor
# ------------------------------------------------------------------------------
INFO "Refreshing Gentle AI skill registry..."
gentle-ai skill-registry refresh || WARN "gentle-ai skill-registry refresh returned warnings."

if [ "$RUN_DOCTOR" = true ] && [ -x "$SCRIPT_DIR/doctor.sh" ]; then
  INFO "Running full-stack doctor diagnostic..."
  "$SCRIPT_DIR/doctor.sh" || WARN "doctor.sh reported issues; review output above."
elif [ "$RUN_DOCTOR" = true ] && [ -f "$SCRIPT_DIR/doctor.sh" ]; then
  bash "$SCRIPT_DIR/doctor.sh" || WARN "doctor.sh reported issues; review output above."
fi

SUCCESS "Global provisioning complete!"
