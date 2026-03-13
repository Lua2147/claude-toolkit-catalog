---
name: frontend-design
description: |
  Applies Kadenwood CRM's UI design system: Tailwind v4 CSS-first config, shadcn/ui New York style, OKLCH color tokens, and CVA variant patterns.
  Use when: building or styling React components in apps/kadenwood, adding new UI elements to the dashboard, implementing dark mode variants, or maintaining design consistency across the 269-KPI CRM surface.
allowed-tools: Read, Edit, Write, Glob, Grep, Bash, mcp__context7__resolve-library-id, mcp__context7__query-docs
---

# Frontend Design — Kadenwood CRM

Kadenwood uses **Tailwind CSS v4** (CSS-first, no `tailwind.config.ts`), **shadcn/ui New York** style with **Radix UI** primitives, and an **OKLCH color system** defined entirely in `app/globals.css`. All tokens are CSS custom properties; theming is `.dark` class on `<html>`.

## Quick Start

### The `cn()` utility — always use it

```typescript
import { cn } from "@/lib/utils"

// Merges Tailwind classes intelligently — clsx conditions + twMerge conflict resolution
<div className={cn("rounded-xl bg-card p-6", isActive && "ring-2 ring-primary", className)} />
```

### CVA for component variants

```typescript
import { cva, type VariantProps } from "class-variance-authority"
import { cn } from "@/lib/utils"

const statusBadge = cva(
  "inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium",
  {
    variants: {
      status: {
        active:   "bg-primary/10 text-primary",
        inactive: "bg-muted text-muted-foreground",
        warning:  "bg-destructive/10 text-destructive",
      },
    },
    defaultVariants: { status: "active" },
  }
)

interface Props extends VariantProps<typeof statusBadge> {
  className?: string
}

export function StatusBadge({ status, className }: Props) {
  return <span className={cn(statusBadge({ status }), className)} />
}
```

### OKLCH semantic tokens — use variables, not hex

```css
/* In globals.css — DO NOT add raw colors, extend the token system */
@theme inline {
  --color-deal-hot:    oklch(0.7 0.2 41);   /* warm amber */
  --color-deal-cold:   oklch(0.6 0.1 220);  /* cool blue  */
}
```

```typescript
// In component — reference via Tailwind token
<div className="bg-[--color-deal-hot] text-white" />
```

## Key Concepts

| Concept | Usage | File |
|---------|-------|------|
| Color tokens | `--primary`, `--muted`, `--destructive` | `app/globals.css` |
| Component variants | CVA + `VariantProps` | `components/ui/*.tsx` |
| Dark mode | `.dark` class on `<html>` | `lib/theme/context.tsx` |
| Class merging | `cn()` = clsx + twMerge | `lib/utils.ts` |
| Icons | `lucide-react` only | package.json |
| Data viz | Tremor + Recharts | KPI dashboard |

## Common Patterns

### Card with hover lift (project convention)

```typescript
<div className={cn(
  "flex flex-col gap-6 rounded-xl border bg-card py-6 text-card-foreground shadow-sm",
  "card-hover"  // defined in globals.css — translateY(-1px) + box-shadow on hover
)}>
  {children}
</div>
```

### Dark mode conditional styling

```typescript
// CSS variables handle it automatically — prefer semantic tokens
<div className="bg-background text-foreground" />  // ✓ adapts to dark

// Only use dark: prefix for structural differences
<div className="shadow-sm dark:shadow-none border dark:border-white/10" />
```

### Focus ring pattern (matches existing components)

```typescript
// All interactive elements use this exact pattern from shadcn
className="focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50"
```

## See Also

- [aesthetics](references/aesthetics.md) — OKLCH colors, typography, visual identity
- [components](references/components.md) — CVA patterns, data-slot, shadcn usage
- [layouts](references/layouts.md) — dashboard grids, sidebar, responsive patterns
- [motion](references/motion.md) — tw-animate-css, transitions, micro-interactions
- [patterns](references/patterns.md) — DO/DON'T pairs, anti-patterns, design discipline

## Related Skills

For Next.js App Router patterns, see the **nextjs** skill.
For TypeScript type patterns used in component props, see the **typescript** skill.
