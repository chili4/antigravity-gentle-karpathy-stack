#!/usr/bin/env bash
# ==============================================================================
# setup-gentle-karpathy.sh
# Automated Bootstrapping for Google Antigravity + Gentle AI + Karpathy Guidelines
# ==============================================================================
set -euo pipefail

INFO()  { echo -e "\033[1;34m[INFO]\033[0m $*"; }
SUCCESS() { echo -e "\033[1;32m[SUCCESS]\033[0m $*"; }
WARN()  { echo -e "\033[1;33m[WARN]\033[0m $*"; }
ERROR() { echo -e "\033[1;31m[ERROR]\033[0m $*" >&2; exit 1; }

INFO "Checking system prerequisites..."
command -v git >/dev/null 2>&1 || ERROR "git is required but not installed."
command -v curl >/dev/null 2>&1 || ERROR "curl is required but not installed."

# 1. Install or update gentle-ai
INFO "Verifying Gentle AI installation..."
if ! command -v gentle-ai >/dev/null 2>&1; then
    INFO "Installing Gentle AI via official installer..."
    curl -sL https://gentlemanprogramming.com/install.sh | bash
    export PATH="$HOME/.local/bin:$PATH"
fi

command -v gentle-ai >/dev/null 2>&1 || ERROR "gentle-ai executable not found in PATH."

INFO "Ensuring gentle-ai is at version >= 4.4.0 (Antigravity modular rules requirement)..."
gentle-ai upgrade || WARN "Could not run gentle-ai upgrade automatically; check gentle-ai --version."

# 2. Sync Antigravity managed configuration
INFO "Syncing Antigravity managed components and rules..."
gentle-ai sync

# 3. Inject Karpathy Operative Rules (always_on)
INFO "Configuring Karpathy Operative Rules in ~/.gemini/config/rules/..."
mkdir -p "$HOME/.gemini/config/rules"

cat << 'EOF' > "$HOME/.gemini/config/rules/karpathy-rules.md"
---
trigger: always_on
---

## Operative Coding Pillars (Karpathy Guidelines)

These four core operational constraints govern all code generation, refactoring, and bug fixing. They are strictly mandatory:

### 1. Think Before Coding
- **Zero silent assumptions**: Never guess architectural decisions, database schemas, API contracts, or business logic in silence.
- **Clarify ambiguities**: If a requirement has multiple interpretations or hidden trade-offs, STOP and ask the user before touching files.
- **Push back on complexity**: If a simpler approach exists or requirements introduce unnecessary risk, explain why before implementing.

### 2. Simplicity First (KISS)
- **Minimum code**: Write only the code strictly necessary to solve the problem.
- **Zero speculation**: No classes, generic interfaces, premature abstractions, or extra configurability for single-use code.
- **No dead error handling**: Do not write defensive handling for impossible scenarios.
- **Lines of code budget**: If 50 lines suffice, 200 lines is considered an implementation defect.

### 3. Surgical Changes
- **Strict diff boundary**: Touch only the lines strictly required to satisfy the request. Every changed line must trace directly to the prompt.
- **No drive-by refactoring**: Never reformat adjacent code, reorder imports, or change untouched functions.
- **Style matching**: Match existing repository formatting and idioms exactly.
- **Orphan cleanup**: Remove only variables, imports, or functions that YOUR changes left unused. Never clean pre-existing dead code unless asked.

### 4. Goal-Driven Execution
- **Verifiable success criteria**: Turn instructions into measurable goals before editing.
- **Test-first / Reproduction**: For bug fixes, reproduce with a test or reproduction command first, apply the minimal fix, and loop until verified.
- **Preserve test suites**: Run relevant test suites before and after modifications to guarantee zero regressions.
EOF

# 4. Inject Karpathy Guidelines Skill
INFO "Registering Karpathy Guidelines skill in ~/.gemini/skills/..."
mkdir -p "$HOME/.gemini/skills/karpathy-guidelines"

cat << 'EOF' > "$HOME/.gemini/skills/karpathy-guidelines/SKILL.md"
---
name: karpathy-guidelines
description: Behavioral guidelines derived from Andrej Karpathy to reduce common LLM coding mistakes. Enforces explicit assumptions, radical simplicity (KISS), strictly surgical changes, and goal-driven verification loops.
---

# Karpathy Guidelines

Behavioral guidelines to reduce common LLM coding mistakes, derived from Andrej Karpathy's observations on LLM coding pitfalls.

**Tradeoff:** Bias toward caution and precision over unverified generation speed.

## 1. Think Before Coding
- State assumptions explicitly; never guess business logic silently.
- Present alternatives when multiple valid paths exist.
- Push back against unnecessary architectural complexity.

## 2. Simplicity First (KISS)
- Only implement requested functionality.
- Prohibit speculative interfaces, single-use classes, or unrequested flexibility.

## 3. Surgical Changes
- Every changed line must trace to user intent.
- Zero drive-by refactoring of adjacent code, imports, or comments.
- Clean up own orphans only.

## 4. Goal-Driven Execution
- Convert tasks into verifiable proof loops.
- Reproduce bugs first; verify fixes against the test suite before closing.
EOF

# 5. Template directory
INFO "Storing reusable AGENTS.md template in ~/.gemini/templates/..."
mkdir -p "$HOME/.gemini/templates"
cp "$(dirname "$0")/../templates/AGENTS.md" "$HOME/.gemini/templates/AGENTS.md" 2>/dev/null || true

# 6. Run doctor
INFO "Running gentle-ai doctor diagnostic..."
gentle-ai doctor || WARN "gentle-ai doctor reported non-critical warnings."

SUCCESS "Setup complete! Antigravity is now configured with Gentle AI 4.4.0+ and Karpathy Guidelines."
