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
- **Zero speculation**: No unrequested abstractions, generic interfaces, premature factories, or extra configurability for single-use code.
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
