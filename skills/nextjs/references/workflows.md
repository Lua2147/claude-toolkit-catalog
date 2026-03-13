# Next.js Workflows Reference

## Contents
- Adding a new CRM entity page
- Adding a new API route
- Regenerating Supabase TypeScript types
- Server Actions for mutations
- Build and deploy checklist

---

## Adding a New CRM Entity Page

Follow the pattern established by `companies`, `contacts`, `deals`, `capital-partners`.

Copy this checklist and track progress:
- [ ] Create `app/(dashboard)/[entity]/page.tsx` — list view, Server Component
- [ ] Create `app/(dashboard)/[entity]/[id]/page.tsx` — detail view, Server Component
- [ ] Create `app/(dashboard)/[entity]/loading.tsx` — skeleton
- [ ] Create `app/(dashboard)/[entity]/error.tsx` — must be `'use client'`
- [ ] Create `app/(dashboard)/[entity]/[id]/loading.tsx`
- [ ] Add to `(dashboard)/layout.tsx` navigation sidebar
- [ ] Run `pnpm build` — catch type errors before committing

**List page scaffold:**

```typescript
// app/(dashboard)/referral-partners/page.tsx
import { createClient } from '@/lib/supabase/server';
import { redirect } from 'next/navigation';
import { ReferralPartnersTable } from '@/components/relationships/referral-partners/referral-partners-table';

export default async function ReferralPartnersPage() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect('/login');

  const { data: partners, error } = await supabase
    .from('referral_partners')
    .select('*, owner:users!referral_partners_owner_id_fkey(id, first_name, last_name)')
    .order('created_at', { ascending: false });

  if (error) throw error;

  return <ReferralPartnersTable partners={partners ?? []} />;
}
```

**Detail page scaffold:**

```typescript
// app/(dashboard)/referral-partners/[id]/page.tsx
import { createClient } from '@/lib/supabase/server';
import { notFound, redirect } from 'next/navigation';

export default async function ReferralPartnerPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect('/login');

  const { data, error } = await supabase
    .from('referral_partners')
    .select('*, owner:users!referral_partners_owner_id_fkey(id, first_name, last_name)')
    .eq('id', id)
    .single();

  if (error || !data) notFound();

  return <ReferralPartnerDetail partner={data} />;
}
```

---

## Adding a New API Route

Route handlers live at `app/api/[path]/route.ts`. Auth validation is mandatory — the browser can call any API route directly.

```typescript
// app/api/sync/new-service/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';

export async function POST(req: NextRequest) {
  try {
    const supabase = await createClient();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

    const body = await req.json();
    // ... process body

    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('[sync/new-service] error:', error);
    return NextResponse.json(
      { error: error instanceof Error ? error.message : 'Internal server error' },
      { status: 500 }
    );
  }
}
```

**Webhook routes** (no auth, use secret validation instead):

```typescript
// app/api/webhooks/new-service/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { headers } from 'next/headers';

export async function POST(req: NextRequest) {
  const headersList = await headers();
  const secret = headersList.get('x-webhook-secret');
  if (secret !== process.env.WEBHOOK_SECRET) {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
  }
  // process webhook
  return NextResponse.json({ received: true });
}
```

---

## Regenerating Supabase TypeScript Types

Run this after any schema migration. Types live at `packages/database/src/types/database.ts`.

```bash
# From apps/kadenwood root
pnpm gen:types
```

This runs:
```
npx supabase gen types typescript --local | tail -n +2 > packages/database/src/types/database.ts
```

After regenerating, rebuild to catch any type errors:
```bash
pnpm build
```

For production schema (not local), see the **supabase** skill for the correct CLI command with `--project-id`.

---

## Server Actions for Mutations

For form submissions, prefer Server Actions over route handlers — they eliminate the API layer entirely and provide type safety end-to-end.

```typescript
// components/deals/deal-form.tsx
'use server';

import { createClient } from '@/lib/supabase/server';
import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import { z } from 'zod';

const DealSchema = z.object({
  name: z.string().min(1),
  tier: z.enum(['T1', 'T2', 'T3']),
  status: z.string(),
});

export async function createDeal(formData: FormData) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect('/login');

  const parsed = DealSchema.safeParse({
    name: formData.get('name'),
    tier: formData.get('tier'),
    status: formData.get('status'),
  });

  if (!parsed.success) {
    throw new Error(parsed.error.issues[0].message);
  }

  const { error } = await supabase.from('deals').insert({
    ...parsed.data,
    owner_id: user.id,
  });

  if (error) throw error;

  revalidatePath('/deals');
  redirect('/deals');
}
```

**NOTE:** This codebase uses `react-hook-form` + `zod` for complex forms. Server Actions work best for simple CRUD operations. For complex multi-step forms with real-time validation, keep the form as a Client Component and use Server Actions only for the submit handler.

---

## Build and Deploy Checklist

Always run before committing significant changes:

```bash
cd apps/kadenwood/apps/dashboard
pnpm build          # Must pass — type errors = CI failure
pnpm lint           # ESLint with next/core-web-vitals rules
pnpm test:unit      # Vitest unit tests
```

For E2E before deploying to production:
```bash
pnpm test:e2e:lifecycle    # Core CRM lifecycle (deals, pipeline, contacts)
```

Deploy triggers automatically on push to `main` → Vercel production at `war.kadenwoodgroup.com`.
Push to `staging` → `kadenwood-staging.vercel.app`.

For Playwright E2E test authoring, see the **playwright** skill.
