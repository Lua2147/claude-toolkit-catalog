# Aesthetics Reference

## Contents
- Color System (OKLCH tokens)
- Typography
- Dark Mode
- Visual Identity

---

## Color System — OKLCH

Kadenwood uses **OKLCH** (perceptually uniform color space) for all design tokens. This is intentional: OKLCH produces more consistent lightness across hues than HSL or hex, which matters for a data-dense CRM with 269 KPIs where color carries semantic meaning.

**Light mode tokens** (`app/globals.css`, `:root`):

```css
--primary:            oklch(0.541 0.247 293.009);  /* purple — brand accent */
--primary-foreground: oklch(1 0 0);                /* white on primary */
--background:         oklch(1 0 0);                /* pure white surface */
--foreground:         oklch(0.145 0 0);            /* near-black text */
--muted:              oklch(0.97 0 0);             /* subtle backgrounds */
--muted-foreground:   oklch(0.556 0 0);            /* secondary text */
--destructive:        oklch(0.577 0.245 27.325);   /* red for errors/warnings */
--border:             oklch(0.922 0 0);            /* hairline dividers */
```

**Dark mode tokens** (`.dark` class):

```css
--primary:     oklch(0.627 0.265 303.9);  /* slightly brighter purple */
--background:  oklch(0.145 0 0);          /* near-black */
--card:        oklch(0.205 0 0);          /* elevated surface */
--border:      oklch(1 0 0 / 10%);        /* translucent white hairline */
```

**Chart color palette** (5-color system for Tremor/Recharts):

```css
--chart-1: oklch(0.646 0.222 41.116);   /* amber — high/positive */
--chart-2: oklch(0.6 0.118 184.704);    /* teal */
--chart-3: oklch(0.398 0.07 227.392);   /* slate blue */
--chart-4: oklch(0.828 0.189 84.429);   /* yellow-green */
--chart-5: oklch(0.769 0.188 70.08);    /* gold */
```

### NEVER add raw hex or HSL colors

```typescript
// BAD — bypasses the token system, breaks dark mode
<div className="bg-[#7c3aed] text-white" />

// GOOD — token adapts to dark mode automatically
<div className="bg-primary text-primary-foreground" />

// GOOD — extend the system for new semantic needs
// In globals.css @theme inline:
// --color-status-live: oklch(0.65 0.18 145);
// Then: className="bg-[--color-status-live]"
```

---

## Typography

**Font stack** (system fonts — no external font load cost):

```css
--font-sans: ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
```

This renders as SF Pro on macOS/iOS, Segoe UI on Windows, and system default on Linux. Appropriate for a professional CRM — crisp, fast, no external dependency.

**Do NOT switch to Inter or Roboto.** The system font stack is a deliberate performance and polish choice. Inter would require a font file and causes FOUT during load.

**Size scale** (Tailwind defaults — use these, don't invent):

```typescript
// Data labels in tables/charts
<span className="text-xs text-muted-foreground">MRR</span>

// Body content
<p className="text-sm text-foreground">Pipeline value: $4.2M</p>

// Card headers
<h3 className="text-base font-semibold">Active Deals</h3>

// Page headings
<h1 className="text-2xl font-bold tracking-tight">Kadenwood CRM</h1>

// KPI numbers (large metric display)
<span className="text-4xl font-bold tabular-nums">$1.2M</span>
```

Use `tabular-nums` on numeric displays — it prevents layout shift when values update.

---

## Dark Mode

Dark mode is controlled by `.dark` on `<html>` via `lib/theme/context.tsx`. Supports `light`, `dark`, and `system` (OS preference).

The `@custom-variant dark` in globals.css enables:

```typescript
// Structural dark mode differences (use sparingly — prefer semantic tokens)
<div className="shadow-md dark:shadow-none" />
<div className="border dark:border-white/10" />
```

Sidebar tokens are a separate token group (`--sidebar`, `--sidebar-foreground`, etc.) to allow independent sidebar theming from the main content area.

---

## Visual Identity

Kadenwood's design language: **data-first, professional, low visual noise**. The CRM houses 269 KPIs — whitespace and typography hierarchy are how users navigate, not decoration.

- **Primary accent**: purple (`oklch(0.541 0.247 293.009)`) — used sparingly on interactive elements and active states
- **Border radius**: `0.625rem` base (rounded but not pill-shaped — business tool, not consumer app)
- **Shadows**: minimal — `shadow-sm` on cards, none elsewhere. Dark mode strips shadows entirely (irrelevant on dark backgrounds)
- **Icons**: Lucide only. Star icons are globally hidden via `.lucide-star { display: none !important }` — product decision, do not revert
