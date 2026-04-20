---
date: 2026-04-20
decision: Rewrite 3 fabricated linkdrop skills with faithful content from real sources
affects: [mac, achilles, toolkit-repo, skills]
reversible: yes (via git revert in toolkit-catalog)
---

# Linkdrop skill rewrites — 3 skills replaced with faithful content

## Decision

Rewrote three `linkdrop-x-*` skills that failed content-faithfulness review, replacing fabricated content with real content pulled live from the actual source repos.

| Skill | Prior issue | Fix |
|---|---|---|
| `linkdrop-x-tom-doerr-multi-llm-council-deliberation` | Listed 4 named personas + "14 others"; invented 7 system-prompt stubs; no modes, triads, or profiles | Rewrote with real content from https://github.com/0xNyk/council-of-high-intelligence: 18 real members, 13 polarity pairs, 3 deliberation modes (full/quick/duo), 20 pre-defined triads, 3 council profiles, real `/council` command syntax, multi-provider auto-routing |
| `linkdrop-x-deronin-karpathy-nn-from-scratch` | Invented "lecture content (reconstruction from Karpathy's public curriculum)" section — 6 bullet outline fabricated; workflow steps padded with speculation | Stripped reconstruction. Kept honest pointer to Karpathy's Zero-to-Hero YouTube series + real `github.com/karpathy/micrograd` repo (15.5k stars, MIT) + pragmatic code-along workflow |
| `linkdrop-x-0x-kaize-awesome-claude-code-repos` | "10 repos" table had zero real repos named — generic filler categories | Replaced with pointer to real `github.com/hesreallyhim/awesome-claude-code` (39.8k stars, active daily) and its actual category headings (Agent Skills / Workflows / Tooling / Status Lines / Hooks / Slash-Commands / CLAUDE.md Files / Alternative Clients / Official Documentation) with 8 real slash-command sub-categories |

## Rationale

Audit (2026-04-20) flagged these three as hallucinated — density script passed them at 6-8/8 but content fabricated specifics the source never contained. User policy: keep all tools available, but fix content that lies when invoked. Rewrite was preferred over delete because the underlying sources genuinely exist and are valuable references.

## Verification

All three rewrites pass density:

```bash
bash ~/.claude/scripts/phase3/check-skill-density.sh ~/.claude/skills/linkdrop-x-tom-doerr-multi-llm-council-deliberation/SKILL.md      # 7/8
bash ~/.claude/scripts/phase3/check-skill-density.sh ~/.claude/skills/linkdrop-x-deronin-karpathy-nn-from-scratch/SKILL.md              # 6/8 (honest floor)
bash ~/.claude/scripts/phase3/check-skill-density.sh ~/.claude/skills/linkdrop-x-0x-kaize-awesome-claude-code-repos/SKILL.md            # 8/8
```

File parity across surfaces:

```bash
for s in linkdrop-x-tom-doerr-multi-llm-council-deliberation linkdrop-x-deronin-karpathy-nn-from-scratch linkdrop-x-0x-kaize-awesome-claude-code-repos; do
  diff ~/.claude/skills/$s/SKILL.md "/Users/mundiprinceps/Mundi Princeps/tmp/claude-toolkit-catalog/skills/$s/SKILL.md"
done
ssh achilles-mundi 'for s in linkdrop-x-tom-doerr-multi-llm-council-deliberation linkdrop-x-deronin-karpathy-nn-from-scratch linkdrop-x-0x-kaize-awesome-claude-code-repos; do
  wc -l /home/mundi/.claude/skills/$s/SKILL.md
done'
```

All three sources verified live on 2026-04-20:
- `gh api repos/0xNyk/council-of-high-intelligence` → 311 stars, pushed 2026-04-15
- `gh api repos/karpathy/micrograd` → 15,524 stars, MIT
- `gh api repos/hesreallyhim/awesome-claude-code` → 39,801 stars, pushed 2026-04-20

## How to reverse

Prior (fabricated) versions preserved in git history of this toolkit-catalog repo. To restore:

```bash
cd "/Users/mundiprinceps/Mundi Princeps/tmp/claude-toolkit-catalog"
git log --oneline skills/linkdrop-x-tom-doerr-multi-llm-council-deliberation/SKILL.md
# Find the commit before the rewrite, then:
git checkout <prior-commit-sha> -- skills/linkdrop-x-*/SKILL.md
```

(But don't. The prior versions were hallucinated.)

## Related

- Parent audit: inline audit report 2026-04-20 (session).
- Content-faithfulness rule captured in memory at `feedback_linkdrop_faithfulness.md`.
- Other linkdrops in the set (abmankendrick, avichawla, gregpr07, ghumare64, khairallah, marcelkargul, tom-doerr-self-learning, tomdoerr-gnhf, vmlops) left unchanged — audit scored those legitimate or thin-but-honest.
