#!/usr/bin/env sh
# ==============================================================================
# pre-commit-semgrep.sh
# Lightweight Git pre-commit hook: runs Semgrep ONLY on staged source files.
# ==============================================================================
set -eu

STAGED_FILES="$(git diff --cached --name-only --diff-filter=ACM)"

if [ -z "$STAGED_FILES" ]; then
  exit 0
fi

# Collect existing staged source files safely before requiring semgrep.
tmp_list="$(mktemp)"
trap 'rm -f "$tmp_list"' EXIT

git diff --cached --name-only --diff-filter=ACM | while IFS= read -r file; do
  [ -f "$file" ] || continue
  case "$file" in
    *.js|*.jsx|*.ts|*.tsx|*.mjs|*.cjs|*.py|*.go|*.rs|*.java|*.kt|*.rb|*.php|*.cs|*.c|*.cpp|*.h|*.hpp|*.sql|*.sh|*.bash|*.yml|*.yaml|*.tf)
      printf '%s\n' "$file" >> "$tmp_list"
      ;;
  esac
done

if [ ! -s "$tmp_list" ]; then
  exit 0
fi

if ! command -v semgrep >/dev/null 2>&1; then
  echo "[pre-commit] ERROR: 'semgrep' CLI is required for staged security checks." >&2
  echo "[pre-commit] Install with: uv tool install semgrep (or pipx install semgrep)" >&2
  exit 1
fi

echo "[pre-commit] Running Semgrep on staged source files..."
# Read newline-delimited staged paths safely into positional args.
set --
while IFS= read -r target; do
  set -- "$@" "$target"
done < "$tmp_list"

semgrep --config auto --error --quiet "$@"
