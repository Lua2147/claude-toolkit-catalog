---
name: mundi-orch-multi-llm-route
description: Task-type → best-LLM-per-task router. Classifies incoming task (code, long-context research, creative, math, vision, agentic) then dispatches to the right provider (Claude for code, Gemini for long-context, GPT for creative, etc.) per published benchmark + cost profile. Use when composing an orchestrator that needs to call the "right" LLM automatically — or when budget optimization matters across many calls.
allowed-tools: Read, Write, Edit, Bash, Task
---

# Mundi Orch — Multi-LLM Router

## Overview

Different LLMs have different strengths. Claude is best at code, reasoning, and tool use. Gemini is strongest on long-context (1M+), vision, and research breadth. GPT is competitive on creative, some math, and has Codex for pure coding. This router classifies a task and dispatches to the best provider per benchmark + cost.

This is the **automated** version of what you'd do manually when you think "this is a code problem → Claude" or "this is a 500-page document → Gemini."

## When to use

- Inside an orchestrator that makes many LLM calls and wants per-call optimization
- When budget matters across a run (expensive tasks → cheap provider when appropriate)
- Building a "best default" for an agentic system that might tackle varied tasks
- Reducing provider-lock-in

**Do NOT use when:**
- One-off manual call — just pick the LLM yourself
- Task is clearly homogeneous (all code → Claude; all long docs → Gemini) — skip the router overhead
- Cost doesn't matter (single-user, small volume) — default to Claude

## Classification taxonomy

| task class | signals | best provider | rationale |
|---|---|---|---|
| **code-generation** | programming language mentioned, code blocks expected, debugging | Claude Sonnet/Opus | SWE-bench leader, tool-use strength |
| **code-review** | "review this diff", explicit file review | Claude Opus | deep reasoning, catches edge cases |
| **long-context-research** | >50k tokens of input, multi-doc synthesis | Gemini 3.1 Pro (1M context) | only model that fits without sharding |
| **vision-extraction** | images, PDFs, screenshots, layout parsing | Gemini 3.1 Pro | strongest vision + cheap |
| **creative-writing** | blog, marketing copy, brand voice | GPT-4 / Claude | GPT more playful, Claude more structured |
| **math-heavy** | numerical computation, derivations | GPT-o1 / Claude Opus + tools | o1 good at pure, Claude good with calculator tool |
| **agentic-decomposition** | break-this-into-sub-tasks, multi-step | Claude Opus | best tool-use + plan-decompose |
| **summarization-short** | <10k input, TL;DR output | Claude Haiku / Gemini Flash | cheap, fast, good enough |
| **structured-extraction** | "extract JSON from this" | Claude Sonnet | reliable JSON mode, fast |

## Pipeline (3 steps)

```
[1] Classify task  → regex + light LLM classifier → task class
[2] Pick provider  → lookup from table + current-cost check + rate-limit check
[3] Dispatch       → call via provider SDK; return result with metadata tag
```

## I/O contract (MWP)

**state_reads:**
- `~/Mundi Princeps/config/api_keys.json` — all provider keys
- `~/.claude/skills/saraev-cc-opus-vs-sonnet-routing/SKILL.md` — Claude-internal routing pattern (reused here)
- `~/.claude/skills/saraev-cc-conductor-multimodel/SKILL.md` — multi-model conductor pattern

**state_writes:**
- Optional `apps/router-log/<date>.jsonl` — decision log per routed call (for audit + cost accounting)

## Composition

| component | tool |
|---|---|
| classifier | Claude Haiku with 3-shot prompt, returns task class + confidence |
| Claude dispatch | `claude-agent-sdk` or subprocess |
| Gemini dispatch | curl pattern from `video-to-action/scripts/analyze-youtube.sh` |
| GPT dispatch | `saraev-cc-codex-diversify` OR OpenAI API |
| rate-limit tracker | simple file-lock counter per provider in `/tmp/mundi-llm-rate-*.json` |
| cost calculator | token count × provider price-per-token (update quarterly) |

## Routing rules

Default preference:
1. **Cheapest acceptable** — if task is simple and Haiku/Flash suffice, use them.
2. **Right-fit over cost** — if long-context is needed, don't shard to save; use Gemini directly.
3. **Fallback cascade** — provider down → next-best per class.
4. **Sticky per-run** — if a run involves many calls with the same task class, don't re-classify; pin to one provider.

```python
# Pseudocode
class_, confidence = classify(task)
provider = PROVIDER_TABLE[class_]
if not provider_available(provider):
    provider = FALLBACK_TABLE[class_][0]
if budget_exceeded(provider):
    provider = cheaper_alternative(class_)
return dispatch(provider, task)
```

## Failure modes

| failure | recovery |
|---|---|
| Classifier low-confidence | default to Claude Opus (safe) and log for review |
| Primary provider down | cascade to next in `FALLBACK_TABLE` for that class |
| Rate-limit hit | wait 30s + retry, or route to alternative |
| Budget exceeded (soft limit) | surface warning + route to cheaper alternative; don't hard-block |
| All providers down | hard-fail; do not synth a response |

## Invocation

```python
Skill(skill="mundi-orch-multi-llm-route", {
  task: "Summarize this 400-page data room into a 2-page IC brief",
  hint_class: "long-context-research",  # optional override
  budget_ceiling_usd: 2.00,
  log_decision: true
})

# Returns:
{
  "classified_as": "long-context-research",
  "provider_used": "gemini-3-pro",
  "fallback_chain": ["gemini-3-pro", "claude-opus-4.7-1m"],
  "response": "...",
  "cost_usd": 0.47,
  "latency_ms": 18400
}
```

## Cross-references

- **Related:** `saraev-cc-opus-vs-sonnet-routing` (Claude-internal), `saraev-cc-conductor-multimodel`, `saraev-cc-claude-code-token-cost-optimization`, `mundi-orch-multi-llm-consensus`, `mundi-orch-multi-llm-debate`, `router-hub` (skill/tool discovery, different layer)
- **Plugin skills:** `claude-agent-sdk`, `claude-api`
- **Memory:** (none specific; patterns from saraev-cc-* family)
- **KB:** `docs/knowledge-base/wiki/01-ai-development-and-agents/1.3-llm-infrastructure.md`, `wiki/02-workflow-and-dx/token-optimization.md`
- **Plan source:** `docs/plans/2026-04-19-phase-3-final.md` line 864

## Safety

- **Keep classifier cheap.** Use Haiku/Flash for classification — expensive classifier defeats the purpose.
- **Log every decision** — retrospectively tune the routing table against actual outcomes.
- **Don't shard when not needed.** If Gemini can fit it in 1M context, don't chunk to save a few cents.
- **Provider diversity also matters** — avoid 100% routing to one provider even if cheapest; keeps you hedged against provider outages.
