#!/usr/bin/env bash
# ==============================================================================
# init-project.sh
# Idempotent per-repository initialization for Antigravity + Gentle AI +
# Karpathy Full-Stack profiles (landing, ecommerce, erp, backend, fullstack).
# ==============================================================================
set -euo pipefail

INFO()    { printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
SUCCESS() { printf '\033[1;32m[SUCCESS]\033[0m %s\n' "$*"; }
WARN()    { printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
ERROR()   { printf '\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2; exit 1; }

TARGET_DIR=""
PROFILE=""
DESIGN_OVERRIDE=""
WITH_SECURITY=""
WITH_DB=false
WITH_CLAUDE_MCP=false
INSTALL_GIT_HOOK=false
FORCE=false

usage() {
  cat << 'EOF'
Usage: ./scripts/init-project.sh --target PATH --profile PROFILE [OPTIONS]

Profiles:
  landing | ecommerce | erp | backend | fullstack

Options:
  --target PATH          Target project directory (required)
  --profile PROFILE      Project archetype profile (required)
  --design ARCHETYPE     Design archetype for fullstack (landing|ecommerce|erp, default: erp)
  --with-security        Enable Semgrep + Socket MCP (default for ecommerce/erp/backend/fullstack)
  --no-security          Disable security MCP fragment
  --with-db              Enable opt-in Postgres MCP Pro (restricted) + .env.example/.gitignore guard
  --with-claude-mcp      Also merge MCP servers into <target>/.mcp.json (Claude Code)
  --install-git-hook     Install staged-only Semgrep pre-commit hook in .git/hooks/pre-commit
  --force                Overwrite existing AGENTS.md, DESIGN.md, and .env.example
  -h, --help             Show this help message
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --target)
      [ "$#" -ge 2 ] || ERROR "--target requires a path argument."
      TARGET_DIR="$2"
      shift
      ;;
    --profile)
      [ "$#" -ge 2 ] || ERROR "--profile requires a profile name."
      PROFILE="$2"
      shift
      ;;
    --design)
      [ "$#" -ge 2 ] || ERROR "--design requires an archetype (landing|ecommerce|erp)."
      DESIGN_OVERRIDE="$2"
      shift
      ;;
    --with-security)
      WITH_SECURITY=true
      ;;
    --no-security)
      WITH_SECURITY=false
      ;;
    --with-db)
      WITH_DB=true
      ;;
    --with-claude-mcp)
      WITH_CLAUDE_MCP=true
      ;;
    --install-git-hook)
      INSTALL_GIT_HOOK=true
      ;;
    --force)
      FORCE=true
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

[ -n "$TARGET_DIR" ] || ERROR "--target is required."
[ -n "$PROFILE" ] || ERROR "--profile is required."

case "$PROFILE" in
  landing)
    HAS_FRONTEND=true
    DESIGN_ARCHETYPE="landing"
    [ -n "$WITH_SECURITY" ] || WITH_SECURITY=false
    ;;
  ecommerce|erp)
    HAS_FRONTEND=true
    DESIGN_ARCHETYPE="$PROFILE"
    [ -n "$WITH_SECURITY" ] || WITH_SECURITY=true
    ;;
  backend)
    HAS_FRONTEND=false
    DESIGN_ARCHETYPE=""
    [ -n "$WITH_SECURITY" ] || WITH_SECURITY=true
    ;;
  fullstack)
    HAS_FRONTEND=true
    DESIGN_ARCHETYPE="${DESIGN_OVERRIDE:-erp}"
    [ -n "$WITH_SECURITY" ] || WITH_SECURITY=true
    ;;
  *)
    ERROR "Invalid profile '$PROFILE'. Expected: landing, ecommerce, erp, backend, or fullstack."
    ;;
esac

if [ "$HAS_FRONTEND" = true ]; then
  case "$DESIGN_ARCHETYPE" in
    landing|ecommerce|erp) ;;
    *) ERROR "Invalid design archetype '$DESIGN_ARCHETYPE'. Expected: landing, ecommerce, or erp." ;;
  esac
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
if [ -d "$REPO_ROOT/templates/mcp" ]; then
  TEMPLATES_DIR="$REPO_ROOT/templates"
elif [ -d "$HOME/.gemini/templates/mcp" ]; then
  TEMPLATES_DIR="$HOME/.gemini/templates"
else
  ERROR "Templates directory not found in $REPO_ROOT/templates or ~/.gemini/templates."
fi

mkdir -p "$TARGET_DIR"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

# ------------------------------------------------------------------------------
# JSON Helpers (Python / Node / jq)
# ------------------------------------------------------------------------------
detect_python() {
  local cand
  for cand in python3 python; do
    if command -v "$cand" >/dev/null 2>&1 && "$cand" -c "import sys" >/dev/null 2>&1; then
      printf '%s' "$cand"
      return 0
    fi
  done
  return 1
}

PYTHON_BIN="$(detect_python || true)"

run_json_merge_mcp() {
  local target_json="$1"
  local fragment_json="$2"
  local claude_mode="$3"

  if [ -n "$PYTHON_BIN" ]; then
    "$PYTHON_BIN" - "$target_json" "$fragment_json" "$claude_mode" << 'PYEOF'
import json
import os
import sys

target_path, frag_path, claude_mode = sys.argv[1], sys.argv[2], sys.argv[3] == "true"

if os.path.exists(target_path):
    with open(target_path, "r", encoding="utf-8") as f:
        content = f.read().strip()
        data = json.loads(content) if content else {}
else:
    data = {}

if not isinstance(data, dict):
    raise SystemExit(f"Invalid JSON object in {target_path}")

with open(frag_path, "r", encoding="utf-8") as f:
    frag = json.load(f)

servers = data.setdefault("mcpServers", {})
if not isinstance(servers, dict):
    raise SystemExit(f"'mcpServers' in {target_path} must be a JSON object")

for name, cfg in frag.get("mcpServers", {}).items():
    entry = dict(cfg)
    if claude_mode and "serverUrl" in entry:
        url = entry.pop("serverUrl")
        entry = {"type": "http", "url": url, **entry}
    # Non-destructive merge: preserve existing user server configuration if present
    if name not in servers:
        servers[name] = entry

os.makedirs(os.path.dirname(target_path), exist_ok=True)
with open(target_path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PYEOF
  elif command -v node >/dev/null 2>&1; then
    node - "$target_json" "$fragment_json" "$claude_mode" << 'JSEOF'
const fs = require("fs");
const path = require("path");

const [targetPath, fragPath, claudeFlag] = process.argv.slice(2);
const claudeMode = claudeFlag === "true";

let data = {};
if (fs.existsSync(targetPath)) {
  const raw = fs.readFileSync(targetPath, "utf8").trim();
  data = raw ? JSON.parse(raw) : {};
}
const frag = JSON.parse(fs.readFileSync(fragPath, "utf8"));
if (!data.mcpServers || typeof data.mcpServers !== "object") {
  data.mcpServers = {};
}
for (const [name, cfg] of Object.entries(frag.mcpServers || {})) {
  let entry = { ...cfg };
  if (claudeMode && entry.serverUrl) {
    const url = entry.serverUrl;
    delete entry.serverUrl;
    entry = { type: "http", url, ...entry };
  }
  if (!(name in data.mcpServers)) {
    data.mcpServers[name] = entry;
  }
}
fs.mkdirSync(path.dirname(targetPath), { recursive: true });
fs.writeFileSync(targetPath, JSON.stringify(data, null, 2) + "\n", "utf8");
JSEOF
  elif command -v jq >/dev/null 2>&1; then
    local tmp_out
    tmp_out="$(mktemp)"
    mkdir -p "$(dirname "$target_json")"
    if [ ! -f "$target_json" ]; then
      printf '{"mcpServers":{}}\n' > "$target_json"
    fi
    if [ "$claude_mode" = true ]; then
      jq -s '
        .[0] as $base | .[1] as $frag |
        ($frag.mcpServers | with_entries(
          if .value.serverUrl then
            .value = ({type: "http", url: .value.serverUrl} + (.value | del(.serverUrl)))
          else . end
        )) as $adapted |
        $base * {mcpServers: ($adapted + ($base.mcpServers // {}))}
      ' "$target_json" "$fragment_json" > "$tmp_out"
    else
      jq -s '
        .[0] as $base | .[1] as $frag |
        $base * {mcpServers: (($frag.mcpServers // {}) + ($base.mcpServers // {}))}
      ' "$target_json" "$fragment_json" > "$tmp_out"
    fi
    mv "$tmp_out" "$target_json"
  else
    ERROR "Requires python3/python, node, or jq to perform non-destructive JSON merging."
  fi
}

merge_shadcn_registries() {
  local components_json="$1"
  local preset_json="$2"

  if [ -n "$PYTHON_BIN" ]; then
    "$PYTHON_BIN" - "$components_json" "$preset_json" << 'PYEOF'
import json
import sys

comp_path, preset_path = sys.argv[1], sys.argv[2]
with open(comp_path, "r", encoding="utf-8") as f:
    comp = json.load(f)
with open(preset_path, "r", encoding="utf-8") as f:
    preset = json.load(f)

regs = comp.setdefault("registries", {})
for k, v in preset.get("registries", {}).items():
    regs.setdefault(k, v)

with open(comp_path, "w", encoding="utf-8") as f:
    json.dump(comp, f, indent=2)
    f.write("\n")
PYEOF
  elif command -v node >/dev/null 2>&1; then
    node - "$components_json" "$preset_json" << 'JSEOF'
const fs = require("fs");
const [compPath, presetPath] = process.argv.slice(2);
const comp = JSON.parse(fs.readFileSync(compPath, "utf8"));
const preset = JSON.parse(fs.readFileSync(presetPath, "utf8"));
comp.registries = comp.registries || {};
for (const [k, v] of Object.entries(preset.registries || {})) {
  if (!(k in comp.registries)) comp.registries[k] = v;
}
fs.writeFileSync(compPath, JSON.stringify(comp, null, 2) + "\n", "utf8");
JSEOF
  elif command -v jq >/dev/null 2>&1; then
    local tmp_out
    tmp_out="$(mktemp)"
    jq -s '.[0] * {registries: ((.[1].registries // {}) + (.[0].registries // {}))}' \
      "$components_json" "$preset_json" > "$tmp_out"
    mv "$tmp_out" "$components_json"
  fi
}

render_agents_md() {
  local src="$1"
  local dst="$2"
  local design_val="$3"
  local mcps_val="$4"
  local sec_val="$5"
  local db_val="$6"

  if [ -n "$PYTHON_BIN" ]; then
    "$PYTHON_BIN" - "$src" "$dst" "$PROFILE" "$design_val" "$mcps_val" "$sec_val" "$db_val" << 'PYEOF'
import sys
src, dst, prof, design, mcps, sec, db = sys.argv[1:]
with open(src, "r", encoding="utf-8") as f:
    text = f.read()
text = (
    text.replace("<PROFILE_ARCHETYPE>", prof)
        .replace("<DESIGN_CONTRACT>", design)
        .replace("<ENABLED_MCPS>", mcps)
        .replace("<SECURITY_GATE>", sec)
        .replace("<DB_PROFILE>", db)
)
with open(dst, "w", encoding="utf-8") as f:
    f.write(text)
PYEOF
  else
    sed \
      -e "s|<PROFILE_ARCHETYPE>|$PROFILE|g" \
      -e "s|<DESIGN_CONTRACT>|$design_val|g" \
      -e "s|<ENABLED_MCPS>|$mcps_val|g" \
      -e "s|<SECURITY_GATE>|$sec_val|g" \
      -e "s|<DB_PROFILE>|$db_val|g" \
      "$src" > "$dst"
  fi
}

# ------------------------------------------------------------------------------
# 1. Compute Active Profile Metadata & Render AGENTS.md
# ------------------------------------------------------------------------------
ENABLED_MCPS="engram, context7"
[ "$HAS_FRONTEND" = true ] && ENABLED_MCPS="$ENABLED_MCPS, shadcn, playwright"
[ "$WITH_SECURITY" = true ] && ENABLED_MCPS="$ENABLED_MCPS, semgrep, socket"
[ "$WITH_DB" = true ] && ENABLED_MCPS="$ENABLED_MCPS, postgres (restricted)"

DESIGN_CONTRACT="N/A"
[ "$HAS_FRONTEND" = true ] && DESIGN_CONTRACT="./DESIGN.md"

SECURITY_GATE="disabled"
[ "$WITH_SECURITY" = true ] && SECURITY_GATE="enabled"

DB_PROFILE="none"
[ "$WITH_DB" = true ] && DB_PROFILE="postgres-restricted"

if [ ! -f "$TARGET_DIR/AGENTS.md" ] || [ "$FORCE" = true ]; then
  render_agents_md \
    "$TEMPLATES_DIR/AGENTS.md" \
    "$TARGET_DIR/AGENTS.md" \
    "$DESIGN_CONTRACT" \
    "$ENABLED_MCPS" \
    "$SECURITY_GATE" \
    "$DB_PROFILE"
  INFO "Written $TARGET_DIR/AGENTS.md (profile: $PROFILE)."
else
  INFO "Preserving existing $TARGET_DIR/AGENTS.md (use --force to overwrite)."
fi

# ------------------------------------------------------------------------------
# 2. Frontend Design Contract & shadcn Registry Presets
# ------------------------------------------------------------------------------
if [ "$HAS_FRONTEND" = true ]; then
  if [ ! -f "$TARGET_DIR/DESIGN.md" ] || [ "$FORCE" = true ]; then
    cp "$TEMPLATES_DIR/design/$DESIGN_ARCHETYPE.DESIGN.md" "$TARGET_DIR/DESIGN.md"
    INFO "Written $TARGET_DIR/DESIGN.md ($DESIGN_ARCHETYPE archetype)."
  else
    INFO "Preserving existing $TARGET_DIR/DESIGN.md (use --force to overwrite)."
  fi

  PRESET_FILE="$TEMPLATES_DIR/shadcn/$DESIGN_ARCHETYPE.registries.json"
  if [ -f "$TARGET_DIR/components.json" ]; then
    merge_shadcn_registries "$TARGET_DIR/components.json" "$PRESET_FILE"
    INFO "Merged shadcn registries preset ($DESIGN_ARCHETYPE) into components.json."
  else
    INFO "No components.json found. After running 'npx shadcn@latest init', merge these registries from $PRESET_FILE:"
    cat "$PRESET_FILE"
  fi
fi

# ------------------------------------------------------------------------------
# 3. Non-Destructive Workspace MCP Merge
#    Default: <target>/.agents/mcp_config.json (Antigravity/Gemini)
#    Optional (--with-claude-mcp): <target>/.mcp.json (Claude Code)
# ------------------------------------------------------------------------------
ANTIGRAVITY_MCP="$TARGET_DIR/.agents/mcp_config.json"
CLAUDE_MCP="$TARGET_DIR/.mcp.json"

merge_fragment() {
  local frag="$1"
  run_json_merge_mcp "$ANTIGRAVITY_MCP" "$frag" "false"
  if [ "$WITH_CLAUDE_MCP" = true ]; then
    run_json_merge_mcp "$CLAUDE_MCP" "$frag" "true"
  fi
}

[ "$HAS_FRONTEND" = true ] && merge_fragment "$TEMPLATES_DIR/mcp/frontend.mcp.json"
[ "$WITH_SECURITY" = true ] && merge_fragment "$TEMPLATES_DIR/mcp/security.mcp.json"
[ "$WITH_DB" = true ] && merge_fragment "$TEMPLATES_DIR/mcp/db-postgres.mcp.json"

INFO "Updated Antigravity workspace MCP config: $ANTIGRAVITY_MCP"
if [ "$WITH_CLAUDE_MCP" = true ]; then
  INFO "Updated Claude Code workspace MCP config: $CLAUDE_MCP"
fi

# ------------------------------------------------------------------------------
# 4. Opt-in Database Guardrails (--with-db)
# ------------------------------------------------------------------------------
if [ "$WITH_DB" = true ]; then
  if [ ! -f "$TARGET_DIR/.env.example" ] || [ "$FORCE" = true ]; then
    cat << 'EOF' > "$TARGET_DIR/.env.example"
# Copy to .env (gitignored) and use a dedicated least-privilege read-only DB role
# when enabling Postgres MCP Pro (--access-mode=restricted).
DATABASE_URI=postgresql://readonly_user:change_me@localhost:5432/app_db
EOF
    INFO "Created $TARGET_DIR/.env.example"
  else
    INFO "Preserving existing $TARGET_DIR/.env.example"
  fi

  GITIGNORE="$TARGET_DIR/.gitignore"
  touch "$GITIGNORE"
  if ! grep -qxF ".env" "$GITIGNORE" 2>/dev/null; then
    printf '\n# Local environment secrets\n.env\n.env.*.local\n' >> "$GITIGNORE"
    INFO "Added .env exclusions to $GITIGNORE"
  fi

  WARN "Database MCP enabled in restricted mode. Store real credentials ONLY in .env (never commit secrets)."
fi

# ------------------------------------------------------------------------------
# 5. Git Pre-Commit Hook (--install-git-hook)
# ------------------------------------------------------------------------------
if [ "$INSTALL_GIT_HOOK" = true ]; then
  if [ -d "$TARGET_DIR/.git" ]; then
    HOOKS_DIR="$TARGET_DIR/.git/hooks"
    HOOK_DST="$HOOKS_DIR/pre-commit"
    HOOK_SRC="$TEMPLATES_DIR/hooks/pre-commit-semgrep.sh"
    mkdir -p "$HOOKS_DIR"

    if [ -f "$HOOK_DST" ]; then
      if cmp -s "$HOOK_DST" "$HOOK_SRC"; then
        INFO "Semgrep pre-commit hook already up to date at $HOOK_DST"
      else
        backup_path="$HOOK_DST.bak.$(date +%Y%m%d%H%M%S)"
        cp "$HOOK_DST" "$backup_path"
        WARN "Backed up existing pre-commit hook to $backup_path"
        cp "$HOOK_SRC" "$HOOK_DST"
        chmod +x "$HOOK_DST"
        INFO "Installed Semgrep pre-commit hook at $HOOK_DST"
      fi
    else
      cp "$HOOK_SRC" "$HOOK_DST"
      chmod +x "$HOOK_DST"
      INFO "Installed Semgrep pre-commit hook at $HOOK_DST"
    fi
  else
    WARN "--install-git-hook requested, but $TARGET_DIR is not a Git repository (.git not found)."
  fi
fi

SUCCESS "Project initialized at $TARGET_DIR (profile: $PROFILE)."
