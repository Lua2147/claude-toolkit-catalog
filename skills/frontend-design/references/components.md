# Components Reference

## Contents
- Core Patterns (CVA, cn, data-slot)
- Extending shadcn/ui Components
- Custom Component Checklist
- Anti-Patterns

---

## Core Patterns

### CVA — Class Variance Authority

Every multi-variant component uses CVA. This is the established pattern across all `components/ui/` files.

```typescript
import { cva, type VariantProps } from "class-variance-authority"
import { cn } from "@/lib/utils"

const kpiCard = cva(
  // Base styles — always applied
  "flex flex-col rounded-xl border bg-card shadow-sm transition-colors",
  {
    variants: {
      trend: {
        up:      "border-l-4 border-l-emerald-500",
        down:    "border-l-4 border-l-destructive",
        neutral: "",
      },
      size: {
        sm: "p-4 gap-2",
        md: "p-6 gap-4",
        lg: "p-8 gap-6",
      },
    },
    defaultVariants: { trend: "neutral", size: "md" },
  }
)

interface KpiCardProps extends VariantProps<typeof kpiCard> {
  className?: string
  children: React.ReactNode
}

export function KpiCard({ trend, size, className, children }: KpiCardProps) {
  return (
    <div className={cn(kpiCard({ trend, size }), className)}>
      {children}
    </div>
  )
}
```

### `data-slot` — shadcn's styling hook system

Shadcn's New York components use `data-slot` attributes for targeting sub-elements without prop drilling. Match this pattern in new components:

```typescript
function MetricCard({ className, ...props }: React.ComponentProps<"div">) {
  return <div data-slot="metric-card" className={cn("...", className)} {...props} />
}

function MetricCardHeader({ className, ...props }: React.ComponentProps<"div">) {
  return <div data-slot="metric-card-header" className={cn("flex items-center gap-2", className)} {...props} />
}

function MetricCardValue({ className, ...props }: React.ComponentProps<"p">) {
  return <p data-slot="metric-card-value" className={cn("text-4xl font-bold tabular-nums", className)} {...props} />
}
```

### `cn()` — the only class merge utility

Always use `cn()` from `@/lib/utils`. Never concatenate class strings with template literals.

```typescript
// BAD — twMerge won't deduplicate, bg-red-500 won't override bg-blue-500
<div className={`bg-blue-500 ${isError ? "bg-red-500" : ""}`} />

// GOOD
<div className={cn("bg-blue-500", isError && "bg-red-500")} />
```

---

## Extending shadcn/ui Components

Use the shadcn CLI to add components — never copy-paste from docs:

```bash
cd apps/kadenwood/apps/dashboard
npx shadcn add [component-name]
```

Components land in `components/ui/`. Extend by wrapping, not modifying the source file:

```typescript
// components/deal-status-badge.tsx — wraps ui/badge.tsx
import { Badge, type BadgeProps } from "@/components/ui/badge"
import { cn } from "@/lib/utils"

type DealStatus = "live" | "prospecting" | "diligence" | "closed"

const STATUS_STYLES: Record<DealStatus, string> = {
  live:         "bg-emerald-50 text-emerald-700 border-emerald-200 dark:bg-emerald-950 dark:text-emerald-300",
  prospecting:  "bg-primary/10 text-primary border-primary/20",
  diligence:    "bg-amber-50 text-amber-700 border-amber-200 dark:bg-amber-950 dark:text-amber-300",
  closed:       "bg-muted text-muted-foreground",
}

export function DealStatusBadge({ status, className, ...props }: BadgeProps & { status: DealStatus }) {
  return (
    <Badge
      variant="outline"
      className={cn(STATUS_STYLES[status], className)}
      {...props}
    />
  )
}
```

### Aria attributes for form validation

shadcn inputs use `aria-invalid` to trigger error styling — leverage it instead of adding error classes manually:

```typescript
// Input already handles this via globals.css:
// aria-invalid:border-destructive aria-invalid:ring-destructive/20

<Input
  aria-invalid={!!errors.email}
  {...register("email")}
/>
// No need for: className={errors.email ? "border-red-500" : ""}
```

---

## Custom Component Checklist

When building a new component from scratch:

- [ ] Accept `className?: string` prop and pass to `cn()` as last argument (allows overrides)
- [ ] Use `React.ComponentProps<"element">` for HTML passthrough props
- [ ] Add `data-slot="component-name"` for CSS targeting
- [ ] Use CVA if there are 2+ variants
- [ ] Use semantic color tokens (`bg-card`, `text-muted-foreground`) not raw Tailwind colors
- [ ] Add `dark:` variants only when semantic tokens aren't sufficient
- [ ] Export both the component and its variant types: `export { Button, buttonVariants }`

---

## Anti-Patterns

### WARNING: Inline style for colors

**The Problem:**
```typescript
// BAD — bypasses dark mode, breaks theming, impossible to refactor
<div style={{ backgroundColor: "#7c3aed", color: "white" }}>
```

**Why This Breaks:** CSS custom property tokens update automatically on `.dark` toggle. Inline hex never does. One dark mode bug report becomes ten.

**The Fix:**
```typescript
<div className="bg-primary text-primary-foreground">
```

### WARNING: Prop drilling className into shadcn internals

**The Problem:**
```typescript
// BAD — reaches into shadcn internals, breaks on updates
<CardContent className="[&_.card-header]:bg-red-500">
```

**The Fix:** Wrap the component and apply your styles at the wrapper level, or use `data-slot` selectors defined in your own CSS.

### WARNING: Missing `tabular-nums` on numeric displays

Numbers without `tabular-nums` cause layout shift when values update — especially visible in the KPI dashboard where values refresh. Add it to every numeric metric display:

```typescript
<span className="text-2xl font-bold tabular-nums">{kpiValue}</span>
```
