---
date: 2026-04-20
decision: Cleanup batch — permissions hardening + orphan file + mundi dead refs + build-toolkit-scout error handling
affects: [mac, achilles, monorepo-not-affected, toolkit-repo]
reversible: yes
---

# Final cleanup — items 9-12

Small-scope follow-ups from the audit pass. Batched together because each is ≤5 lines of change.

## Item 9 — Permissions hardening

Added 9 deny rules to `~/.claude/settings.json` (Mac) and `/home/mundi/.claude/settings.json` (Achilles):

**Destructive-rm guards** (belt-and-braces; `Bash(rm *)` is allowed, but these specific home/root wipes should never slip through):
- `Bash(rm -rf /)`
- `Bash(rm -rf ~)`
- `Bash(rm -rf ~/*)`
- `Bash(rm -rf $HOME)`
- `Bash(rm -rf $HOME/*)`

**Retired-MCP denies** (defense-in-depth — if a plugin update ever re-registers these, they'll fail rather than auto-run):
- `mcp__unusualwhales__*`
- `mcp__explorium__*`
- `mcp__google-sheets__*`
- `mcp__capiq__*` (orphan client registration; the active capiq lives under the merged `apps/capiq-mcp/`)

Deny list deduplicated via `| unique` so re-runs don't create drift.

## Item 10 — Orphan SKILL.md on Achilles

Deleted `/home/mundi/.claude/skills/SKILL.md` — a 4KB stray file at the skills dir root (content was a duplicate of `saraev-cc-btw-mid-task-aside/SKILL.md`). The real directory stayed intact. Mac/Achilles skill-count parity now exact (1108/1108 — was 1108/1107 with the orphan counted).

## Item 11 — Mundi command dead refs

**`~/.claude/commands/mundi/claude-md-audit.md`** — fixed line 6 stale path:
```
~/.claude/MEMORY.md   →   ~/.claude/projects/-Users-mundiprinceps-Mundi-Princeps/memory/MEMORY.md
```

**`~/.claude/commands/mundi/router-hub.md`** — three fixes:
1. Line 9: removed stale "(forward-reference to Wave 2B build)" — router-hub shipped 2026-04-19; added note that wrapper `~/.claude/scripts/route.sh` is the canonical entrypoint.
2. Line 19: `Task(subagent_type="general-purpose", ...)` → `Task(subagent_type="router-hub", ...)` (agent exists at `~/.claude/agents/router-hub.md`).
3. Line 28: updated "Until 2B ships, use toolkit-scout" note to reflect that router-hub has shipped + pointer to 2026-04-20 router-hub fixes.

## Item 12 — `build-toolkit-scout.sh` malformed-JSON handling

Added three error-path guards to the Python block inside the script:

1. `json.JSONDecodeError` → prints `toolkit-scout: registry is malformed JSON at <path>: <error>` to stderr + re-run hint + `exit 2`.
2. Registry root not a dict → prints `registry root is <type>, expected object` + `exit 2`.
3. Empty `items` list → prints `WARNING — registry has 0 items. Output will be a placeholder.` to stderr but still completes (intentional — empty registry is a valid intermediate state during rebuild).

Happy path regression-free: `bash ~/.claude/scripts/build-toolkit-scout.sh` still produces the usual `wrote 171 lines, 1821 items` output. Synced to Achilles, regenerated there (`172 lines, 1825 items`).

## Verification

```bash
# Permissions
jq '.permissions.deny | length' ~/.claude/settings.json                           # ≥ 14 (was 5)
ssh achilles-mundi 'jq ".permissions.deny | length" /home/mundi/.claude/settings.json'  # ≥ 14

# Orphan gone
ssh achilles-mundi 'ls /home/mundi/.claude/skills/SKILL.md 2>&1 | head -1'
# → ls: ... No such file or directory

# Mundi commands
grep "projects/.*memory/MEMORY.md" ~/.claude/commands/mundi/claude-md-audit.md     # → line 6
grep 'subagent_type="router-hub"' ~/.claude/commands/mundi/router-hub.md           # → line 19

# build-toolkit-scout error handling
bash ~/.claude/scripts/build-toolkit-scout.sh 2>&1 | tail -1
# → [toolkit-scout] wrote /Users/mundiprinceps/.claude/skills/toolkit-scout/SKILL.md (171 lines, 1821 items)

# Malformed JSON path — not trivially testable without temporarily mv'ing registry.json;
# inspection confirms the try/except + clean exit 2 is in place at lines 21-26 of
# build-toolkit-scout.sh.
```

## How to reverse

Permissions: `jq '.permissions.deny -= [...]' ~/.claude/settings.json` with the 9 added rules listed.
Orphan file: file deleted, re-create from `~/.claude/skills/saraev-cc-btw-mid-task-aside/SKILL.md` if needed.
Mundi commands: `git checkout <prior-sha> -- commands/mundi/claude-md-audit.md commands/mundi/router-hub.md` in toolkit-catalog.
build-toolkit-scout: same — `git checkout` in toolkit-catalog.

## Related

- Companion decisions this session (items 1-8): context-mode, dialogue-gate, gws-dedup, linkdrop-3-rewrites, router-hub-fixes, kb-indexing-hygiene, app-claude-md-contradictions, claude-mem-disabled, global-claude-md-trim.
- This closes the audit's punch list. All 12 flagged items addressed.
