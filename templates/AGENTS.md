# Project Agent Contract (AGENTS.md)

> **Mandatory Operating Contract**: Any AI coding agent working in this repository (Google Antigravity, Claude Code, Cursor, Aider, OpenCode) MUST strictly adhere to these guidelines. These rules supersede standard defaults.

---

## 1. Active Project Profile

- **Archetype**: `<PROFILE_ARCHETYPE>` <!-- landing | ecommerce | erp | backend | fullstack -->
- **Design Contract**: `<DESIGN_CONTRACT>` <!-- ./DESIGN.md or N/A -->
- **Enabled Profile MCPs**: `<ENABLED_MCPS>` <!-- e.g. engram, context7, shadcn, playwright, semgrep, socket, postgres -->
- **Security Gate**: `<SECURITY_GATE>` <!-- enabled | disabled -->
- **Database Profile**: `<DB_PROFILE>` <!-- postgres-restricted | none -->

---

## 2. Prerequisite Pre-Flight: Gentle AI & Active MCPs

Before touching any code, the agent MUST verify the environment:

1. **Check for Gentle AI**:
   ```bash
   command -v gentle-ai >/dev/null 2>&1 || { echo "ERROR: gentle-ai is required but not installed."; exit 1; }
   ```
   - **If installed**: Run `gentle-ai skill-registry refresh` to index global and project skills.
   - **If NOT installed**: **STOP IMMEDIATELY**. Do not guess or execute changes. Notify the user and provide the official installer:
     ```bash
     curl -sL https://gentlemanprogramming.com/install.sh | bash
     ```
2. **Verify Active Project MCPs & Contracts**:
   - Confirm workspace MCP config in `.agents/mcp_config.json` (and `.mcp.json` if present) matches the active profile above.
   - If `<DESIGN_CONTRACT>` is `./DESIGN.md`, read `./DESIGN.md` before writing or modifying any UI component or style.
   - Query Engram (`mem_search`) for existing project decisions/context before planning changes.
3. **Verify Toolchains & Baseline Tests**:
   - Inspect build/test configs (`package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, etc.).
   - Ensure existing tests pass before touching code to establish an accurate baseline.

---

## 3. Audit Synergy (Complementary Gates)

Security and quality checks operate as three complementary, non-overlapping layers:
- **`semgrep` MCP (Deterministic SAST)**: Fast local static analysis on modified files (and staged files via `.git/hooks/pre-commit`).
- **Trail of Bits Skills (Logical Security Lens)**: `differential-review` (diff blast radius), `insecure-defaults` (fail-open config), `sharp-edges` (misuse-prone APIs), and `fp-check` (exploitability verification before reporting/patching).
- **Gentle AI `Judgment Day` (Adversarial Milestone Review)**: Blind multi-perspective review reserved for major features, schema changes, and critical integrations.

---

## 4. The 4 Operative Coding Pillars (Karpathy Guidelines)

### Pillar 1: Think Before Coding
- **Zero silent assumptions**: Never guess business logic, API contracts, schema structures, or architecture silently.
- **Surface ambiguities**: If a prompt has multiple valid interpretations, halt immediately, present the trade-offs, and ask the user before touching files.
- **Push back on complexity**: If a requested implementation is unnecessarily complex or introduces technical debt, state the technical reasons and propose a simpler alternative.

### Pillar 2: Simplicity First (KISS)
- **Minimum code**: Implement only what was explicitly requested.
- **Zero speculation**: No classes, generic interfaces, premature abstractions, or extra configurability for single-use code.
- **No dead error handling**: Do not write defensive handling for impossible scenarios.
- **Code budget**: If 50 lines solve the problem cleanly, writing 200 lines is considered an implementation defect.

### Pillar 3: Surgical Changes
- **Strict diff discipline**: Every changed line must trace directly to the user's specific request.
- **No drive-by refactoring**: Never reformat adjacent code, never reorder imports, and never modify untouched functions or files.
- **Respect codebase style**: Match the existing coding idioms, formatting, and naming conventions exactly.
- **Orphan cleanup**: Clean up variables, imports, or private helpers that YOUR change made obsolete. Never delete pre-existing dead code unless asked.

### Pillar 4: Goal-Driven Execution
- **Verifiable success criteria**: Turn instructions into measurable goals before editing.
- **Bug fixing**: Write a test or craft a minimal command that reproduces the failure first, apply the minimal surgical fix, and loop until verified.
- **Test suites**: Run relevant unit and integration test suites before and after modifications to guarantee zero regressions.

---

## 5. Repository Commands (Fill in for this project)

```bash
# Build
<BUILD_COMMAND>

# Test
<TEST_COMMAND>

# Lint / Typecheck
<LINT_COMMAND>
```

---

## 6. Git & Commit Conventions

- Use **Conventional Commits** (`feat:`, `fix:`, `refactor:`, `test:`, `docs:`).
- Commits must represent atomic, coherent units of work with their tests and documentation.
- Never add "Co-Authored-By", AI watermarks, or machine attribution to commit messages.
