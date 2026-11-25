# DESIGN.md — Landing Page Archetype

## 1. Visual Intent & Anti-Slop Mandate
- **Goal**: High-conviction editorial clarity that communicates value in under 5 seconds and drives one primary conversion action.
- **Hard Bans (Zero AI Slop)**:
  - NO generic purple/blue neon mesh gradients, glowing glass blobs, or stock-looking 3-equal-card feature grids repeated down the page.
  - NO placeholder metric counters or unrequested decorative badges on every heading.
  - NO default Inter/Roboto-only monochrome templates without typographic hierarchy.

## 2. Typography & Visual Rhythm
- **Display + Body Pairing**: Pair an expressive display typeface (editorial serif, geometric grotesk, or technical mono display) with a highly legible sans-serif body (`16px`–`18px`, `1.55`–`1.65` line-height, `60ch`–`70ch` max measure).
- **Scale & Contrast**: Enforce a sharp scale jump (`H1 >= 2.75rem` desktop, tight tracking `-0.025em`) and deliberate negative space between narrative bands.
- **Asymmetry**: Alternate rhythm across sections (split hero, editorial manifesto, interactive proof/demo, focused pricing/FAQ, clean footer) rather than uniform centered stacks.

## 3. Color, Surfaces & Motion
- **Palette Discipline**: 1 dominant surface (light editorial paper or deep ink), 1 neutral secondary surface, 1 sharp accent reserved strictly for primary CTAs and active states (`>= 4.5:1` WCAG AA contrast).
- **Restrained Motion**: Use purposeful entrance/scroll transitions (`transform`, `opacity` only; `<= 250ms`–`400ms` ease-out) and respect `prefers-reduced-motion`. Never animate layout properties.

## 4. Component & Verification Rules
- Pull motion/hero primitives from configured `shadcn` registries (`@magicui`, `@cult-ui`) before writing custom animation wrappers.
- Every interactive flow (CTA, waitlist/contact form, mobile nav) MUST implement `default`, `loading`, `empty`, and `error` states.
- Verify desktop (`1440px`) and mobile (`390px`) via `playwright` MCP with zero horizontal overflow and zero console/network errors.
