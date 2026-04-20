---
date: 2026-04-20
decision: KB indexing hygiene pass — delete 2 ghost dirs, move 1 misplaced file, create 2 INDEX.md, update 5 INDEX.md, refresh master INDEX.md
affects: [monorepo, kb, achilles]
reversible: yes (via git revert in monorepo)
---

# Knowledge base indexing hygiene — 2026-04-20 pass

## Decision

Mechanical housekeeping on `docs/knowledge-base/` to make navigation actually work. No content was deleted — only moved, indexed, or categorized.

### Structural changes (destructive but benign)

1. **Deleted empty ghost dir** `wiki/04-lead-generation-and-outreach/` — was a zero-file duplicate of `wiki/04-lead-generation/`.
2. **Moved misplaced file** `wiki/06-design/linkdrop-x-ghumare64-awesome-claude-design.md` → `wiki/06-web-design-frontend/linkdrop-x-ghumare64-awesome-claude-design.md`. Then deleted the now-empty `wiki/06-design/`. (Canonical is `06-web-design-frontend/`; `06-design/` was a silo mistake.)

### Files created

1. `wiki/00-indexes/INDEX.md` — previously missing. Directory had 4 files + transcripts/ subdir without an index.
2. `outputs/INDEX.md` — previously missing. Directory had 83 .md files (Phase 1/2/3 reports, reviews, Saraev catalog, audits) invisible to navigation. Grouped by prefix.

### Files updated

1. `wiki/01-ai-development-and-agents/INDEX.md` — added "Linkdrops & External Reading" section listing 7 orphan files (gregpr07, shabnam, tom-doerr-council, tomdoerr-gnhf, vmlops, anthropic-best-practices, openmythos-moe).
2. `wiki/02-workflow-and-dx/INDEX.md` — added 4 orphan linkdrops (0x-kaize, avichawla, khairallah, tom-doerr-self-learning) + promoted `token-optimization.md` from Related to Files section.
3. `wiki/04-lead-generation/INDEX.md` — added 2 orphans (4.2-saraev-outbound-pipelines, levikmunneke-volume-critique) as first-class file entries rather than Related-only.
4. `wiki/06-web-design-frontend/INDEX.md` — added 3 orphans (design-skills-selection-guide, claude-design-scorecard-2026-04, marcelkargul-design-prompt) + the moved ghumare64 linkdrop.
5. `wiki/07-video-media-production/INDEX.md` — promoted `content-engine-selection-guide.md` from Related to Files.
6. `docs/knowledge-base/INDEX.md` (master) — replaced stale header (claimed "155+ skills", said 2026-04-19 env) with current counts ("1,108 skills, 171 agents, 29 /mundi:* commands, 24+ MCPs, 201 scripts, 2026-04-20"), added pointers to new `00-indexes/INDEX.md` and existing `00-workflows/INDEX.md`, rewrote Raw section to reflect actual subdirs, added `project-scoped google-workspace MCP` to the Legacy/Removed section (deduplicated 2026-04-20).

## Rationale

The wiki became discoverable through INDEX.md files, but ~25 orphan entries across 5 categories + 83 unindexed outputs meant humans browsing the KB couldn't find recently-added content. Master index counts were stale. Two ghost directories (`06-design/`, `04-lead-generation-and-outreach/`) violated the CLAUDE.md rule "Every subcategory has an INDEX.md".

No content loss, no behavior change — just making the docs match disk state.

## Verification

```bash
# Ghost dirs gone
ls docs/knowledge-base/wiki/ | grep -E "06-design|04-lead-generation-and-outreach"
# → (no output; only 06-web-design-frontend and 04-lead-generation remain)

# ghumare64 in new location
ls docs/knowledge-base/wiki/06-web-design-frontend/ | grep ghumare64
# → linkdrop-x-ghumare64-awesome-claude-design.md

# Every wiki/<category>/ has INDEX.md
for d in docs/knowledge-base/wiki/*/; do test -f "$d/INDEX.md" || echo "MISSING: $d"; done
# → (no output)

# Orphan check: every .md file in a category dir is now referenced in its INDEX.md
for d in docs/knowledge-base/wiki/01-ai-development-and-agents docs/knowledge-base/wiki/02-workflow-and-dx docs/knowledge-base/wiki/04-lead-generation docs/knowledge-base/wiki/06-web-design-frontend docs/knowledge-base/wiki/07-video-media-production; do
  for f in "$d"/*.md; do
    base=$(basename "$f")
    [ "$base" = "INDEX.md" ] && continue
    grep -q "$base" "$d/INDEX.md" || echo "ORPHAN: $d/$base"
  done
done
# → (no output expected)

# outputs INDEX has all 83 files referenced
ls docs/knowledge-base/outputs/*.md | wc -l   # 84 (83 entries + INDEX.md itself)
grep -c "^- \[" docs/knowledge-base/outputs/INDEX.md   # ≥ 83
```

## How to reverse

All changes are tracked in monorepo git. To revert:
```bash
cd "/Users/mundiprinceps/Mundi Princeps"
git log --oneline docs/knowledge-base/ | head -5
# git checkout <sha>~1 -- docs/knowledge-base/
```

## Related

- Parent audit: inline KB indexing audit 2026-04-20.
- CLAUDE.md rule invoked: `docs/knowledge-base/CLAUDE.md` — "Every subcategory has an INDEX.md. `outputs/` is derived. Each file states what it's derived from."
- Linkdrop skills rewrite: `2026-04-20-linkdrop-3-rewrites.md` (which updated the SKILL.md files that some of these INDEX entries reference).
