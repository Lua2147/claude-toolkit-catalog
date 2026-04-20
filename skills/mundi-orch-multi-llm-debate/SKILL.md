---
name: mundi-orch-multi-llm-debate
description: Adversarial cross-model debate — Claude vs Gemini vs GPT argue opposing sides of a decision, structured multi-round, escalating specificity. Use when genuine adversarial diversity is needed (not Claude-vs-Claude debate which has correlated priors). Distinct from /mundi:debate which is Claude-only chat.json.
allowed-tools: Read, Write, Edit, Bash, Task, WebFetch
---

# Mundi Orch — Multi-LLM Debate

## Overview

Cross-model adversarial debate. Takes a proposition (architectural choice, hire, acquisition, etc.), assigns opposing sides to different providers (Claude + Gemini + GPT), and runs multi-round structured debate. Distinct from `/mundi:debate` (Claude-only chat.json) in that the providers have genuinely uncorrelated priors.

Related to `mundi-orch-multi-llm-consensus` — consensus is "agree-or-flag-divergence", debate is "actively attack each other's reasoning."

## When to use

- Evaluating a contentious proposal where you need the strongest case for and against
- Pre-mortem on a decision Claude already recommended ("Gemini: argue why this fails")
- Architectural tradeoff reviews (microservices vs monolith, build vs buy, etc.)
- Legal / ethics / compliance edge-cases
- Board prep: "what will the skeptical director ask?"

**Do NOT use when:**
- Question is factual (look it up, don't debate it)
- Reversible / low-stakes (single-model is cheaper)
- Single provider is available (no real adversarial — use `/mundi:debate` instead)

## Architecture

```
    Proposition
        │
        ├─ Round 1 (Position Papers, parallel)
        │    Claude → argues PRO / assigned position A
        │    Gemini → argues CON / assigned position B
        │    GPT    → argues alt position C or skeptic
        │
        ├─ Round 2 (Cross-Examination)
        │    Each reads siblings → writes targeted critiques
        │    "Here's where position A breaks down..."
        │
        ├─ Round 3 (Rebuttals)
        │    Each responds to strongest critique
        │
        └─ Scribe (Opus aggregator)
             Extract: strongest argument per side, unresolved
             Output: debate transcript + synthesis
```

## Pipeline (6 steps)

```
[1] Frame proposition    → user provides or elaborates
[2] Assign positions     → auto (Claude=PRO, Gemini=CON, GPT=alt) OR user-specified
[3] Round 1: position papers (parallel fan-out, 200-400 words each)
[4] Round 2: cross-examination (each reads siblings, critiques strongest point)
[5] Round 3: rebuttals (each responds to targeted critique)
[6] Scribe aggregation → extract strongest arguments per side + unresolved points
```

## I/O contract (MWP)

**state_reads:**
- `~/Mundi Princeps/config/api_keys.json` — all 3 providers
- `~/.claude/skills/claude-agent-sdk/` — Claude invocation pattern
- `~/.claude/skills/agent-chatrooms/` — chat.json pattern for debate structure
- `~/.claude/skills/saraev-iterative-multi-agent-debate-visualization/` — output viz pattern

**state_writes:**
- `docs/debates/<YYYY-MM-DD>-<topic>/` — artifact dir
  - `position-papers/{claude,gemini,gpt}.md` — round 1
  - `critiques/{claude,gemini,gpt}.md` — round 2
  - `rebuttals/{claude,gemini,gpt}.md` — round 3
  - `synthesis.md` — scribe output (strongest args + unresolved)
  - `transcript.md` — full three-round transcript

## Composition

| step | tool |
|---|---|
| Claude | `claude-agent-sdk` skill or direct CLI call |
| Gemini | Gemini 3.1 Pro via curl, Files API if needed |
| GPT | OpenAI API via Codex bridge or direct |
| parallel orchestration | `superpowers:dispatching-parallel-agents` |
| chat.json debate | `agent-chatrooms` skill pattern |
| scribe | Opus-only, fixed role prompt |
| visualization | `saraev-iterative-multi-agent-debate-visualization` (optional) |

## Round structure

**Round 1 — Position Papers (200-400 words each, parallel, 30-60s each):**
- Independent (no peer context)
- Each argues their assigned side
- Must include: thesis, 3 supporting arguments, 1 acknowledged weakness

**Round 2 — Cross-Examination (100-200 words each, sequential after Round 1 complete):**
- Each reads all siblings
- Identifies strongest opposing view
- Attacks load-bearing assumption, not rhetoric

**Round 3 — Rebuttals (100-200 words each):**
- Responds to the specific targeted critique
- Must either concede or explain why the critique misses

**Scribe:** fixed role — quote + tally + surface unresolved, NEVER re-argue.

## Failure modes

| failure | recovery |
|---|---|
| One provider times out | defer that round; 2-way debate continues |
| Echo (all agree too soon) | add adversarial framing: "Gemini, you MUST argue against Claude's claim even if you find it compelling" |
| Personality drift (generic agreeable tone) | tighten system prompts with provider-specific priors (Claude=cautious, Gemini=scale, GPT=pragmatic) |
| Scribe injects its own view | reject + regenerate with tighter role prompt |

## Invocation

```python
Skill(skill="mundi-orch-multi-llm-debate", {
  proposition: "We should open-source the capiq-mcp tool registration layer",
  positions: {"claude": "pro", "gemini": "con", "gpt": "risk-focused alternative"},
  rounds: 3,
  scribe: "opus",
  save_artifact: true,
  output_dir: "docs/debates/capiq-oss-2026-04-20/"
})
```

## Output contract

```json
{
  "proposition": "...",
  "providers_engaged": ["claude", "gemini", "gpt"],
  "rounds_completed": 3,
  "strongest_pro_argument": "...",
  "strongest_con_argument": "...",
  "strongest_alt_argument": "...",
  "unresolved_points": [...],
  "load_bearing_assumptions": [...],
  "synthesis_md": "docs/debates/.../synthesis.md",
  "transcript_md": "docs/debates/.../transcript.md"
}
```

## Cross-references

- **Distinct from:** `/mundi:debate` (Claude-only chat.json)
- **Related:** `mundi-orch-multi-llm-consensus` (agreement-oriented), `mundi-orch-multi-llm-route` (task→provider classifier), `/mundi:debate-then-verify`
- **Plugin skills:** `linkdrop-x-tom-doerr-multi-llm-council-deliberation` (18-persona /council)
- **Memory:** `feedback_linkdrop_faithfulness.md`, `feedback_edit_source.md`
- **KB:** `docs/knowledge-base/wiki/01-ai-development-and-agents/INDEX.md`
- **Plan source:** `docs/plans/2026-04-19-phase-3-final.md` line 863

## Safety

- **Provider diversity required.** If only Claude responds, abort — this skill degenerates to `/mundi:debate`.
- **Scribe role is locked.** Quote + tally, never re-argue. If scribe adds its own view, regenerate.
- **Debate is an input**, not a decision. Save the artifact; make the call yourself.
- **Cost awareness:** 3 providers × 3 rounds = 9 calls. Budget accordingly.
