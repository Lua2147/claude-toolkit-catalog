# TypeScript Modules Reference

## Contents
- Path aliases and import conventions
- Barrel exports
- `'use client'` / `'use server'` directives
- Package boundaries in pnpm workspaces
- Module resolution: bundler mode

---

## Path Aliases

`tsconfig.json` defines `@/*` → `./` (from `apps/dashboard/`):

```typescript
// GOOD — absolute import via alias
import { handleAsync } from '@/lib/errors';
import { createClient } from '@/lib/database/client/browser';
import type { Database } from '@/lib/database/types';

// BAD — relative path hell, breaks on file moves
import { handleAsync } from '../../../lib/errors';
```

Always use `@/` for imports from within `apps/dashboard/`. Scripts in `scripts/` are excluded from tsconfig and use relative paths directly.

---

## Barrel Exports

Each feature directory exports via `index.ts`:

```typescript
// packages/database/src/index.ts
export * from './types';
export * from './client';

// packages/integrations/src/index.ts
export * from './google';
export * from './anthropic';
export * from './exa';
```

**Import from the package root, not internal files:**

```typescript
// GOOD — stable public API
import { createClient } from '@kadenwood/database';

// BAD — couples you to internal directory structure
import { createClient } from '@kadenwood/database/src/client/browser';
```

### WARNING: Circular Barrel Exports

Don't re-export everything in a barrel if modules depend on each other. When `a.ts` imports from `index.ts` which imports `b.ts` which imports `a.ts`, you get circular dependency crashes at runtime (Next.js fast refresh amplifies this).

**Fix:** Import directly from the source file when you have circular risk, or restructure so shared types live in a `types.ts` leaf (no imports of its own).

---

## `'use client'` and `'use server'` Directives

In Next.js App Router, module graph determines rendering context:

```typescript
// lib/stores/notifications.ts — client-only
'use client';

import { create } from 'zustand';
// Any import chain from here runs only in the browser
```

```typescript
// lib/database/client/server.ts — server-only
import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers'; // Next.js server-only API
// No 'use server' needed — server is the default in App Router
```

### WARNING: Importing Server Code into Client Components

```typescript
// BAD — cookies() crashes in the browser
'use client';
import { createClient } from '@/lib/database/client/server'; // imports cookies()
```

**Fix:** Use `@/lib/database/client/browser` in client components, `@/lib/database/client/server` in Server Components and Route Handlers.

---

## pnpm Workspace Package Boundaries

Kadenwood is a pnpm workspace with internal packages:

```
apps/kadenwood/
├── apps/dashboard/          — Next.js app
└── packages/
    ├── database/            — @kadenwood/database
    └── integrations/        — @kadenwood/integrations
```

Packages declare their public API in `package.json#exports`:

```json
{
  "name": "@kadenwood/database",
  "exports": {
    ".": "./src/index.ts"
  }
}
```

**Never import across package boundaries without going through `exports`.** Scripts that run outside the workspace (e.g., `kadenwood/scripts/*.ts`) use direct paths and are excluded from the main tsconfig.

---

## Module Resolution: Bundler Mode

`tsconfig.json` uses `"moduleResolution": "bundler"` (Next.js default). This means:

- Supports `exports` field in `package.json` (workspace packages work)
- Does NOT require file extensions in imports
- Resolves `index.ts` automatically from directory imports
- Does NOT support CommonJS `require()` — ESM only

```typescript
// GOOD — no extension needed with bundler resolution
import { createClient } from '@/lib/database/client';  // resolves index.ts

// BAD in this project — CommonJS style
const { createClient } = require('@/lib/database/client');
```

---

## Type-Only Imports

Use `import type` for types that are only needed at compile time — eliminates the import at runtime and prevents accidental value usage:

```typescript
// GOOD — explicit type-only import
import type { Database } from '@/lib/database/types';
import type { TargetDisposition } from '@/lib/deals/target-dispositions';

// Only needed if you use both type and value from the same module
import { handleAsync, type AsyncResult } from '@/lib/errors';
```

`isolatedModules: true` in tsconfig enforces that type-only re-exports use `export type`, which catches issues where a type import gets bundled as a value.
