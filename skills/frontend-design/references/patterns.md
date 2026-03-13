# Patterns Reference

## Contents
- Core DO/DON'T Pairs
- Tailwind v4 Specifics
- Data Display Patterns
- Anti-Patterns (Generic AI Aesthetics)
- When to Break the Rules

---

## Core DO/DON'T Pairs

### Color: tokens vs raw values

```typescript
// DON'T — hardcoded values break dark mode and future rebrands
<div className="bg-white text-gray-900 border-gray-200">
<div className="bg-[#7c3aed]">

// DO — semantic tokens that adapt automatically
<div className="bg-background text-foreground border-border">
<div className="bg-primary text-primary-foreground">
```

### Opacity: the `/` modifier vs direct classes

```typescript
// DON'T — opacity modifies the element, making it see-through including children
<div className="opacity-10 bg-primary">

// DO — opacity applied to the color only
<div className="bg-primary/10 text-primary">
```

### Dark mode: tokens vs explicit dark: variants

```typescript
// DON'T — duplicating what tokens already handle
<div className="bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100">

// DO — let semantic tokens handle it
<div className="bg-card text-card-foreground">

// DO use dark: only for structural differences tokens can't express
<div className="shadow-lg dark:shadow-none">
```

### Responsive: mobile-first vs desktop-first

```typescript
// DON'T — desktop-first breaks mobile, harder to maintain
<div className="grid-cols-4 sm:grid-cols-2 xs:grid-cols-1">

// DO — mobile-first: add complexity as viewport grows
<div className="grid-cols-1 sm:grid-cols-2 lg:grid-cols-4">
```

---

## Tailwind v4 Specifics

Kadenwood uses Tailwind v4. The config is CSS-first — **there is no `tailwind.config.ts`**. All customization lives in `app/globals.css` under `@theme`.

```css
/* Extend the design system HERE, not in a config file */
@theme inline {
  --color-deal-pipeline:  oklch(0.65 0.18 225);
  --color-kpi-positive:   oklch(0.7 0.17 145);
  --color-kpi-negative:   oklch(0.65 0.22 27);
}
```

Then use in components:

```typescript
// CSS variable reference — works with Tailwind's JIT
<div className="bg-[--color-deal-pipeline] text-white" />
```

**WARNING**: Don't install `@tailwindcss/typography`, `@tailwindcss/forms`, or other v3 plugins without verifying v4 compatibility. The plugin API changed significantly.

---

## Data Display Patterns

For a 269-KPI dashboard, data display patterns are the most important design decisions:

### KPI metric display

```typescript
// Consistent structure across all KPI cards
<div className="flex flex-col gap-1">
  <span className="text-sm font-medium text-muted-foreground">{label}</span>
  <span className="text-3xl font-bold tabular-nums tracking-tight">{value}</span>
  <span className={cn(
    "flex items-center gap-1 text-xs",
    trend > 0 ? "text-emerald-600 dark:text-emerald-400" : "text-destructive"
  )}>
    {trend > 0 ? <TrendingUp className="size-3" /> : <TrendingDown className="size-3" />}
    {Math.abs(trend)}% vs last month
  </span>
</div>
```

### Empty states

```typescript
// Consistent empty state pattern
<div className="flex flex-col items-center justify-center py-12 text-center">
  <Database className="size-10 text-muted-foreground/40 mb-3" />
  <p className="text-sm font-medium text-muted-foreground">No deals found</p>
  <p className="text-xs text-muted-foreground/60 mt-1">Try adjusting your filters</p>
</div>
```

### Status indicators (semantic color use)

Use Tailwind semantic colors for status, not arbitrary colors:
- **Positive/live**: emerald variants (`text-emerald-600 dark:text-emerald-400`)
- **Warning/pending**: amber variants (`text-amber-600 dark:text-amber-400`)
- **Error/closed-lost**: `text-destructive`
- **Neutral/inactive**: `text-muted-foreground`

---

## Anti-Patterns (Generic AI Aesthetics)

These are the visual clichés Claude defaults to when not given direction. AVOID them in Kadenwood.

### WARNING: Gradient backgrounds on cards

```typescript
// BAD — the "AI purple gradient" look, instantly forgettable
<div className="bg-gradient-to-br from-violet-500 to-purple-600 text-white rounded-xl p-6">

// GOOD — flat card with semantic token, distinctive through typography and data
<div className="bg-card border rounded-xl p-6">
```

**Why:** The CRM conveys authority through data density and precision, not visual flair. Gradients draw attention away from the numbers.

### WARNING: Glassmorphism

```typescript
// BAD — looks dated, poor contrast, fails accessibility
<div className="bg-white/10 backdrop-blur-lg border border-white/20">

// GOOD — solid surfaces with proper contrast ratios
<div className="bg-card border">
```

### WARNING: Excessive rounded corners

```typescript
// BAD — pill-shaped cards look like consumer apps, not B2B tools
<div className="rounded-full p-6">
<div className="rounded-3xl p-6">

// GOOD — the established radius from globals.css
<div className="rounded-xl p-6">   // 0.625rem + 4px = large
<div className="rounded-lg p-6">   // 0.625rem
```

### WARNING: Emoji in UI

```typescript
// BAD — unprofessional in a CRM context
<span>📈 Revenue up 12%</span>

// GOOD — Lucide icon, properly sized and colored
<TrendingUp className="size-4 text-emerald-600" />
<span>Revenue up 12%</span>
```

---

## When to Break the Rules

**Acceptable deviations:**
- Use `!important` in globals.css for intentional overrides (e.g., `.lucide-star { display: none !important }`) — never in component files
- Use arbitrary values (`w-[280px]`) when matching a specific design constraint like sidebar width that needs a fixed value
- Use raw OKLCH colors for one-off decorative elements that won't need dark mode adaptation (charts, illustration accents)

**Never acceptable:**
- Inline styles on interactive elements (dark mode never applies)
- Arbitrary spacing outside the 4px grid for structural layout
- Adding `!important` in component className strings (cascade order should handle specificity)
