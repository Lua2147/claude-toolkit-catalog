---
name: mundi-orch-board-materials
description: Generate board-discussion materials end-to-end from a data room — ingest (Drive/SharePoint) → Gemini-powered summarization → pitch-deck generation → Q&A prep → artifact bundle. Use when prepping for a board meeting, IC discussion, or investor update where you have a raw data room and need polished materials.
allowed-tools: Read, Write, Edit, Bash, Task, Grep, Glob, mcp__gws__*, mcp__ms365__*, WebFetch
---

# Mundi Orch — Board Materials

## Overview

Converts a data room into board-ready materials. Addresses the pattern: you have 40 PDFs / a shared Drive folder / a SharePoint site full of deal or portfolio docs, and you need a synthesized deck + talking points + Q&A prep within hours, not days.

Input: data room reference (Google Drive folder ID, SharePoint site, or local path)
Output: polished deck (PPTX), talking-points markdown, anticipated-Q&A document, source-map JSON

## When to use

- Board meeting prep on a specific portfolio company or deal
- IC discussion materials for a new deal
- Investor update bundle (quarterly, one-off)
- Post-mortem on a closed deal
- Any "here's a bunch of docs, I need a coherent narrative by [tight deadline]"

Skip if:
- Single document summary — use `document-skills:docx` or `document-skills:pdf` directly
- Net-new content creation from scratch (no data room) — use `investment-banking:pitch-deck` from scratch

## Pipeline (7 steps)

```
[1] Data room inventory     → list all files in Drive folder / SharePoint, classify by type
[2] Extract text            → docx/pptx/pdf → plain text (document-skills plugin)
[3] Gemini synthesis        → long-context summarization across all docs (Gemini 3.1 Pro handles it)
[4] Narrative assembly      → top-level story arc + key evidence per slide
[5] Deck generation         → investment-banking:pitch-deck OR financial-analysis:ppt-template
[6] Talking points + Q&A    → anticipate top questions + prep 1-sentence answers with citation
[7] Bundle + deliver        → upload to Drive folder, email/link to user
```

## I/O contract (MWP)

**state_reads:**
- Data room: Google Drive (via `mcp__gws__*`) or SharePoint (via `mcp__ms365__*`)
- `config/token.json` — Google OAuth for gws
- `~/.claude/projects/.../memory/project_board_discussion_v4*.md` — prior board-material patterns (Fantuan deal)
- `~/.claude/projects/.../memory/project_wwc_engagement.md` — WWC engagement scope

**state_writes:**
- `docs/board-materials/<company>-<date>/` — working directory
  - `source-map.json` — file → summary mapping with citations
  - `narrative.md` — top-level story arc
  - `deck.pptx` — board deck
  - `talking-points.md` — per-slide talking points
  - `q-and-a.md` — anticipated Qs with prepped answers
  - `bundle-upload-log.json` — Drive/SharePoint upload metadata

## Composition

| step | tool |
|---|---|
| Drive inventory | `mcp__gws__listFolderContents`, `mcp__gws__getFolderInfo` |
| SharePoint inventory | `mcp__ms365__list-sharepoint-site-items`, `get-sharepoint-site-drive-by-id` |
| PDF extract | `document-skills:pdf` |
| DOCX extract | `document-skills:docx` |
| PPTX extract | `document-skills:pptx` |
| Gemini synthesis | `~/.claude/skills/video-to-action/scripts/analyze-youtube.sh`-pattern adapted (Gemini Files API + long-context) |
| Deck generation | `investment-banking:pitch-deck` OR `financial-analysis:ppt-template-creator` |
| Chart generation | `financial-analysis:3-statements`, `financial-analysis:comps-analysis` (if financial data in data room) |
| Upload back | `mcp__gws__createDocument`, `mcp__gws__createFromTemplate` |

## Gemini pattern

Because most data rooms exceed Claude's practical working set, the synthesis step MUST use Gemini 3.1 Pro (1M context). Adapt the curl pattern from `~/.claude/skills/video-to-action/scripts/analyze-youtube.sh`:

```bash
# Upload docs to Gemini Files API, then single call with full context
# (or use the existing analyze-youtube.sh pattern, adapted for multi-doc)
```

## Failure modes

| failure | recovery |
|---|---|
| Drive folder not accessible | check OAuth scope; fall back to SharePoint if duplicated |
| Gemini Files API upload fails on one doc | proceed with rest, log skipped doc |
| Long-context summarization fails (too many docs) | shard by topic (financials / team / market / diligence) and synthesize per-shard first |
| Deck generator errors on unusual chart data | flag for manual review; produce skeleton deck with text only |

## Invocation

```python
Skill(skill="mundi-orch-board-materials", {
  source: "drive://1aB2c3D4e..." | "sharepoint://<site>/data-room",
  company: "Fantuan",
  meeting_type: "IC" | "board" | "investor_update",
  deadline: "2026-05-01T14:00:00",
  output_dir: "docs/board-materials/fantuan-2026-05-01/"
})
```

## Output contract

```json
{
  "run_id": "fantuan-2026-05-01",
  "data_room_files_processed": 42,
  "pages_summarized": 1847,
  "deck_path": "docs/board-materials/fantuan-2026-05-01/deck.pptx",
  "deck_slides": 22,
  "talking_points_path": "...",
  "q_and_a_path": "...",
  "source_map_path": "...",
  "gaps": ["3 PDFs had OCR issues", "financials table on slide 14 needs manual verify"],
  "upload_urls": {"drive_folder": "..."}
}
```

## Cross-references

- **Paired skill:** none currently (no `/mundi:board-materials` slash command yet — may add)
- **Memory:** `project_board_discussion_v4.md`, `project_board_discussion_v4_session1.md` (Fantuan deal context), `project_wwc_engagement.md`
- **Plugin skills:** `investment-banking:pitch-deck`, `investment-banking:cim`, `financial-analysis:ppt-template-creator`, `financial-analysis:3-statements`, `document-skills:pdf`, `document-skills:docx`, `document-skills:pptx`
- **Related:** `/mundi:investor-portal` (portal UI for materials), `financial-analysis:check-deck` (deck review)
- **Plan source:** `docs/plans/2026-04-19-phase-3-final.md` line 868

## Safety

- Never email / share externally without human sign-off. Artifacts live in a private Drive folder.
- Source-map must be preserved — every claim in the deck must trace to a data-room doc.
- If the data room contains sensitive info (PII, financials), work in a private Drive folder with restricted sharing.
