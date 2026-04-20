---
name: linkdrop-x-tom-doerr-multi-llm-council-deliberation
description: 18 AI personas (Aristotle, Socrates, Sun Tzu, Feynman, Kahneman, Karpathy, Sutskever, Taleb, etc.) deliberate hard decisions via structured multi-round debate across Claude/OpenAI/Gemini/Ollama. Use when making a high-stakes call where genuine multi-model disagreement beats single-model consensus.
source: https://x.com/tom_doerr/status/2045839498634727752 → https://github.com/0xNyk/council-of-high-intelligence
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# linkdrop-x-tom-doerr — Council of High Intelligence

## Overview

`0xNyk/council-of-high-intelligence` is a Claude Code + Codex skill (CC0 license, 311+ stars) that installs 18 named council members — each a philosophical / disciplinary archetype — and runs structured multi-round deliberation across multiple LLM providers. The pitch: a single LLM gives you "one reasoning path dressed up as confidence." The council gives you structured *disagreement* instead.

The real differentiator vs our existing debate patterns (`/mundi:debate`, `/mundi:consensus`, `stochastic-multi-agent-consensus`):

1. **Named members with polarity pairs.** Not generic debate roles — specific archetypes paired for deliberate tension (Socrates↔Feynman, Torvalds↔Watts, Karpathy↔Sutskever, 10 more).
2. **Multi-provider auto-routing.** Members distributed across Claude, OpenAI, Gemini, Ollama. No single model's bias dominates.
3. **Pre-built triads and profiles.** 20 domain-specific 3-member combos + 3 pre-built panels for different decision types.

## Install

```bash
git clone https://github.com/0xNyk/council-of-high-intelligence.git
cd council-of-high-intelligence
./install.sh           # Claude Code
# OR
./install.sh --codex   # Codex
```

Then in Claude Code:

```
/council Should we open-source our agent framework?
/council --quick Should we add caching here?
/council --duo Should we use microservices or monolith?
/council --triad ai-safety What's our AI policy?
```

## The 18 members (actual, from repo)

| Agent | Figure | Domain | Default model | Polarity |
|---|---|---|---|---|
| `council-aristotle` | Aristotle | Categorization & structure | opus | Classifies everything |
| `council-socrates` | Socrates | Assumption destruction | opus | Questions everything |
| `council-sun-tzu` | Sun Tzu | Adversarial strategy | sonnet | Reads terrain & competition |
| `council-ada` | Ada Lovelace | Formal systems & abstraction | sonnet | What can/can't be mechanized |
| `council-aurelius` | Marcus Aurelius | Resilience & moral clarity | opus | Control vs acceptance |
| `council-machiavelli` | Machiavelli | Power dynamics & realpolitik | sonnet | How actors actually behave |
| `council-lao-tzu` | Lao Tzu | Non-action & emergence | opus | When less is more |
| `council-feynman` | Feynman | First-principles debugging | sonnet | Refuses unexplained complexity |
| `council-torvalds` | Linus Torvalds | Pragmatic engineering | sonnet | Ship it or shut up |
| `council-musashi` | Miyamoto Musashi | Strategic timing | sonnet | The decisive strike |
| `council-watts` | Alan Watts | Perspective & reframing | opus | Dissolves false problems |
| `council-karpathy` | Andrej Karpathy | Neural network intuition | sonnet | How models actually learn and fail |
| `council-sutskever` | Ilya Sutskever | Scaling frontier & AI safety | opus | When capability becomes risk |
| `council-kahneman` | Daniel Kahneman | Cognitive bias & decision science | opus | Your own thinking is the first error |
| `council-meadows` | Donella Meadows | Systems thinking & feedback loops | sonnet | Redesign the system, not the symptom |
| `council-munger` | Charlie Munger | Multi-model reasoning & economics | sonnet | Invert — what guarantees failure? |
| `council-taleb` | Nassim Taleb | Antifragility & tail risk | opus | Design for the tail, not the average |
| `council-rams` | Dieter Rams | User-centered design | sonnet | Less, but better — the user decides |

## Polarity pairs (13 intentional counter-weights)

- **Socrates ↔ Feynman** — destroys top-down vs rebuilds bottom-up
- **Aristotle ↔ Lao Tzu** — classifies everything vs structure IS the problem
- **Sun Tzu ↔ Aurelius** — wins external games vs governs the internal one
- **Ada ↔ Machiavelli** — formal purity vs messy human incentives
- **Torvalds ↔ Watts** — ships concrete solutions vs questions whether the problem exists
- **Musashi ↔ Torvalds** — waits for the perfect moment vs ships it now
- **Karpathy ↔ Sutskever** — build + iterate vs pause + research + ensure safety
- **Karpathy ↔ Ada** — empirical ML intuition vs formal systems theory
- **Kahneman ↔ Feynman** — your cognition is the first error vs trust first-principles reasoning
- **Meadows ↔ Torvalds** — redesign the feedback loop vs fix the symptom and ship
- **Munger ↔ Aristotle** — multi-model lattice vs single taxonomic system
- **Taleb ↔ Karpathy** — hidden catastrophic tails vs smooth empirical scaling curves
- **Rams ↔ Ada** — what the user needs vs what computation can do

## Three deliberation modes

1. **Full** (default) — 3 rounds: independent analysis → cross-examination → final positions. Use for high-stakes one-way-door decisions.
2. **`--quick`** — 2 rounds, no cross-examination. Use for simpler decisions where you still want divergence but not the full 3-round cost.
3. **`--duo`** — 2-member dialectic using a polarity pair. Use when you want to explore a specific tension (e.g., `--duo --members torvalds,ada`).

## 20 pre-defined domain triads

```
architecture   = Aristotle + Ada + Feynman       (classify + formalize + simplicity-test)
strategy       = Sun Tzu + Machiavelli + Aurelius (terrain + incentives + moral grounding)
ethics         = Aurelius + Socrates + Lao Tzu    (duty + questioning + natural order)
debugging      = Feynman + Socrates + Ada         (bottom-up + assumption testing + formal verification)
innovation     = Ada + Lao Tzu + Aristotle
conflict       = Socrates + Machiavelli + Aurelius
complexity     = Lao Tzu + Aristotle + Ada
risk           = Sun Tzu + Aurelius + Feynman
shipping       = Torvalds + Musashi + Feynman
product        = Torvalds + Machiavelli + Watts
founder        = Musashi + Sun Tzu + Torvalds
ai             = Karpathy + Sutskever + Ada
ai-product     = Karpathy + Torvalds + Machiavelli
ai-safety      = Sutskever + Aurelius + Socrates
decision       = Kahneman + Munger + Aurelius
systems        = Meadows + Lao Tzu + Aristotle
uncertainty    = Taleb + Sun Tzu + Sutskever
design         = Rams + Torvalds + Watts
economics      = Munger + Machiavelli + Sun Tzu
bias           = Kahneman + Socrates + Watts
```

Invoke with `/council --triad <domain> <question>`.

## Three council profiles

- **`classic`** (default) — all 18 members with domain triads. Broad deliberation.
- **`exploration-orthogonal`** — 12-member panel for "unknown unknowns" (Socrates, Feynman, Sun Tzu, Machiavelli, Ada, Lao Tzu, Aurelius, Torvalds, Karpathy, Sutskever, Kahneman, Meadows).
- **`execution-lean`** — 5-member panel for fast decision-to-action (Torvalds, Feynman, Sun Tzu, Aurelius, Ada).

## Multi-provider auto-routing

The install script detects which LLM provider CLIs are present (`claude`, `openai`, `gemini`, `ollama`) and distributes members across them automatically. No config required. The whole point is genuine model diversity — 18 correlated voices on one provider gives you groupthink.

## When to use

- High-stakes one-way-door decisions: architectural pivots, hiring, major spend, IC memos.
- Auditing a recommendation from a single model before acting.
- Strategy sessions where diverse priors genuinely matter (ethics, regulatory, competitive).
- Pre-mortem style risk review — let Taleb + Sun Tzu + Sutskever hunt tail risks.

**Do NOT use when:**
- The decision is reversible and cheap — just act.
- You only have one LLM provider configured (no real diversity possible).
- The stakes don't justify 18× token cost vs single-model output.

## Cost structure

Per the repo's own guidance: full 18-member 3-round deliberation is substantial spend. Use `--quick` or `--duo` or a triad for routine calls. Reserve full classic profile for the decisions that genuinely warrant it.

## Install strategy for this monorepo

**Option A — vendored install (recommended):**
1. Clone into `~/sandbox/council-of-high-intelligence/` (not global).
2. Review `install.sh` before running — it writes to `~/.claude/`.
3. Run `./install.sh`. Verify no overwrites of existing skills (our local `linkdrop-x-tom-doerr-*` should be untouched since names don't collide).
4. Test with `/council --quick Is this migration safe?` on a low-stakes question first.

**Option B — pattern extraction:**
If you want the concept without the install:
- Read `agents/council-*.md` files from the repo for the 18 system prompts.
- Adapt into our existing `/mundi:debate` or `/mundi:consensus` with a `--personas` flag.

## Integration with our stack

Our existing analogues — keep or replace:
- `/mundi:debate` — 2-side debate. **Keep**; `/council --duo` is the install-free equivalent.
- `/mundi:consensus` — N-agent consensus. **Complements**; council adds named archetypes + polarity.
- `stochastic-multi-agent-consensus` — stochastic aggregation. **Complementary**; use for non-named-persona votes.
- `saraev-iterative-multi-agent-debate-visualization` — visualization layer. **Pair** with council for artifact presentation.
- `superpowers:dispatching-parallel-agents` — the underlying parallel-exec primitive. **Prerequisite**.

## Safety + gotchas

- **License:** CC0 / public domain (per repo badge). Safe to vendor with attribution.
- **Install review:** `install.sh` writes to your `~/.claude/` directory. Always read before running in a shared environment.
- **Provider monoculture:** if only Anthropic is configured, the "multi-provider" promise degrades to single-provider routing. Configure at least 2 for real diversity.
- **Budget blowouts:** 18 members × 3 rounds = 54 LLM calls per decision. Cap with `--quick` or `--duo` unless stakes justify full mode.
- **Persona drift on weaker models:** if some members route to smaller models, their system-prompt distinctions can collapse. The repo's `sonnet` / `opus` defaults are tuned to avoid this.
- **Not a substitute for human judgment:** the council is an *input* to your decision, not a replacement. Save the artifact; make the call yourself.

## Source

- Tweet: https://x.com/tom_doerr/status/2045839498634727752 (2026-04-19 — Tom Doerr)
- Repo: https://github.com/0xNyk/council-of-high-intelligence (311 stars, CC0, MIT-like)
- Captured: 2026-04-18 via link-drop-pipeline; rewritten 2026-04-20 against live repo README.

## Cross-references

- `/mundi:debate`, `/mundi:consensus`, `/mundi:debate-then-verify`
- `stochastic-multi-agent-consensus`
- `saraev-iterative-multi-agent-debate-visualization`
- `superpowers:dispatching-parallel-agents`, `superpowers:subagent-driven-development`
- `~/.claude/rules/agents.md`
- `docs/knowledge-base/wiki/01-ai-development-and-agents/INDEX.md`

## Related KB entry

- `docs/knowledge-base/wiki/01-ai-development-and-agents/linkdrop-x-tom-doerr-multi-llm-council-deliberation.md`
