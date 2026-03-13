# Layouts Reference

## Contents
- Dashboard Layout Structure
- KPI Grid Patterns
- Sidebar Layout
- Responsive Breakpoints
- Spacing Conventions

---

## Dashboard Layout Structure

Kadenwood uses Next.js App Router nested layouts. The root layout (`app/layout.tsx`) wraps everything in `<Providers>` for theme context. Page-level layouts handle the sidebar + content split.

```typescript
// app/layout.tsx — root: theme provider, font, global CSS
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className="font-sans antialiased">
        <Providers>{children}</Providers>
      </body>
    </html>
  )
}

// app/(dashboard)/layout.tsx — dashboard shell pattern
export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex h-screen overflow-hidden bg-background">
      <Sidebar />
      <main className="flex-1 overflow-y-auto">
        <div className="container mx-auto px-6 py-8">
          {children}
        </div>
      </main>
    </div>
  )
}
```

The sidebar uses its own token group (`--sidebar`, `--sidebar-foreground`, etc.) — this allows sidebar theming independent of the main content area.

---

## KPI Grid Patterns

269 KPIs require a consistent, scalable grid. Use CSS Grid with responsive column counts:

```typescript
// Standard KPI grid — 1 col mobile, 2 tablet, 4 desktop
<div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
  {kpis.map((kpi) => <KpiCard key={kpi.id} {...kpi} />)}
</div>

// Wide metric cards — 2 cols at lg, full width at md
<div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
  <RevenueChart />
  <PipelineChart />
</div>

// Section with header + grid
<section className="space-y-4">
  <div className="flex items-center justify-between">
    <h2 className="text-lg font-semibold">Deal Pipeline</h2>
    <Button variant="outline" size="sm">Export</Button>
  </div>
  <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-3">
    {/* cards */}
  </div>
</section>
```

**Gap scale**: Use `gap-4` (16px) within sections, `gap-6` (24px) between sections. Consistent rhythm prevents the dashboard from feeling cluttered.

---

## Sidebar Layout

The sidebar uses dedicated CSS custom property tokens from Tailwind v4's `@theme`:

```typescript
// Sidebar uses --sidebar-* tokens, not bg-card/bg-background
<aside className="w-64 border-r bg-[--sidebar] text-[--sidebar-foreground] flex flex-col">
  <nav className="flex-1 px-3 py-4 space-y-1">
    <SidebarItem href="/dashboard" icon={LayoutDashboard}>
      Dashboard
    </SidebarItem>
    <SidebarItem href="/deals" icon={Briefcase}>
      Deals
    </SidebarItem>
  </nav>
</aside>

// Active state uses sidebar-primary tokens
function SidebarItem({ href, icon: Icon, children }: SidebarItemProps) {
  const isActive = usePathname() === href
  return (
    <Link
      href={href}
      className={cn(
        "flex items-center gap-3 rounded-md px-3 py-2 text-sm font-medium transition-colors",
        isActive
          ? "bg-[--sidebar-primary] text-[--sidebar-primary-foreground]"
          : "text-[--sidebar-foreground] hover:bg-[--sidebar-accent] hover:text-[--sidebar-accent-foreground]"
      )}
    >
      <Icon className="size-4 shrink-0" />
      {children}
    </Link>
  )
}
```

---

## Responsive Breakpoints

Tailwind's default breakpoints — mobile-first:

| Breakpoint | Min-width | Use for |
|------------|-----------|---------|
| (none) | 0px | Mobile — single column |
| `sm:` | 640px | Large phones — 2 columns |
| `md:` | 768px | Tablets — show sidebar |
| `lg:` | 1024px | Desktop — full dashboard |
| `xl:` | 1280px | Wide desktop — extra columns |

```typescript
// Mobile-first pattern: hide sidebar on mobile
<aside className="hidden md:flex w-64 flex-col border-r bg-[--sidebar]">

// Stack on mobile, side-by-side on desktop
<div className="flex flex-col gap-4 lg:flex-row">
  <div className="lg:w-2/3">{/* main content */}</div>
  <div className="lg:w-1/3">{/* sidebar panel */}</div>
</div>
```

---

## Spacing Conventions

Kadenwood uses a consistent spatial hierarchy. Don't invent new spacing values.

```
Within a card:     p-6, gap-4    (24px padding, 16px gaps)
Between cards:     gap-4 / gap-6
Between sections:  mb-8 / space-y-8
Page padding:      px-6 py-8
Table cells:       px-4 py-3
```

```typescript
// Standard page structure
<div className="space-y-8">
  <PageHeader />
  <section className="space-y-4">
    <SectionTitle />
    <CardGrid />
  </section>
  <section className="space-y-4">
    <SectionTitle />
    <DataTable />
  </section>
</div>
```

### WARNING: Don't use arbitrary spacing values

```typescript
// BAD — breaks the visual rhythm, not on the 4px grid
<div className="mb-[22px] p-[14px]">

// GOOD — stays on the spacing scale
<div className="mb-6 p-4">
```

Arbitrary values are acceptable only for pixel-perfect positioning of decorative elements, never for structural spacing.

For Next.js App Router layout patterns, see the **nextjs** skill.
