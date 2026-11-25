---
trigger: always_on
---

# Full-Stack Orchestration & Routing

## 1. Execution Mode Cut-Off (Karpathy vs. Gentle AI)
- **Bounded bugfix, isolated refactor, minor tweak**: Execute directly using Karpathy's 4 pillars + RED/GREEN verification loop. Skip ODD/SDD ceremony.
- **New feature, architecture change, DB schema change, critical integration**: Run the full Gentle AI ODD/SDD workflow + Engram persistence + Judgment Day at milestones.

## 2. Automatic Layer Routing
| Change Surface | Mandatory Actions & Progressive Skills |
| :--- | :--- |
| **All Tasks (Memory)** | Query Engram (`mem_search`) for prior context at start; persist key decisions and traps (`mem_save`) before closing. |
| **UI / Styles / Components / Pages** | 1) Read `./DESIGN.md` first. 2) Use `shadcn` MCP to discover/install primitives & configured registries instead of rebuilding complex UI. 3) Load `impeccable` skill for visual hierarchy and full states (`default`, `loading`, `empty`, `error`), respecting `DESIGN.md` density. 4) Verify live in headless browser via `playwright` MCP (render, responsive layout, 0 console/network errors). |
| **Backend / API / Auth / Payments / Webhooks / SQL** | 1) Run `semgrep` MCP on modified files. 2) Load `differential-review` skill on final diff (add `insecure-defaults` for new routes, guards, or config; `sharp-edges` for security-sensitive APIs). 3) Run `fp-check` before reporting or patching findings. 4) For non-trivial PostgreSQL queries or migrations, load `supabase-postgres-best-practices` (and `postgres` MCP in `restricted` mode if active). |
| **Dependencies** (`package.json`, `pyproject.toml`, `Cargo.toml`, etc.) | Evaluate every new package with `socket` MCP before running the package manager. |

## 3. Definition of Done (Mandatory Gate)
Never close a task without verifying all applicable gates:
- Relevant unit/integration tests pass (RED -> GREEN on bugfixes).
- `playwright` MCP live check passes with zero console/network errors (if UI changed).
- Zero blocking `semgrep` findings on modified files (if backend/critical logic changed).
- No file under `rules/` or `~/.gemini/config/rules/` exceeds 24 KB.
