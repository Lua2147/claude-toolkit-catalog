# Motion Reference

## Contents
- Animation Stack
- Transition Conventions
- Micro-interactions
- CSS Hover Effects
- Performance Rules

---

## Animation Stack

Kadenwood uses **`tw-animate-css`** — a Tailwind plugin that provides utility classes for CSS animations. There is no Framer Motion or GSAP. Keep it that way: a CRM dashboard doesn't need physics-based animations, and adding a heavy animation library for decorative effects is unjustified complexity.

```css
/* globals.css — imported at root */
@import "tw-animate-css";
```

This provides classes like `animate-in`, `animate-out`, `fade-in`, `slide-in-from-top`, etc. — all CSS-only, no JS runtime cost.

---

## Transition Conventions

### Color and state transitions

shadcn/ui components use `transition-colors` for hover/focus state changes. Match this:

```typescript
// Interactive elements — color only, fast
<button className="transition-colors duration-150 hover:bg-accent">

// Links and nav items
<a className="text-muted-foreground transition-colors hover:text-foreground">
```

### Box-shadow and transform transitions

The project's `card-hover` class (defined in `globals.css`) shows the established pattern:

```css
.card-hover {
  transition: box-shadow 0.2s ease, transform 0.2s ease;
}
.card-hover:hover {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.06);
  transform: translateY(-1px);
}
```

Use this class directly rather than reimplementing it. For custom hover lifts:

```typescript
// Use Tailwind's transition-[property] for multi-property transitions
<div className="transition-[box-shadow,transform] duration-200 ease-out hover:-translate-y-0.5 hover:shadow-md">
```

### Multi-property transitions (shadcn input pattern)

```typescript
// From components/ui/input.tsx — the established pattern for interactive inputs
className="transition-[color,box-shadow] duration-150"
// + focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50
```

---

## Micro-interactions

### Loading states

```typescript
// Skeleton for async content — use shadcn Skeleton component
import { Skeleton } from "@/components/ui/skeleton"

function KpiCardSkeleton() {
  return (
    <div className="flex flex-col gap-4 rounded-xl border bg-card p-6">
      <Skeleton className="h-4 w-24" />
      <Skeleton className="h-8 w-32" />
      <Skeleton className="h-3 w-20" />
    </div>
  )
}
```

### Button loading state

```typescript
import { Loader2 } from "lucide-react"

<Button disabled={isLoading}>
  {isLoading && <Loader2 className="animate-spin" />}
  {isLoading ? "Saving..." : "Save"}
</Button>
```

`animate-spin` is a Tailwind built-in — it's fine for single spinner icons.

### Enter animations with tw-animate-css

```typescript
// Fade in on mount — useful for page content after data loads
<div className="animate-in fade-in duration-300">
  {data && <DataTable rows={data} />}
</div>

// Slide in from top — for notifications, alerts
<div className="animate-in slide-in-from-top-2 duration-200">
  <Alert>{message}</Alert>
</div>
```

---

## CSS Hover Effects

```typescript
// Table row hover — subtle, no transform
<tr className="transition-colors hover:bg-muted/50 cursor-pointer">

// Sidebar item — color change only
<Link className="transition-colors hover:bg-[--sidebar-accent] hover:text-[--sidebar-accent-foreground]">

// Card with lift — use card-hover class
<div className="card-hover rounded-xl border bg-card shadow-sm">

// Icon button — scale on hover
<button className="transition-transform hover:scale-105 active:scale-95">
  <RefreshCw className="size-4" />
</button>
```

---

## Performance Rules

**NEVER animate properties that trigger layout:**

```typescript
// BAD — animating these causes reflow on every frame (janky)
// width, height, top, left, margin, padding, font-size

// GOOD — GPU-composited, no reflow
// transform (translate, scale, rotate)
// opacity
// filter
// box-shadow (careful — still composited but expensive)
```

**Reduce motion support:**

```css
/* Add to globals.css for accessibility */
@media (prefers-reduced-motion: reduce) {
  .card-hover {
    transition: none;
  }
  .card-hover:hover {
    transform: none;
  }
}
```

Or use Tailwind:

```typescript
<div className="transition-[box-shadow,transform] motion-reduce:transition-none hover:-translate-y-0.5 motion-reduce:hover:translate-y-0">
```

**Keep durations short for a productivity tool:**
- Color transitions: 100-150ms
- Lift/shadow: 200ms
- Page-level enters: 250-300ms
- NEVER exceed 400ms for UI feedback — users are waiting to work, not watching demos
