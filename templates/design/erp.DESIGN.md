# DESIGN.md — ERP / Backoffice Archetype

## 1. Density & Restraint Mandate (Curb Decorative Flair)
- **Goal**: High-density, keyboard-first operational workspace (Linear / Stripe Dashboard standard) built for speed, accuracy, and long-session legibility.
- **Explicit Override for `impeccable`**: Suppress editorial, marketing, or decorative instincts. NO oversized hero padding, NO ornamental gradients, NO playful floating animations, NO unnecessary cards wrapping simple key-value pairs. Prioritize information density, structural alignment, and edge-case resilience.

## 2. Layout, Typography & Numerals
- **Shell**: Compact persistent sidebar (`220px`–`248px`, collapsible) + slim top breadcrumb/command bar (`48px`–`52px`) + fluid workspace canvas.
- **Tabular Numerals (Mandatory)**: Apply `font-variant-numeric: tabular-nums` on ALL monetary amounts, quantities, percentages, timestamps, invoice numbers, and table IDs. Right-align numeric columns.
- **Type Scale**: Crisp sans-serif UI (`13px`–`14px` base, `12px` table headers/meta) + monospace for IDs, SKUs, and audit hashes.

## 3. Tables, Filters & Keyboard Ergonomics
- **Operational Tables**: Sticky headers, deterministic sorting, multi-facet filter bar (URL-synced state), explicit column widths, row hover + keyboard focus ring, and safe bulk-action confirmation for destructive mutations.
- **Keyboard Shortcuts**: Support `Cmd/Ctrl+K` command/search bar, `Esc` to close drawers/dialogs, and unambiguous tab order across dense forms.
- **Semantic Status Tokens**: Use restrained, accessible status pills (`neutral`, `info`, `success`, `warning`, `danger`) with text labels—never color alone.

## 4. State Completeness & Verification
- Every view/table/form MUST handle `loading` (structural skeleton), `empty` (zero-records prompt + action), `error` (actionable banner + retry), and `permission-denied` / `stale-conflict` states.
- Use `@originui` and `@diceui` via `shadcn` MCP for data tables, comboboxes, date pickers, and dense inputs; exclude decorative effect registries.
- Verify dense table alignment, filter URL state, form validation, and zero console/network errors via `playwright` MCP.
