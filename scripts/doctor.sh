#!/usr/bin/env bash
# ==============================================================================
# doctor.sh
# End-to-end health diagnostic for the Antigravity + Gentle AI + Karpathy
# Full-Stack environment and optional target project.
# ==============================================================================
set -uo pipefail

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0
PROJECT_DIR=""

ok()   { printf '\033[1;32m[OK]\033[0m   %s\n' "$*"; PASS_COUNT=$((PASS_COUNT + 1)); }
warn() { printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; WARN_COUNT=$((WARN_COUNT + 1)); }
fail() { printf '\033[1;31m[FAIL]\033[0m %s\n' "$*"; FAIL_COUNT=$((FAIL_COUNT + 1)); }

usage() {
  cat << 'EOF'
Usage: ./scripts/doctor.sh [--project PATH]

Options:
  --project PATH   Also validate project contract, DESIGN.md, MCP config, .gitignore, and hook
  -h, --help       Show this help message
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --project)
      [ "$#" -ge 2 ] || { fail "--project requires a directory path."; exit 1; }
      PROJECT_DIR="$2"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "Unknown option: $1"
      exit 1
      ;;
  esac
  shift
done

version_gte() {
  # Compare semver-like X.Y.Z: returns 0 if $1 >= $2
  local a="$1" b="$2"
  local a1 a2 a3 b1 b2 b3
  IFS='.' read -r a1 a2 a3 << EOF
${a#v}
EOF
  IFS='.' read -r b1 b2 b3 << EOF
${b#v}
EOF
  a1="${a1:-0}"; a2="${a2:-0}"; a3="${a3%%-*}"; a3="${a3:-0}"
  b1="${b1:-0}"; b2="${b2:-0}"; b3="${b3%%-*}"; b3="${b3:-0}"
  [ "$a1" -gt "$b1" ] && return 0
  [ "$a1" -lt "$b1" ] && return 1
  [ "$a2" -gt "$b2" ] && return 0
  [ "$a2" -lt "$b2" ] && return 1
  [ "$a3" -ge "$b3" ] && return 0
  return 1
}

extract_semver() {
  printf '%s' "$1" | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1 || true
}

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

validate_json_file() {
  local file="$1"
  if command -v jq >/dev/null 2>&1; then
    jq empty "$file" >/dev/null 2>&1
  elif [ -n "$PYTHON_BIN" ]; then
    "$PYTHON_BIN" -m json.tool "$file" >/dev/null 2>&1
  elif command -v node >/dev/null 2>&1; then
    node -e "JSON.parse(require('fs').readFileSync(process.argv[1],'utf8'))" "$file" >/dev/null 2>&1
  else
    return 2
  fi
}

list_mcp_servers() {
  local file="$1"
  if command -v jq >/dev/null 2>&1; then
    jq -r '(.mcpServers // {}) | keys | join(", ")' "$file" 2>/dev/null || true
  elif [ -n "$PYTHON_BIN" ]; then
    "$PYTHON_BIN" -c 'import json,sys; d=json.load(open(sys.argv[1],encoding="utf-8")); print(", ".join(sorted((d.get("mcpServers") or {}).keys())))' "$file" 2>/dev/null || true
  elif command -v node >/dev/null 2>&1; then
    node -e 'const d=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")); console.log(Object.keys(d.mcpServers||{}).sort().join(", "))' "$file" 2>/dev/null || true
  fi
}

printf '\n=== 1. Core Health (Gentle AI & Engram) ===\n'
if command -v gentle-ai >/dev/null 2>&1; then
  gai_raw="$(gentle-ai --version 2>/dev/null || true)"
  gai_ver="$(extract_semver "$gai_raw")"
  if [ -n "$gai_ver" ] && version_gte "$gai_ver" "4.4.0"; then
    ok "gentle-ai $gai_ver (>= 4.4.0)"
  else
    warn "gentle-ai installed (${gai_raw:-unknown}), could not verify >= 4.4.0"
  fi
  if gentle-ai doctor >/dev/null 2>&1; then
    ok "gentle-ai doctor passed"
  else
    warn "gentle-ai doctor reported warnings/errors (run 'gentle-ai doctor' for details)"
  fi
else
  fail "gentle-ai not found in PATH"
fi

if command -v engram >/dev/null 2>&1; then
  eng_raw="$(engram --version 2>/dev/null || true)"
  eng_ver="$(extract_semver "$eng_raw")"
  if [ -n "$eng_ver" ] && version_gte "$eng_ver" "3.7.0"; then
    ok "engram $eng_ver (>= 3.7.0)"
  else
    warn "engram installed (${eng_raw:-unknown}), could not verify >= 3.7.0"
  fi
else
  fail "engram not found in PATH"
fi

printf '\n=== 2. Antigravity Rules Quota (<= 24 KB) ===\n'
RULES_DIR="$HOME/.gemini/config/rules"
if [ -d "$RULES_DIR" ]; then
  oversized="$(find "$RULES_DIR" -type f -size +24k 2>/dev/null || true)"
  if [ -n "$oversized" ]; then
    fail "Rule file(s) exceed 24 KB limit: $oversized"
  else
    ok "No files in $RULES_DIR exceed 24 KB"
  fi
  while IFS= read -r rf; do
    [ -f "$rf" ] || continue
    sz="$(wc -c < "$rf" | tr -d ' ')"
    ok "Rule $(basename "$rf"): ${sz} bytes"
  done << EOF
$(find "$RULES_DIR" -maxdepth 1 -type f -name '*.md' 2>/dev/null | sort)
EOF
else
  warn "Rules directory $RULES_DIR does not exist yet (run setup-gentle-karpathy.sh)"
fi

printf '\n=== 3. Stack Binaries & Browser ===\n'
if command -v node >/dev/null 2>&1 && command -v npx >/dev/null 2>&1; then
  ok "node ($(node -v 2>/dev/null || echo ok)) + npx available"
else
  fail "node / npx not found in PATH"
fi

if command -v semgrep >/dev/null 2>&1; then
  sg_ver="$(semgrep --version 2>/dev/null | head -n 1 || echo ok)"
  if semgrep mcp --help >/dev/null 2>&1; then
    ok "semgrep $sg_ver (with 'semgrep mcp' support)"
  else
    fail "semgrep $sg_ver lacks 'semgrep mcp' support"
  fi
else
  fail "semgrep CLI not found in PATH"
fi

pw_found=false
for pw_dir in "$HOME/.cache/ms-playwright" "$HOME/Library/Caches/ms-playwright" "${LOCALAPPDATA:-}/ms-playwright"; do
  if [ -n "$pw_dir" ] && [ -d "$pw_dir" ] && ls "$pw_dir"/chromium* >/dev/null 2>&1; then
    pw_found=true
    ok "Playwright Chromium cached in $pw_dir"
    break
  fi
done
[ "$pw_found" = true ] || warn "Playwright Chromium cache not found (run: npx -y playwright install chromium)"

if command -v jq >/dev/null 2>&1; then
  ok "JSON tool: jq"
elif [ -n "$PYTHON_BIN" ]; then
  ok "JSON tool: $PYTHON_BIN"
elif command -v node >/dev/null 2>&1; then
  ok "JSON tool: node"
else
  fail "No JSON processor found (jq, python3, python, or node)"
fi

printf '\n=== 4. Global Skills (Progressive Disclosure) ===\n'
SKILLS_DIR="$HOME/.gemini/config/skills"
if [ -d "$SKILLS_DIR" ]; then
  for req_skill in karpathy-guidelines impeccable differential-review insecure-defaults sharp-edges fp-check; do
    if [ -f "$SKILLS_DIR/$req_skill/SKILL.md" ]; then
      ok "Skill registered: $req_skill"
    else
      fail "Missing required skill: $SKILLS_DIR/$req_skill/SKILL.md"
    fi
  done

  if [ -f "$SKILLS_DIR/supabase-postgres-best-practices/SKILL.md" ]; then
    ok "Optional DB skill installed: supabase-postgres-best-practices"
  else
    warn "Optional DB skill not installed: supabase-postgres-best-practices"
  fi

  # Detect extra Trail of Bits skills beyond the 4 surgical selections
  tob_extra=""
  for d in "$SKILLS_DIR"/*/; do
    [ -d "$d" ] || continue
    bname="$(basename "$d")"
    case "$bname" in
      differential-review|insecure-defaults|sharp-edges|fp-check) continue ;;
    esac
    if grep -Rqi "trailofbits\|Trail of Bits" "$d" 2>/dev/null; then
      tob_extra="$tob_extra $bname"
    fi
  done
  if [ -n "$tob_extra" ]; then
    warn "Extra Trail of Bits skills detected (bloat risk):$tob_extra"
  else
    ok "Trail of Bits surgical filter clean (no extra bloat skills)"
  fi

  if command -v gentle-ai >/dev/null 2>&1; then
    if gentle-ai skill-registry refresh >/dev/null 2>&1; then
      ok "gentle-ai skill-registry refresh succeeded"
    else
      warn "gentle-ai skill-registry refresh returned non-zero status"
    fi
  fi
else
  warn "Global skills directory $SKILLS_DIR does not exist yet"
fi

printf '\n=== 5. Global MCP Configuration ===\n'
GLOBAL_MCP="$HOME/.gemini/config/mcp_config.json"
if [ -f "$GLOBAL_MCP" ]; then
  if validate_json_file "$GLOBAL_MCP"; then
    servers="$(list_mcp_servers "$GLOBAL_MCP")"
    ok "Global MCP config valid ($GLOBAL_MCP): [${servers:-none}]"
  else
    fail "Global MCP config has invalid JSON syntax: $GLOBAL_MCP"
  fi
else
  warn "Global MCP config not found at $GLOBAL_MCP"
fi

if [ -n "$PROJECT_DIR" ]; then
  printf '\n=== 6. Project Verification (%s) ===\n' "$PROJECT_DIR"
  if [ ! -d "$PROJECT_DIR" ]; then
    fail "Project directory does not exist: $PROJECT_DIR"
  else
    if [ -f "$PROJECT_DIR/AGENTS.md" ]; then
      ok "Project AGENTS.md present"
      if grep -Eq '^\- \*\*Design Contract\*\*: `?\./DESIGN\.md' "$PROJECT_DIR/AGENTS.md" 2>/dev/null; then
        if [ -f "$PROJECT_DIR/DESIGN.md" ]; then
          ok "Project DESIGN.md present"
        else
          fail "AGENTS.md references ./DESIGN.md but DESIGN.md is missing"
        fi
      fi
    else
      fail "Missing $PROJECT_DIR/AGENTS.md"
    fi

    proj_mcp="$PROJECT_DIR/.agents/mcp_config.json"
    if [ -f "$proj_mcp" ]; then
      if validate_json_file "$proj_mcp"; then
        p_servers="$(list_mcp_servers "$proj_mcp")"
        ok "Workspace MCP config valid (.agents/mcp_config.json): [${p_servers:-none}]"
      else
        fail "Invalid JSON in $proj_mcp"
      fi
    else
      warn "Workspace MCP config not found at $proj_mcp"
    fi

    if [ -f "$PROJECT_DIR/.mcp.json" ]; then
      if validate_json_file "$PROJECT_DIR/.mcp.json"; then
        c_servers="$(list_mcp_servers "$PROJECT_DIR/.mcp.json")"
        ok "Claude MCP config valid (.mcp.json): [${c_servers:-none}]"
      else
        fail "Invalid JSON in $PROJECT_DIR/.mcp.json"
      fi
    fi

    if [ -f "$PROJECT_DIR/.gitignore" ] && grep -Eq '(^|/)\.env($|[[:space:]])' "$PROJECT_DIR/.gitignore"; then
      ok ".gitignore covers .env"
    else
      warn ".gitignore does not explicitly cover .env"
    fi

    hook_file="$PROJECT_DIR/.git/hooks/pre-commit"
    if [ -d "$PROJECT_DIR/.git" ]; then
      if [ -f "$hook_file" ] && [ -x "$hook_file" ]; then
        ok "Executable pre-commit hook present ($hook_file)"
      elif [ -f "$hook_file" ]; then
        fail "pre-commit hook exists but is not executable ($hook_file)"
      else
        warn "No pre-commit hook installed at $hook_file"
      fi
    fi
  fi
fi

printf '\nSummary: %d OK, %d WARN, %d FAIL\n' "$PASS_COUNT" "$WARN_COUNT" "$FAIL_COUNT"
[ "$FAIL_COUNT" -eq 0 ]
