---
name: autoresearch
description: Karpathy's autonomous research loop — an AI agent iteratively runs experiments, evaluates results, and keeps improvements. Use for optimization tasks like model training, A/B testing, parameter tuning, or any iterative experimentation workflow.
---

# Autoresearch

Andrej Karpathy's framework for AI-driven autonomous experimentation. An agent reads a research directive, modifies code, runs an experiment on a fixed time budget, evaluates results, and loops — keeping improvements, discarding failures.

## Repo

```
https://github.com/karpathy/autoresearch
```

## Quick Start (LLM Training — Original Use Case)

```bash
git clone https://github.com/karpathy/autoresearch.git
cd autoresearch

# Install uv if needed
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install deps + prepare data (~2 min)
uv sync
uv run prepare.py

# Test a single training run (~5 min)
uv run train.py
```

Requires: Single NVIDIA GPU, Python 3.10+, `uv`

## How the Loop Works

```
┌─────────────────────────────────────────┐
│  1. Agent reads program.md (directive)  │
│  2. Agent modifies train.py             │
│  3. Run experiment (fixed 5-min budget) │
│  4. Evaluate val_bpb metric             │
│  5. Keep improvement or revert          │
│  6. Loop → go to 1                      │
└─────────────────────────────────────────┘
```

- ~12 experiments/hour, ~100 overnight
- Fixed time budget makes results directly comparable
- Agent handles hypothesis → code change → evaluation → decision

## Core Files

| File | Role | Who edits |
|------|------|-----------|
| `program.md` | Research directive & constraints | Human |
| `train.py` | Model, optimizer, training loop (~630 lines) | Agent |
| `prepare.py` | Data download, tokenizer training | Nobody |

## Key Design Principles

1. **Fixed time budget** — every experiment runs exactly 5 minutes regardless of what changed
2. **Single modification target** — only `train.py` changes, keeping scope tight
3. **Self-contained** — no distributed training, no external services
4. **Metric-driven** — `val_bpb` (bits per byte) is the single optimization target

## Tuning Parameters

| Param | Default | Notes |
|-------|---------|-------|
| `DEPTH` | 8 | Primary model complexity knob |
| `MAX_SEQ_LEN` | varies | Sequence length |
| `DEVICE_BATCH_SIZE` | varies | Per-device batch |
| `TOTAL_BATCH_SIZE` | varies | Global batch (powers of 2) |
| `vocab_size` | 8192 | Token vocabulary |
| `WINDOW_PATTERN` | "L"/"SSSL" | Attention pattern |

## Adapting the Pattern for Kadenwood

The autoresearch loop pattern can be applied beyond LLM training:

### Deal Scoring Optimization
```
program.md: "Improve deal scoring accuracy. Modify scoring_model.py.
Metric: precision@10 on validation set. 5-min budget per run."
```

### Landing Page Conversion
```
program.md: "Find higher converting landing page copy. Modify variants.json.
Metric: simulated CTR from A/B test framework. 5-min budget per run."
```

### Outreach Copy Optimization
```
program.md: "Optimize InMail response rates. Modify templates.yaml.
Metric: response_rate on holdout set. 5-min budget per run."
```

### Pipeline Signal Tuning
```
program.md: "Improve deal intent signal precision. Modify signal_weights.py.
Metric: F1 score on labeled signals. 5-min budget per run."
```

## Running with Claude Code

The autoresearch pattern maps naturally to Claude Code's coding agent loops:

```bash
# In a tmux session, point Claude at the research loop
claude --dangerously-skip-permissions -p "
Read program.md for your research directive.
Run experiments by modifying train.py, then run 'uv run train.py'.
After each run, evaluate val_bpb. Keep improvements, revert failures.
Continue iterating autonomously.
"
```

Or use the `coding-agent-loops` skill for persistent tmux-based execution.

## Community Forks

- macOS fork available (no NVIDIA required)
- Windows fork available
- For smaller GPUs: use TinyStories dataset, reduce vocab_size, lower DEPTH

## License

MIT
