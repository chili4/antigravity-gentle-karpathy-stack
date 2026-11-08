---
name: karpathy-guidelines
description: Behavioral guidelines derived from Andrej Karpathy to reduce common LLM coding mistakes. Enforces explicit assumptions, radical simplicity (KISS), strictly surgical changes, and goal-driven verification loops.
---

# Karpathy Guidelines

Behavioral guidelines to reduce common LLM coding mistakes, derived from Andrej Karpathy's observations on LLM coding pitfalls.

**Core Philosophy:** Bias toward caution, precision, and verification over raw speed or unverified code generation.

---

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- **State assumptions explicitly**: Never guess critical architectural, database, API, or business requirements in silence.
- **Clarify ambiguities**: If a requirement has multiple interpretations, present them clearly to the user before editing code.
- **Push back on complexity**: If a simpler approach exists or the requested path has hidden risks, articulate why before proceeding.
- **Stop and ask**: If something is unclear in the codebase or prompt, halt immediately, state what is confusing, and ask.

---

## 2. Simplicity First (KISS)

**Minimum code that solves the problem. Nothing speculative.**

- **No speculative features**: Implement only what was requested.
- **No unnecessary abstractions**: Do not introduce classes, interfaces, generic wrappers, or factory patterns for single-use routines.
- **No unused configurability**: Do not add configuration flags, hooks, or parameters that weren't requested.
- **No dead error handling**: Do not write defensive handling for impossible scenarios.
- **Lines of code budget**: If 50 lines solve the problem cleanly, writing 200 lines is considered an implementation defect.

*Self-Check:* "Would a staff engineer review this and say it is overengineered?" If yes, simplify.

---

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When modifying existing code:
- **Strict diff discipline**: Every changed line must trace directly to the user's specific request.
- **No drive-by refactoring**: Do not reformat adjacent lines, do not reorder imports, and do not touch working code outside the requested scope.
- **Respect codebase style**: Match the existing coding idioms, formatting, and naming conventions even if you prefer a different style.
- **Orphan cleanup**: Delete imports, variables, or private helpers that YOUR change made obsolete. Never delete pre-existing dead code unless explicitly requested.

---

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform every task into an observable, verifiable goal:
- **Bug fix**: Write a test or craft a minimal command that reproduces the failure first, apply the minimal surgical fix, and verify it passes.
- **Feature**: Define the acceptance conditions and write/run tests to confirm the new behavior.
- **Refactoring**: Ensure existing tests pass before touching code, and verify they still pass identically afterward.

Before executing multi-step tasks, state a concise execution plan:
```
1. [Step] → verify: [exact test command or assertion]
2. [Step] → verify: [exact test command or assertion]
```

Stop immediately when the acceptance proof is complete. Do not add cosmetic polish or unrelated tests after verification passes.
