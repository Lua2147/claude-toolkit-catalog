---
name: mundi-orch-multi-llm-consensus
description: Cross-model consensus — spawn parallel calls to Claude + Gemini + GPT on the same question, aggregate via vote or merge, return a decision with divergence flagged. Use when a high-stakes decision needs genuine model-level diversity (not just framing variation within one provider). Distinct from /mundi:consensus which is Claude-only framing variation.
allowed-tools: Read, Write, Edit, Bash, Task, WebFetch
---

# Mundi Orch — Multi-LLM Consensus

## Overview

Most of Mundi Princeps decision workflows run on Claude. That means every "consensus" is really Claude-agreeing-with-itself. This orchestrator addresses the blind spot: takes a question, fans out in parallel to **Claude + Gemini + GPT** (and optionally local Ollama), aggregates responses via vote / merge / divergence-flag.

Paired with `/mundi:consensus` (Claude-only) — this is the cross-provider upgrade path.

## When to use

- Strategic architecture decisions (one-way doors, major spend, hiring)
- Risk review on a recommendation Claude made (independent verification)
- Ethics / legal / compliance calls where provider-level bias matters
- Pre-mortem: "what could go wrong" — diversity of priors maximizes blind-spot coverage

**Do NOT use for:**
- Routine code tasks (cheap, single-model is fine)
- Questions with clear deterministic answers (single model + verification is enough)
- Low-stakes reversible decisions

## Architecture

```
                    ┌─── Claude (Sonnet 4.6 + Opus 4.7)
   Question ───┬───┼─── Gemini (3.1 Pro, Files API)
                │   ├─── GPT (via Codex bridge or OpenAI API)
                │   └─── Ollama (optional local, Llama 3 / Qwen)
                │
                └──▶ Aggregator (Opus scribe)
                       │
                       ▼
                  Consensus report
                       {decision, divergence_level, outlier_flags, ...}
```

## Pipeline (5 steps)

```
[1] Prepare prompt    → same question, same format expectation, templated
[2] Parallel fan-out  → parallel calls, 60s timeout each, capture structured JSON responses
[3] Diversity check   → detect mode collapse (all say the same thing) → if so, flag and retry with adversarial framing
[4] Aggregator scribe → Opus reads all responses, produces consensus + outlier + divergence
[5] Artifact persist  → docs/decisions/<YYYY-MM-DD>-<topic>-multi-llm.md
```

## I/O contract (MWP)

**state_reads:**
- `~/Mundi Princeps/config/api_keys.json` — Anthropic, OpenAI/Codex, Gemini keys
- `~/.claude/skills/claude-agent-sdk/SKILL.md` — Claude SDK invocation pattern
- `~/.claude/skills/video-to-action/scripts/analyze-youtube.sh` — Gemini curl pattern
- `~/.claude/skills/saraev-cc-codex-diversify/` — Codex/GPT bridge pattern

**state_writes:**
- `docs/decisions/<YYYY-MM-DD>-<topic>/` — artifact dir
  - `round1/claude.md`, `round1/gemini.md`, `round1/gpt.md` — raw responses
  - `consensus.md` — aggregated verdict with divergence flags
  - `metadata.json` — timing, tokens, confidence

## Composition

| provider | invocation |
|---|---|
| Claude | `claude-agent-sdk` skill or `/mundi:debate`-style direct call |
| Gemini | curl via Gemini 3.1 Pro API, Files API for long context |
| GPT | Codex CLI bridge (`saraev-cc-codex-diversify`) OR OpenAI API |
| Ollama | subprocess `ollama run <model> "..."` — optional, for local diversity |
| aggregator | Opus scribe, fixed-role prompt: "quote + tally + flag divergence, do not re-argue" |

## Aggregation rules

```
Divergence levels:
- LOW       — all providers agree on top-line decision + reasoning
- MEDIUM    — agree on decision, differ on rationale/tradeoffs
- HIGH      — differ on decision itself
- OUTLIER   — N-1 agree, 1 dissents strongly → surface dissent prominently

Output structure:
- Decision: <recommended path, if any>
- Consensus rationale: <what they all agree on>
- Divergence: <where and why they split, by provider>
- Outlier flag: <if present>
- Assumptions load-bearing: [a1, a2, a3]
- Reversal trigger: <observation that would flip the decision>
```

## Failure modes

| failure | recovery |
|---|---|
| One provider API down | proceed with available 2; flag `degraded: missing <provider>` |
| All 3 agree too strongly | possible echo; re-run round 2 with "steelman the opposing view" instruction |
| Aggregator produces low-confidence output | run a 4th provider; if still low, surface "no consensus" |
| Rate-limit | exponential backoff; never retry a 429 within 30s |

## Invocation

```python
Skill(skill="mundi-orch-multi-llm-consensus", {
  question: "Should we open-source the capiq-mcp tool registration layer?",
  providers: ["claude", "gemini", "gpt"],
  aggregator: "opus",
  format: "structured" | "prose",
  save_artifact: true
})
```

## Output contract

```json
{
  "question": "...",
  "providers_called": ["claude", "gemini", "gpt"],
  "providers_succeeded": ["claude", "gemini", "gpt"],
  "divergence_level": "LOW|MEDIUM|HIGH|OUTLIER",
  "decision": "...",
  "consensus_rationale": "...",
  "divergence_by_provider": {"claude": "...", "gemini": "...", "gpt": "..."},
  "outlier": null | {"provider": "...", "view": "..."},
  "load_bearing_assumptions": [...],
  "reversal_trigger": "...",
  "artifact_path": "docs/decisions/..."
}
```

## Cross-references

- **Distinct from:** `/mundi:consensus` (Claude-only stochastic framing variation), `/mundi:debate` (Claude-only chat.json debate)
- **Related:** `mundi-orch-multi-llm-debate` (adversarial version), `mundi-orch-multi-llm-route` (task→provider classifier), `stochastic-multi-agent-consensus`
- **Plugin skills:** `linkdrop-x-tom-doerr-multi-llm-council-deliberation` (external /council pattern — 18-persona cross-model)
- **Memory:** `feedback_linkdrop_faithfulness.md` (no invented content in aggregator)
- **KB:** `docs/knowledge-base/wiki/01-ai-development-and-agents/INDEX.md`
- **Plan source:** `docs/plans/2026-04-19-phase-3-final.md` line 862

## Safety

- **Provider diversity required.** If only Claude responds, this degrades to `/mundi:consensus` — do not pretend.
- **Aggregator is a scribe, not an arbiter.** Lock its role: quote + tally + flag divergence, never re-argue.
- **Not a substitute for human judgment** — output is an input to your decision.
