---
name: mwp
description: Model Workspace Protocol — framework-free AI agent orchestration using filesystem structure, markdown contracts, and layered context. Use for designing multi-stage AI workflows, structuring complex projects, or when GSD stages need I/O contract patterns.
---

# Model Workspace Protocol (MWP)

Framework-free method for orchestrating AI agent workflows using **filesystem structure** instead of code frameworks. The entire "program" is numbered folders, markdown files, and local scripts.

**Paper**: "Interpretable Context Methodology" — Jake Van Clief & David McDermott (Eduba / University of Edinburgh)
**Repo**: `https://github.com/RinDig/Model-Workspace-Protocol-MWP-`
**License**: MIT

## Core Architecture

```
project/
├── CLAUDE.md              ← Layer 0: global persona (~800 tokens)
├── CONTEXT.md             ← Layer 1: project-wide rules (~300 tokens)
├── 01_stage/
│   ├── CONTEXT.md         ← Layer 2: stage contract (inputs/process/outputs)
│   ├── reference/         ← Layer 3: read-only material (500-2k tokens)
│   └── working/           ← Layer 4: mutable artifacts
├── 02_stage/
│   ├── CONTEXT.md
│   └── working/
└── 03_stage/
    ├── CONTEXT.md
    └── working/
```

## 5 Design Principles

1. **One stage, one job** — decompose into single-responsibility stages
2. **Plain text interface** — markdown is the universal exchange format
3. **Layered context loading** — only load what the current stage needs (2-8k tokens vs 42k+ monolithic)
4. **Every output is an edit surface** — humans can modify any intermediate artifact
5. **Configure the factory, not the product** — tune CONTEXT.md files, not outputs

## Stage Contract Format (CONTEXT.md)

Each stage's CONTEXT.md is an explicit I/O contract:

```markdown
# Stage: [Name]

## Inputs
- [Layer 3 reference files this stage reads]
- [Layer 4 working files from previous stages]

## Process
- [Step-by-step instructions for the agent]
- [Constraints and quality criteria]

## Outputs
- [Files this stage produces in working/]
- [Format and structure requirements]
```

## The Edit-Source Principle

When output is wrong, fix the **source instruction** (CONTEXT.md), not the output. This keeps the pipeline reproducible — re-running from corrected instructions produces correct results.

```
Wrong output? → Fix CONTEXT.md → Re-run stage → Correct output
NOT: Wrong output? → Hand-edit output → Pipeline now inconsistent
```

## 5-Layer Context Hierarchy

| Layer | File | Tokens | Loaded When |
|-------|------|--------|-------------|
| 0 | CLAUDE.md | ~800 | Always |
| 1 | Root CONTEXT.md | ~300 | Always |
| 2 | Stage CONTEXT.md | 200-500 | Per stage |
| 3 | reference/ files | 500-2k | Per stage (read-only) |
| 4 | working/ files | Varies | Per stage (mutable) |

Total per stage: 2-8k focused tokens vs 42k+ monolithic dump.

## Key Findings (52-member practitioner community)

- **U-shaped intervention**: 92% edit stage 1 outputs, 30% stage 2, 78% stage 3. Middle stages run most autonomously.
- **Non-technical users succeed**: People who can't code can edit CONTEXT.md to change agent behavior.
- **Workspace duplication**: Clone folders to run variations — filesystem IS version control.

## How MWP Maps to GSD

| MWP Concept | GSD Equivalent | Gap Filled |
|-------------|---------------|------------|
| Stage CONTEXT.md | Phase CONTEXT.md | Added `<io_contract>` section |
| Inputs/Outputs | `must_haves`, `requires/provides` | Now explicit in CONTEXT.md |
| Edit-source principle | — | Added to PLAN.md template guidance |
| Layer 0 (CLAUDE.md) | CLAUDE.md | Already exists |
| Layer 1 (root CONTEXT) | PROJECT.md + ROADMAP.md | Already exists |
| Layer 2 (stage CONTEXT) | Phase CONTEXT.md | Already exists |
| Layer 3 (reference) | `<context>` block `@` references | Already exists |
| Layer 4 (working) | Source code files | Already exists |
| Human review gates | Checkpoint tasks | Already exists |
| State mutations | — | Added `state_reads`/`state_writes` to PLAN.md |

## When to Use MWP Patterns

- **Designing new GSD phases**: Use the I/O contract pattern in CONTEXT.md to declare what goes in and out
- **Debugging pipeline failures**: Trace from failed output → which stage → which input was wrong → fix source
- **Non-code workflows**: MWP works for any sequential pipeline (content production, research, data processing) — not just software
- **Teaching others**: MWP's simplicity (numbered folders + markdown) makes it accessible to non-developers

## Production Implementations

| Pipeline | Stages | Domain |
|----------|--------|--------|
| Script-to-animation | 3 | Script → storyboard → animated video |
| Course deck production | 5 | Topic → research → outline → slides → polish |
| Workspace-builder | 5 | Requirements → scaffold → populate → validate → package |

## Limitations

- Sequential only — no parallel stage execution (GSD handles this with waves)
- No automated branching or conditional routing (GSD handles with checkpoints)
- Local-first — no multi-user collaboration
- Human must trigger each stage transition (GSD handles with auto-advance)
