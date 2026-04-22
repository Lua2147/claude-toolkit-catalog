---
name: link-drop-pipeline
description: META-DELIVERABLE — user drops a URL (article/YouTube/tweet/repo/tool), agent autonomously classifies + extracts + decides which of {new skill, agent, command, KB wiki entry, MEMORY append, CLAUDE.md update, registry refresh, autoresearch propagation} apply, writes additively, commits once, rsyncs to Achilles. Replaces monthly R&D marathons.
source: Phase 3 Wave 3A meta-deliverable; builds on router-hub + video-to-action + autoresearch-evolve + akshay-harnessed-agent-arch
allowed-tools: Read, Write, Edit, Bash, WebFetch, Glob, Grep
---

# link-drop-pipeline

## Overview

The meta-pattern: you see a good URL (tweet, repo, blog post, YouTube video) and want it captured into your toolkit RIGHT NOW without a 6-hour R&D session. You drop the URL, the agent does everything: fetch → classify → extract → dedupe against existing 600+ skills → write new skill/agent/command/KB/MEMORY/CLAUDE.md updates → refresh router registry → run autoresearch-evolve on 3-5 related skills → single commit → rsync to Achilles → log decision trail.

This replaces the monthly R&D marathon (captured in `docs/snapshots/rd-session-2a672502-handoff.md`) with a 5-minute per-URL primitive. When aggregated across a week of daily drops, it recreates the marathon outcomes incrementally.

## When to use

- You just saw a tweet/repo/post worth capturing
- You don't want to stop what you're doing to build a skill
- You want the toolkit to grow passively, not from sprint-style marathons
- You have Gemini key + X bearer token + Achilles SSH working
- `router-hub` is built (reads registry)
- `autoresearch-evolve` is available (to propagate learnings)

## Workflow

**Step 0 — URL pre-scan (security):** scan raw URL for secret query-params BEFORE fetching:

```python
import re
if re.search(r'\?token=|[?&]api[_-]?key=|X-Amz-Signature=|AWSAccessKeyId=|key=AIza', url):
    refuse("URL contains secret query-params; log to phase-3-inputs.md with redacted URL")
```

**Step 1 — Fetch + classify.** Detect URL type by domain/pattern:

| Pattern | Fetcher | Output |
|---|---|---|
| `youtube.com/watch`, `youtu.be/` | `~/.claude/skills/video-to-action/scripts/analyze-youtube.sh` via Gemini | structured JSON (workflows + skills_proposed) |
| `x.com/…/status/…`, `twitter.com/…` | X API batch (bearer at `deal_intent_signals_v1.x.bearer_token`) | tweet text + entities |
| `github.com/<owner>/<repo>` | `gh repo view` + README | repo metadata + tactics |
| `substack.com`, `medium.com`, generic blog | WebFetch | extracted text |
| `gist.github.com`, `*.s3.amazonaws.com`, pastebin | WebFetch + double-pass secret scanner | text with redaction |
| `.pdf` | WebFetch → text extract | text |

**Step 2 — Secret scanner on fetched content** (MANDATORY before any write):

```python
if re.search(r'AIza[A-Za-z0-9_-]{35}|sk-[A-Za-z0-9]{20,}|gho_[A-Za-z0-9]{36}|Bearer\s+[A-Za-z0-9._~+/=-]+', content):
    refuse("Content contains secret patterns — halt, log redacted")
```

**Step 3 — GBrain/OpenClaw ban check:** `scripts/phase3/pre-commit-gbrain-ban.sh` — reject any content referencing `GBrain|OpenClaw|Moltbot|Clawdbot` per security protocol.

**Step 4 — Extract insights + route.** Use `router-hub` to find related existing skills:

```bash
route.sh "<topic from extracted content>" --kind=skill --top=5
```

If top-1 score ≥ 0.9 AND title matches intent → use `extends:` pattern (append to existing skill). Else create new skill.

**Step 5 — Decide updates (wide scope per Q5):**
- **Skill**: new SKILL.md with 6/8 density (via `check-skill-density.sh`), slug matches `linkdrop-<source>-*` prefix
- **Agent**: new `~/.claude/agents/<slug>.md` if pattern is a process (not knowledge)
- **Command**: new `~/.claude/commands/mundi/<slug>.md` if pattern is a chain
- **KB wiki entry**: `docs/knowledge-base/wiki/<category>/<slug>.md` for reference material
- **MEMORY.md append**: only if surprising / decision-shifting (e.g., "found a faster approach to X")
- **CLAUDE.md update**: only if convention-shifting (update global OR app-specific)
- **Registry refresh**: `~/.claude/scripts/build-registry.sh` — chains automatically to `build-toolkit-scout.sh` (refreshes concierge auto-tail) and `build-embeddings.sh` (regenerates semantic vectors for Phase F hybrid routing, Mac-only — skips silently if Ollama unreachable)
- **Autoresearch propagation**: `autoresearch-evolve` on 3-5 "related" skills (same KB category OR ≥2 tag intersection)

**Step 6 — Validate before commit.** Run full validator gate:

```bash
~/.claude/scripts/phase3/check-skill-density.sh <new-skill>    # ≥6/8
~/.claude/scripts/phase3/validate-slug-prefix.sh 3A <slug>      # exit 0
~/.claude/scripts/phase3/check-secrets.sh <new-file>            # exit 0
~/.claude/scripts/phase3/pre-commit-gbrain-ban.sh <new-file>    # exit 0
~/.claude/scripts/phase3/check-no-deletions.sh                   # exit 0 (zero deletions)
```

**Step 7 — Single commit per link-drop** (NOT one commit per change):

```bash
git add <all-touched-files>
git commit -m "link-drop: <one-liner from source>

Source: <url-with-secrets-redacted>
Artifacts: <skill/kb/registry/memory summary>
Router regenerated. Autoresearch propagation: <3-5 skill slugs>"
git push origin main
```

**Step 8 — Rsync to Achilles** (service-excluded):

```bash
rsync -av --ignore-existing --exclude='*/venv/' ~/.claude/skills/ achilles-mundi:/home/mundi/.claude/skills/
ssh achilles-mundi 'cd ~/Mundi\ Princeps && git pull --rebase origin main'
ssh achilles-mundi 'ss -ltn | grep -cE "8766|8768"'  # must return 2
```

**Step 9 — Log decision trail** to `docs/knowledge-base/outputs/link-drop-log.md`:

```markdown
## 2026-04-19T04:15 :: <url-redacted>
- classified: <type>
- artifacts: skill:linkdrop-foo-bar (140 lines), kb/01-ai-development/foo.md, registry +1
- related skills evolved: bar, baz, qux
- commit: <sha>
- achilles-sync: ok
```

## Safety rules

- Abort lock check every 5 tool calls: `[ -f /tmp/link-drop.lock ] || halt` (implemented via `scripts/phase3/lock-gate.sh` wrapper)
- Rate-limit external fetches: 1 req / 2s
- Domain-based extra scrutiny: `gist.github.com`, `*.s3.amazonaws.com`, pastebins, hastebin — double secret scanner pass
- Never auto-commit secrets — any match at any stage halts + logs
- Never touch running services (pitchbook :8766, capiq :8768)
- Zero deletions (additive only)

## Cost model + rate limits + gotchas

- **Gemini cost (video URL path)**: Flash $0.075/1M tok; a YouTube tweet video ≈ 20-60K tok → $0.005/drop.
- **X API cost**: free tier 100K tweets/month; link-drop hits 1-2 tweet fetches per URL → effectively free.
- **gh CLI**: free.
- **WebFetch**: free, rate-limited by Claude harness.
- **Gotcha — X API expired bearer**: regenerate at developer.x.com; update `config/api_keys.json`.
- **Gotcha — GitHub t.co shortlinks**: always `curl -sI -L` first, don't trust `t.co` to resolve cleanly.
- **Gotcha — registry race**: if you drop 3 URLs in 5 seconds, registry rebuilds race. Serialize via `/tmp/link-drop.lock`.
- **Gotcha — skill-density failure**: if fetched content is too thin (<140 lines worth), fall back to KB wiki entry instead of full skill.
- **Gotcha — Achilles sync drops services**: never `--delete`; always `--ignore-existing`; always post-sync `ss -ltn` check.

## Setup steps

```bash
# 1. Verify all prerequisites
[ -f ~/.claude/registry.json ] || ~/.claude/scripts/build-registry.sh
[ -x ~/.claude/skills/router-hub/scripts/route.sh ] || echo "build router-hub first"
[ -d ~/.claude/skills/autoresearch-evolve ] || echo "build autoresearch-evolve first"
[ -x ~/.claude/skills/video-to-action/scripts/analyze-youtube.sh ] || echo "rewrite video-to-action first"
ls ~/.claude/scripts/phase3/*.sh | wc -l  # expect 8

# 2. Verify X bearer + Gemini keys
python3 -c "import json; k=json.load(open('$HOME/Mundi Princeps/config/api_keys.json')); print('x:', bool(k['deal_intent_signals_v1']['x']['bearer_token']), 'gemini:', bool(k['deal_intent_signals_v1']['gemini']['api_key']))"

# 3. Seed lock + log files
touch /tmp/link-drop.lock
touch "$HOME/Mundi Princeps/docs/knowledge-base/outputs/link-drop-log.md"

# 4. Test on known-good URL
# /mundi:link-drop https://x.com/rubenhassid/status/2045004326502871429
```

## Example invocation + expected output

```bash
$ /mundi:link-drop https://x.com/akshay_pachaar/status/2045510648474530263

[1/9] URL pre-scan: clean
[2/9] Classify: tweet
[3/9] Fetch via X API: 'A harnessed LLM agent. Most people picture...'
[4/9] Secret scan: 0 matches
[5/9] GBrain ban: clean
[6/9] Router lookup: 'agent harness architecture' → top-1 skill:agent-harness-construction (score 0.72) — below 0.9 threshold → create NEW skill
[7/9] Write skill: ~/.claude/skills/linkdrop-akshay-harnessed-agent-arch/SKILL.md (156 lines, density 7/8)
[7b/9] KB entry: docs/knowledge-base/wiki/01-ai-development-and-agents/akshay-harness-arch.md
[7c/9] Registry refresh: 1275 items (+1)
[7d/9] Autoresearch propagation: agent-harness-construction, saraev-managed-agents, multi-agent-mcp-orchestration — each got 'Evolution Notes (2026-04-19)' section
[8/9] Commit: abc1234
[9/9] Achilles sync: ok; services LISTEN

=== LINK-DROP COMPLETE === 18.3s
```

## Source citation

- Phase 3 Wave 3A meta-deliverable (plan lines 1100+)
- Architecture inspired by `akshay-harnessed-agent-arch` (Memory+Skills+Protocols)
- Dependencies: `router-hub`, `video-to-action`, `autoresearch-evolve`, `scripts/phase3/*.sh`
- Related command: `/mundi:link-drop <url>` (wrapper)
- Related agent: `~/.claude/agents/link-drop.md`

## See also

- `router-hub` — used in Step 4 (route similarity lookup)
- `video-to-action` — used in Step 1 (YouTube path)
- `autoresearch-evolve` — used in Step 5d (propagation)
- `akshay-harnessed-agent-arch` — the harness architecture this implements
- `/mundi:link-drop` — slash command wrapper
