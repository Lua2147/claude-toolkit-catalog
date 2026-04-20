---
name: linkdrop-x-deronin-karpathy-nn-from-scratch
description: Pointer to Andrej Karpathy's "Neural Networks Zero to Hero" — the canonical lecture series that builds micrograd (autograd engine) and a working MLP from scratch in pure Python + math. Use when onboarding to ML fundamentals, before fine-tuning work, or when framework abstractions hide a bug you need to debug at the gradient level.
source: https://x.com/DeRonin_/status/2045563162016317928 → Karpathy's Zero-to-Hero series + https://github.com/karpathy/micrograd
allowed-tools: Read, Bash
---

# linkdrop-x-deronin-karpathy-nn-from-scratch

## Overview

This is a **pointer skill** — not a transcription. The source tweet (Ronin, @DeRonin_, 2026-04-18) links to Andrej Karpathy's "Neural Networks: Zero to Hero" lecture series. The first lecture of that series (the 2-hour "micrograd" lecture) builds a scalar autograd engine + MLP from scratch with no PyTorch / TensorFlow — pure Python + calculus.

This skill does NOT reconstruct the lecture content. The value is: (1) the video is the canonical teaching resource, (2) `karpathy/micrograd` is the companion repo you clone and code along with, (3) the workflow below turns passive watching into real understanding.

## The resources

- **Video**: Andrej Karpathy's YouTube channel (`@AndrejKarpathy`). "Neural Networks: Zero to Hero" playlist. First episode = micrograd lecture. Find it via the channel, not via an assumed URL — playlist ordering is authoritative.
- **Companion repo**: https://github.com/karpathy/micrograd (15,500+ stars, MIT)
  - Tiny autograd engine: ~100 lines of core Python (DAG over scalar values)
  - `micrograd.nn` module with PyTorch-like API
  - `demo.ipynb`: trains a 2-layer MLP binary classifier on the moon dataset
  - `trace_graph.ipynb`: produces graphviz visualizations of the computational graph

## Why it matters

Every engineer who works with LLMs, fine-tuning, or agent systems benefits from mechanical understanding of what frameworks abstract away. Karpathy's lectures are the highest signal-per-minute ML education content publicly available, with his teaching rank established (Tesla Autopilot lead, OpenAI co-founder, Stanford CS231n).

## When to use

- Onboarding a new engineer to ML fundamentals.
- Before starting fine-tuning work (LoRA, full fine-tune, RLHF).
- Debugging training runs — NaN losses, exploding / vanishing gradients, dead neurons.
- Reviewing backprop intuition after a long time away from first principles.
- Before reading a paper that assumes gradient-flow intuition.
- When framework abstractions hide a bug you need to debug at the gradient level.

Skip if you're doing pure application work (prompting, RAG, tool use) with no training involved.

## Workflow — turn the lecture into real understanding

1. **First pass (2 hrs)** — watch end-to-end, no pausing. Get the shape of the argument.
2. **Clone the repo:** `git clone https://github.com/karpathy/micrograd && cd micrograd`
3. **Code along (3-4 hrs)** — type every line yourself alongside the video. Pause before Karpathy reveals code and predict what he'll write. Do NOT copy-paste.
4. **Exercise — extend**: add a new operation to `engine.py` (e.g., `log`, `sigmoid`) with correct forward + local gradient. Verify via `python -m pytest` (uses PyTorch as reference).
5. **Exercise — re-derive on paper**: without looking, derive `d(a*b)/da`, `d(tanh(x))/dx`, `d(relu(x))/dx`. Check against your `_backward` functions.
6. **Exercise — break a training run**: in `demo.ipynb`, set learning rate 10× too high. Observe gradient explosion. Push further until NaN. Fix by lowering LR. This builds debugging muscle.
7. **Optional** — port the engine to C or Rust. Forces you to confront the computational graph without Python's magic.

Budget 6-8 hours for the full workthrough. Skim-only (watching without coding) retains ~10%. Code-along retains ~70%.

## Prerequisites

- **Math**: chain rule (scalar), partial derivatives, basic linear algebra (dot product, matmul). If rusty, 30 min with 3Blue1Brown's "Essence of Calculus" Ep 2-4 first.
- **Python**: classes, operator overloading (`__add__`, `__mul__`), list comprehensions.
- **Environment**: Python 3.10+, `pip install micrograd` (from PyPI) OR clone the repo. `brew install graphviz` on macOS if you want the graph viz notebooks.

## Gotchas

- **"I already know backprop" trap**: experienced ML engineers still find the scalar-autograd framing sharpens intuition. Don't skip because you think you know it.
- **Framework muscle memory**: if you've only used PyTorch / TF, you'll reach for `.backward()`. Resist — the point is *building* `.backward()`.
- **PyTorch required for tests**: `python -m pytest` uses PyTorch as a gradient reference. Install `torch` separately before running tests.
- **graphviz dependency**: pip-install alone fails on some systems. On macOS: `brew install graphviz` first, then `pip install graphviz`.

## Follow-on resources (Karpathy's Zero-to-Hero series)

After the micrograd lecture, the series continues with:
- `makemore` — character-level language modeling, builds intuition for LM training
- Multi-part transformer build — "Let's build GPT from scratch" and subsequent
- `nanoGPT` — production-minimal GPT implementation

Full series on Karpathy's YouTube. Each lecture has a companion repo.

## Safety / license

- Study material — no execution risk.
- `karpathy/micrograd` is MIT-licensed — safe to fork, modify, vendor with attribution.
- YouTube lecture is publicly accessible; offline study via `yt-dlp` is personal-use OK, don't redistribute.

## Source

- Tweet: https://x.com/DeRonin_/status/2045563162016317928 (Ronin @DeRonin_, 2026-04-18)
- Lecturer: Andrej Karpathy (@karpathy on YouTube and X)
- Companion repo: https://github.com/karpathy/micrograd (MIT)
- Captured: 2026-04-18 via link-drop-pipeline; rewritten 2026-04-20 to remove reconstructed lecture outline and keep honest pointer + workflow.

## Cross-references

- `python` — Python language fundamentals (prerequisite)
- `claude-api` — building Claude-powered apps once fundamentals are in place
- `data-engineering` — ML data pipelines (pre-training)
- `exploratory-data-analysis` — pre-training data understanding
- `read-arxiv-paper` — for papers Karpathy references
- `video-to-action` — generic YouTube-to-structured-output pipeline (meta)
- `/mundi:video-to-spec` — workflow wrapper
