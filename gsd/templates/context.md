# Phase Context Template

Template for `.planning/phases/XX-name/{phase_num}-CONTEXT.md` - captures implementation decisions for a phase.

**Purpose:** Document decisions that downstream agents need. Researcher uses this to know WHAT to investigate. Planner uses this to know WHAT choices are locked vs flexible.

**Key principle:** Categories are NOT predefined. They emerge from what was actually discussed for THIS phase. A CLI phase has CLI-relevant sections, a UI phase has UI-relevant sections.

**Downstream consumers:**
- `gsd-phase-researcher` — Reads decisions to focus research (e.g., "card layout" → research card component patterns)
- `gsd-planner` — Reads decisions to create specific tasks (e.g., "infinite scroll" → task includes virtualization)

---

## File Template

```markdown
# Phase [X]: [Name] - Context

**Gathered:** [date]
**Status:** Ready for planning

<domain>
## Phase Boundary

[Clear statement of what this phase delivers — the scope anchor. This comes from ROADMAP.md and is fixed. Discussion clarifies implementation within this boundary.]

</domain>

<decisions>
## Implementation Decisions

### [Area 1 that was discussed]
- [Specific decision made]
- [Another decision if applicable]

### [Area 2 that was discussed]
- [Specific decision made]

### [Area 3 that was discussed]
- [Specific decision made]

### Claude's Discretion
[Areas where user explicitly said "you decide" — Claude has flexibility here during planning/implementation]

</decisions>

<specifics>
## Specific Ideas

[Any particular references, examples, or "I want it like X" moments from discussion. Product references, specific behaviors, interaction patterns.]

[If none: "No specific requirements — open to standard approaches"]

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- [Component/hook/utility]: [How it could be used in this phase]

### Established Patterns
- [Pattern]: [How it constrains/enables this phase]

### Integration Points
- [Where new code connects to existing system]

</code_context>

<io_contract>
## Phase I/O Contract

### Inputs (what this phase consumes)
- **From prior phases:** [List specific artifacts/exports this phase depends on, e.g., "Phase 01 SUMMARY.md → auth middleware path", "Phase 02 → User model type"]
- **External data:** [APIs, files, configs this phase reads, e.g., "config/api_keys.json → Stripe keys"]
- **Existing code:** [Source files this phase builds on, e.g., "src/lib/db.ts → database client"]

### Outputs (what this phase produces)
- **Artifacts:** [Files created/modified with their purpose, e.g., "src/features/chat/Chat.tsx → message list component"]
- **Exports:** [Types, functions, APIs downstream phases can consume, e.g., "ChatMessage type", "POST /api/chat endpoint"]
- **State mutations:** [Planning artifacts updated, e.g., "STATE.md → position, decisions", "ROADMAP.md → plan checkboxes"]

### Consumed by
- [Which future phases depend on this phase's outputs, e.g., "Phase 4 (notifications) needs ChatMessage type", "Phase 5 (admin) needs /api/chat endpoint"]

[If unknown: "No known downstream consumers yet"]

</io_contract>

<deferred>
## Deferred Ideas

[Ideas that came up during discussion but belong in other phases. Captured here so they're not lost, but explicitly out of scope for this phase.]

[If none: "None — discussion stayed within phase scope"]

</deferred>

---

*Phase: XX-name*
*Context gathered: [date]*
```

<good_examples>

**Example 1: Visual feature (Post Feed)**

```markdown
# Phase 3: Post Feed - Context

**Gathered:** 2025-01-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Display posts from followed users in a scrollable feed. Users can view posts and see engagement counts. Creating posts and interactions are separate phases.

</domain>

<decisions>
## Implementation Decisions

### Layout style
- Card-based layout, not timeline or list
- Each card shows: author avatar, name, timestamp, full post content, reaction counts
- Cards have subtle shadows, rounded corners — modern feel

### Loading behavior
- Infinite scroll, not pagination
- Pull-to-refresh on mobile
- New posts indicator at top ("3 new posts") rather than auto-inserting

### Empty state
- Friendly illustration + "Follow people to see posts here"
- Suggest 3-5 accounts to follow based on interests

### Claude's Discretion
- Loading skeleton design
- Exact spacing and typography
- Error state handling

</decisions>

<specifics>
## Specific Ideas

- "I like how Twitter shows the new posts indicator without disrupting your scroll position"
- Cards should feel like Linear's issue cards — clean, not cluttered

</specifics>

<io_contract>
## Phase I/O Contract

### Inputs
- **From Phase 02:** User model type, auth middleware (for identifying current user)
- **Existing code:** `src/lib/db.ts` → database client, `src/components/Avatar.tsx` → user avatar component

### Outputs
- **Artifacts:** `src/features/feed/Feed.tsx`, `src/features/feed/PostCard.tsx`, `src/app/api/feed/route.ts`
- **Exports:** `PostCard` component (reusable), `GET /api/feed` endpoint, `Post` TypeScript type
- **State mutations:** STATE.md → position updated, ROADMAP.md → Phase 3 plans checked

### Consumed by
- Phase 5 (comments) needs PostCard component and Post type
- Phase 7 (search) needs Post type for search results

</io_contract>

<deferred>
## Deferred Ideas

- Commenting on posts — Phase 5
- Bookmarking posts — add to backlog

</deferred>

---

*Phase: 03-post-feed*
*Context gathered: 2025-01-20*
```

**Example 2: CLI tool (Database backup)**

```markdown
# Phase 2: Backup Command - Context

**Gathered:** 2025-01-20
**Status:** Ready for planning

<domain>
## Phase Boundary

CLI command to backup database to local file or S3. Supports full and incremental backups. Restore command is a separate phase.

</domain>

<decisions>
## Implementation Decisions

### Output format
- JSON for programmatic use, table format for humans
- Default to table, --json flag for JSON
- Verbose mode (-v) shows progress, silent by default

### Flag design
- Short flags for common options: -o (output), -v (verbose), -f (force)
- Long flags for clarity: --incremental, --compress, --encrypt
- Required: database connection string (positional or --db)

### Error recovery
- Retry 3 times on network failure, then fail with clear message
- --no-retry flag to fail fast
- Partial backups are deleted on failure (no corrupt files)

### Claude's Discretion
- Exact progress bar implementation
- Compression algorithm choice
- Temp file handling

</decisions>

<specifics>
## Specific Ideas

- "I want it to feel like pg_dump — familiar to database people"
- Should work in CI pipelines (exit codes, no interactive prompts)

</specifics>

<io_contract>
## Phase I/O Contract

### Inputs
- **From Phase 01:** Database connection abstraction, config module
- **External data:** Database connection string (env var or CLI arg)

### Outputs
- **Artifacts:** `src/commands/backup.ts`, `src/lib/backup-engine.ts`
- **Exports:** `backup` CLI command, `BackupResult` type, `createBackup()` function
- **State mutations:** STATE.md → position, decisions

### Consumed by
- Phase 3 (restore) needs BackupResult type and backup file format
- Phase 5 (scheduled backups) needs createBackup() function

</io_contract>

<deferred>
## Deferred Ideas

- Scheduled backups — separate phase
- Backup rotation/retention — add to backlog

</deferred>

---

*Phase: 02-backup-command*
*Context gathered: 2025-01-20*
```

**Example 3: Organization task (Photo library)**

```markdown
# Phase 1: Photo Organization - Context

**Gathered:** 2025-01-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Organize existing photo library into structured folders. Handle duplicates and apply consistent naming. Tagging and search are separate phases.

</domain>

<decisions>
## Implementation Decisions

### Grouping criteria
- Primary grouping by year, then by month
- Events detected by time clustering (photos within 2 hours = same event)
- Event folders named by date + location if available

### Duplicate handling
- Keep highest resolution version
- Move duplicates to _duplicates folder (don't delete)
- Log all duplicate decisions for review

### Naming convention
- Format: YYYY-MM-DD_HH-MM-SS_originalname.ext
- Preserve original filename as suffix for searchability
- Handle name collisions with incrementing suffix

### Claude's Discretion
- Exact clustering algorithm
- How to handle photos with no EXIF data
- Folder emoji usage

</decisions>

<specifics>
## Specific Ideas

- "I want to be able to find photos by roughly when they were taken"
- Don't delete anything — worst case, move to a review folder

</specifics>

<io_contract>
## Phase I/O Contract

### Inputs
- **External data:** Photo library directory path (user-provided), EXIF metadata from image files
- **Existing code:** None — first phase

### Outputs
- **Artifacts:** `src/organizer.py`, `src/exif_reader.py`, `src/duplicate_detector.py`
- **Exports:** `organize()` function, `PhotoMetadata` type, folder structure convention (YYYY/MM/event/)
- **State mutations:** STATE.md → position, decisions (clustering algorithm, naming convention)

### Consumed by
- Phase 2 (tagging) needs PhotoMetadata type and organized folder structure
- Phase 3 (search) needs folder convention for indexing

</io_contract>

<deferred>
## Deferred Ideas

- Face detection grouping — future phase
- Cloud sync — out of scope for now

</deferred>

---

*Phase: 01-photo-organization*
*Context gathered: 2025-01-20*
```

</good_examples>

<guidelines>
**This template captures DECISIONS for downstream agents.**

The output should answer: "What does the researcher need to investigate? What choices are locked for the planner?"

**Good content (concrete decisions):**
- "Card-based layout, not timeline"
- "Retry 3 times on network failure, then fail"
- "Group by year, then by month"
- "JSON for programmatic use, table for humans"

**Bad content (too vague):**
- "Should feel modern and clean"
- "Good user experience"
- "Fast and responsive"
- "Easy to use"

**I/O contract section:**
- Declare what this phase consumes (prior phase outputs, external data, existing code)
- Declare what this phase produces (artifacts, exports, state mutations)
- Declare who consumes this phase's outputs (downstream phases)
- Enables automatic context assembly — planner knows exactly what to wire up
- Enables debugging — when output is wrong, trace back to which input was missing

**After creation:**
- File lives in phase directory: `.planning/phases/XX-name/{phase_num}-CONTEXT.md`
- `gsd-phase-researcher` uses decisions to focus investigation
- `gsd-planner` uses decisions + research + I/O contract to create executable tasks with correct wiring
- Downstream agents should NOT need to ask the user again about captured decisions
</guidelines>
