# DESIGN.md — E-Commerce Archetype

## 1. Visual Intent & Conversion Clarity
- **Goal**: Trustworthy, tactile storefront where product photography leads and price, variants, stock, and checkout remain unmistakable.
- **Usability Over Novelty**: Never sacrifice standard shopping mental models (sticky bag summary, obvious variant selectors, clear shipping/return cues) for experimental navigation or hidden interactions.

## 2. Product Media & Grid Discipline
- **Strict Aspect Ratios**: Enforce uniform media containers (`aspect-[3/4]` or `aspect-[4/5]` for apparel/editorial, `aspect-square` for general catalog) with `object-cover`, explicit `sizes`, and zero layout shift (CLS = 0).
- **Hero Imagery**: Clean product-first photography on neutral surfaces (`#FFFFFF`, `#F7F7F5`, or warm stone) so product colors stay true.
- **Card Restraint**: Max 3–4 data points per product card (title, price/compare-at price, color swatches, quick-add/stock badge).

## 3. Pricing, Variants & Drawers
- **Typographic Numerals**: Use `font-variant-numeric: tabular-nums` on all prices, discounts, quantities, and cart subtotals.
- **Fast Drawers**: Implement filter facets, quick-view, and slide-over cart drawer without full-page reloads. Preserve focus trapping and `Esc` dismissal.
- **State Completeness**: Every async surface (catalog filter, variant stock check, cart mutation, checkout) MUST handle `loading` (skeletons matching card ratio), `empty` (clear reset CTA), `out-of-stock` (disabled/notify state), and `error` (recoverable retry).

## 4. Component & Verification Rules
- Prefer `@originui` and `@kibo-ui` via `shadcn` MCP for drawers, command search, carousels, and accessible form controls.
- Verify product grid, variant selection, cart drawer total math, and mobile (`390px`) touch targets via `playwright` MCP with zero console/network errors.
