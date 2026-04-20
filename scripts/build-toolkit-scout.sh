#!/usr/bin/env bash
# Regenerate the AUTO-GENERATED portion of ~/.claude/skills/toolkit-scout/SKILL.md
# from ~/.claude/registry.json. Runs automatically after build-registry.sh.
#
# Hybrid layout:
#   [curated head — hand-maintained, preserved byte-for-byte]
#   <!-- AUTO-GENERATED BELOW — DO NOT EDIT MANUALLY — run ~/.claude/scripts/build-toolkit-scout.sh to regenerate -->
#   [auto-generated inventory]
#
# Marker algorithm:
#   0 markers found      -> write full template (curated head + marker + tail)
#   1 marker found       -> preserve head + marker, replace only the tail
#   2+ markers found     -> abort with error (ambiguous, manual review required)
#
set -euo pipefail

REGISTRY="${HOME}/.claude/registry.json"
OUT="${HOME}/.claude/skills/toolkit-scout/SKILL.md"

if [ ! -f "$REGISTRY" ]; then
  echo "toolkit-scout: registry not found at $REGISTRY — run build-registry.sh first" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUT")"

python3 - "$REGISTRY" "$OUT" <<'PYEOF'
import json, sys, re
from collections import Counter, defaultdict
from pathlib import Path

try:
    reg = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
except json.JSONDecodeError as e:
    print(f"toolkit-scout: registry is malformed JSON at {sys.argv[1]}: {e}", file=sys.stderr)
    print(f"  Run `bash ~/.claude/scripts/build-registry.sh` to rebuild.", file=sys.stderr)
    sys.exit(2)

if not isinstance(reg, dict):
    print(f"toolkit-scout: registry root is {type(reg).__name__}, expected object", file=sys.stderr)
    sys.exit(2)

out = Path(sys.argv[2])

MARKER = "<!-- AUTO-GENERATED BELOW — DO NOT EDIT MANUALLY — run ~/.claude/scripts/build-toolkit-scout.sh to regenerate -->"

items = reg.get("items", [])
if not items:
    print(f"toolkit-scout: WARNING — registry has 0 items", file=sys.stderr)
by_kind = defaultdict(list)
for it in items:
    by_kind[it["kind"]].append(it)


def prefix_of(name: str) -> str:
    # Plugin pack: "pack:skill" -> "pack:"
    if ":" in name:
        return name.split(":", 1)[0] + ":"
    # Hyphen family — for big flood families, go 2 segments deep so
    # saraev-biz-* / saraev-cc-* / saraev-outbound-* are separate rows
    # instead of collapsing 500+ skills into one unnavigable "saraev-*" bucket.
    DEEP_FAMILIES = {"saraev", "ariz", "tob", "hassid", "linkdrop", "mundi", "gstack", "rodman"}
    parts = name.split("-")
    if len(parts) >= 2 and len(parts[0]) >= 2:
        first = parts[0]
        if first in DEEP_FAMILIES and len(parts) >= 3:
            return f"{first}-{parts[1]}-*"
        return first + "-*"
    return name


def family_table(kind, top_n=30, min_count=3):
    c = Counter(prefix_of(it["name"]) for it in by_kind.get(kind, []))
    rows = sorted(c.items(), key=lambda x: (-x[1], x[0]))
    big = [(k, v) for k, v in rows if v >= min_count]
    small = [(k, v) for k, v in rows if v < min_count]
    lines = []
    for k, v in big[:top_n]:
        lines.append(f"| `{k}` | {v} |")
    if small:
        lines.append(f"| (other standalone) | {len(small)} |")
    return lines


def command_namespaces():
    c = Counter()
    for it in by_kind.get("command", []):
        n = it["name"].lstrip("/")
        ns = n.split(":", 1)[0] if ":" in n else "(root)"
        c[ns] += 1
    return sorted(c.items(), key=lambda x: (-x[1], x[0]))


def mcp_list():
    return sorted(it["name"] for it in by_kind.get("mcp", []))


# --- Build auto-generated tail (everything BELOW the marker) ---------------
tail_lines = []
tail_lines.append("")  # blank line after marker
tail_lines.append("# Auto-generated inventory")
tail_lines.append("")
tail_lines.append(f"**Registry built:** `{reg.get('generated_at', 'unknown')}`  ")
tail_lines.append(f"**Total items:** {reg.get('item_count', 0)}  ")
tail_lines.append(f"**Source:** `~/.claude/registry.json`  ")
tail_lines.append("**Regenerate:** `bash ~/.claude/scripts/build-toolkit-scout.sh`")
tail_lines.append("")
tail_lines.append("## Counts by kind")
tail_lines.append("")
tail_lines.append("| Kind | Count |")
tail_lines.append("|------|-------|")
for k in sorted(by_kind.keys()):
    tail_lines.append(f"| {k} | {len(by_kind[k])} |")
tail_lines.append("")
tail_lines.append("## Skill families (by slug prefix)")
tail_lines.append("")
tail_lines.append("_See curated head above for rich family descriptions. This table is raw counts only._")
tail_lines.append("")
tail_lines.append("| Family | Count |")
tail_lines.append("|--------|-------|")
tail_lines.extend(family_table("skill", top_n=40, min_count=3))
tail_lines.append("")
tail_lines.append("## Agent families")
tail_lines.append("")
tail_lines.append("| Family | Count |")
tail_lines.append("|--------|-------|")
tail_lines.extend(family_table("agent", top_n=30, min_count=2))
tail_lines.append("")
tail_lines.append("## Command namespaces")
tail_lines.append("")
tail_lines.append("| Namespace | Count |")
tail_lines.append("|-----------|-------|")
for ns, n in command_namespaces()[:40]:
    tail_lines.append(f"| `/{ns}:*`" + (" (root slash-commands)" if ns == "(root)" else "") + f" | {n} |")
tail_lines.append("")
tail_lines.append("## MCP servers")
tail_lines.append("")
for m in mcp_list():
    tail_lines.append(f"- `{m}`")
tail_lines.append("")

auto_tail = "\n".join(tail_lines)


# --- Fallback curated head (only used when file is brand new) --------------
DEFAULT_CURATED_HEAD = f"""---
name: toolkit-scout
description: Concierge index for the Claude Code toolkit on this machine — router-first rule, by-intent map, workflow recipes, and family descriptions. Auto-generated inventory appended below the marker via ~/.claude/scripts/build-toolkit-scout.sh.
---

# Toolkit Scout

> ⚠️ **Router-first rule.** If you are not sure which tool to use for a task, run:
> `bash ~/.claude/scripts/route.sh "<task description>" --top=5`
> **before** scrolling this file or guessing from names. The router scores the full registry ({reg.get('item_count', 0)} items) against your query and returns ranked matches with invocation syntax.

_Content above the marker is hand-maintained. Edit this file to add recipes or intent mappings. The marker below separates the curated head from the auto-generated inventory._

"""


# --- Marker-aware write logic ---------------------------------------------
if out.exists():
    existing = out.read_text(encoding="utf-8")
    marker_count = existing.count(MARKER)

    if marker_count == 0:
        # Treat as curated-only OR brand-new — write full template with default head.
        new_content = DEFAULT_CURATED_HEAD + MARKER + auto_tail
    elif marker_count == 1:
        head, _ = existing.split(MARKER, 1)
        # head retains trailing newline if user put one; that's preserved byte-for-byte
        new_content = head + MARKER + auto_tail
    else:
        print(
            f"toolkit-scout: ERROR — {marker_count} markers found in {out}. "
            f"Manual review required. Marker string: {MARKER!r}",
            file=sys.stderr,
        )
        sys.exit(3)
else:
    # Brand new file.
    new_content = DEFAULT_CURATED_HEAD + MARKER + auto_tail

# Ensure trailing newline.
if not new_content.endswith("\n"):
    new_content += "\n"

out.write_text(new_content, encoding="utf-8")
print(
    f"[toolkit-scout] wrote {out} "
    f"(tail {len(tail_lines)} lines, {reg.get('item_count', 0)} items, "
    f"marker_count={0 if not out.exists() else 'preserved'})"
)
PYEOF
