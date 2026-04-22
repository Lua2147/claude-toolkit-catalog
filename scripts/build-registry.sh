#!/usr/bin/env bash
# build-registry.sh — Unified toolkit registry generator (Phase 3, Stream 1G).
#
# Walks skills, agents, commands, MCPs, scripts and writes:
#   ~/.claude/registry.json              — item catalog
#   ~/.claude/registry-embeddings.json   — keyword index per item
#
# Idempotent: output bytes are identical across runs on a clean tree
# (generated_at is fixed to the newest source mtime, not wall clock).
#
# Usage: bash ~/.claude/scripts/build-registry.sh

set -euo pipefail

HERE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_REGISTRY="$HOME/.claude/registry.json"
OUT_EMBEDDINGS="$HOME/.claude/registry-embeddings.json"

python3 - "$OUT_REGISTRY" "$OUT_EMBEDDINGS" <<'PYEOF'
import json
import os
import re
import sys
from pathlib import Path

OUT_REGISTRY = Path(sys.argv[1])
OUT_EMBEDDINGS = Path(sys.argv[2])

HOME = Path.home()
MP_ROOT = HOME / "Mundi Princeps"

SKILLS_DIR = HOME / ".claude" / "skills"
AGENTS_DIR = HOME / ".claude" / "agents"
COMMANDS_DIR = HOME / ".claude" / "commands"
SCRIPTS_DIR = MP_ROOT / "scripts"
USER_CLAUDE_JSON = HOME / ".claude.json"
PROJ_MCP_JSON = MP_ROOT / ".mcp.json"


def abbrev(p: Path) -> str:
    s = str(p)
    home = str(HOME)
    if s.startswith(home):
        return "~" + s[len(home):]
    return s


def parse_frontmatter(text: str):
    """Return (frontmatter_dict, body). Tolerant of YAML keys with colons."""
    if not text.startswith("---"):
        return {}, text
    end = text.find("\n---", 3)
    if end == -1:
        return {}, text
    fm_block = text[3:end].strip("\n")
    body = text[end + 4:].lstrip("\n")
    fm = {}
    current_key = None
    for line in fm_block.split("\n"):
        if not line.strip():
            continue
        m = re.match(r"^([A-Za-z0-9_\-]+)\s*:\s*(.*)$", line)
        if m:
            current_key = m.group(1).strip()
            val = m.group(2).strip()
            fm[current_key] = val
        elif current_key and line.startswith(" "):
            fm[current_key] = (fm[current_key] + " " + line.strip()).strip()
    return fm, body


# Patterns for Claude chat output accidentally persisted at the top of a
# SKILL.md (common on auto-generated skills missing proper --- frontmatter).
# Skipped during fallback body scan so they don't become the description.
_CHAT_ARTIFACT_PATTERNS = [
    re.compile(r"^all\s+\S+\s+files?\s+(created|written|generated)", re.IGNORECASE),
    re.compile(r"^here\.?s\s+what\s+(was|is)", re.IGNORECASE),
    re.compile(r"^done[.,]?\s+\S+\s+files?", re.IGNORECASE),
    re.compile(r"^(okay|great|perfect)[.,]\s", re.IGNORECASE),
    re.compile(r"^the\s+\*{0,2}\w[\w\-]*\*{0,2}\s+skill\s+is\s+created", re.IGNORECASE),
]


def extract_description(fm: dict, text: str, body: str) -> str:
    """Best-effort description extraction tolerant of malformed SKILL.md files.

    Preference order:
    1. fm['description'] from proper YAML frontmatter.
    2. Inline 'description: ...' line in body (pseudo-frontmatter, no --- block).
    3. First body line that is not a heading, blank, or Claude chat artifact.
    """
    desc = (fm.get("description") or "").strip()
    if desc:
        return desc
    for line in (body or text).split("\n"):
        s = line.strip()
        if not s or s.startswith("#") or s == "---":
            continue
        m = re.match(r"^description\s*:\s*(.+)$", s, re.IGNORECASE)
        if m:
            return m.group(1).strip()[:280]
        if any(p.match(s) for p in _CHAT_ARTIFACT_PATTERNS):
            continue
        return s[:280]
    return ""


def tokenize(*parts):
    """Lowercase word-set for keyword-fallback index."""
    buf = " ".join(p for p in parts if p)
    buf = buf.lower()
    tokens = re.findall(r"[a-z0-9][a-z0-9_\-]{1,}", buf)
    stop = {
        "the", "and", "for", "with", "use", "this", "that", "from", "when",
        "into", "you", "your", "are", "not", "but", "all", "any", "can",
        "has", "have", "was", "were", "will", "would", "should", "could",
        "there", "their", "they", "them", "these", "those", "what", "which",
        "who", "how", "why", "also", "other", "than", "then", "just", "only",
        "about", "over", "under", "been", "being", "per", "via", "our", "out",
    }
    seen = []
    for t in tokens:
        if t in stop or len(t) < 2:
            continue
        if t not in seen:
            seen.append(t)
    return seen


def parse_tags(raw):
    if not raw:
        return []
    raw = raw.strip()
    if raw.startswith("[") and raw.endswith("]"):
        inner = raw[1:-1]
        parts = [p.strip().strip("'\"") for p in inner.split(",")]
        return [p for p in parts if p]
    return [p.strip() for p in raw.split(",") if p.strip()]


items = []


# -----------------------------------------------------------------------------
# Skills (~/.claude/skills/*/SKILL.md, also nested plugin packs)
# -----------------------------------------------------------------------------
def walk_skills():
    if not SKILLS_DIR.exists():
        return
    for skill_md in sorted(SKILLS_DIR.rglob("SKILL.md")):
        rel_parts = skill_md.relative_to(SKILLS_DIR).parts
        # Name is the directory containing SKILL.md (last dir component).
        if len(rel_parts) >= 2:
            name = rel_parts[-2]
        else:
            name = skill_md.stem
        try:
            text = skill_md.read_text(encoding="utf-8", errors="replace")
        except Exception:
            text = ""
        fm, body = parse_frontmatter(text)
        desc = extract_description(fm, text, body)
        tags = parse_tags(fm.get("tags", ""))
        source = fm.get("source", "").strip()
        # If skill lives inside a plugin-pack subtree, prefix with pack name
        # so the id stays unique (e.g. document-skills:pdf vs skill:pdf).
        plugin_pack = None
        if len(rel_parts) > 2:
            # e.g. document-skills/pdf/SKILL.md -> pack=document-skills
            plugin_pack = rel_parts[0]
        if plugin_pack:
            full_name = f"{plugin_pack}:{name}"
        else:
            full_name = name
        item_id = f"skill:{full_name}"
        invoke = f"Skill({{skill: '{full_name}'}})"
        items.append({
            "id": item_id,
            "kind": "skill",
            "name": full_name,
            "path": abbrev(skill_md),
            "description": desc,
            "tags": tags,
            "source": source,
            "invoke_syntax": invoke,
        })


# -----------------------------------------------------------------------------
# Plugin-pack skills (~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/skills/<name>/SKILL.md)
#
# Walks ONLY the cache directory (installed skills). Does NOT walk
# ~/.claude/plugins/marketplaces/ — that contains upstream templates (~3,365
# SKILL.md files), which are promoted to cache only when /plugin install runs.
# Cache is the source of truth for what Claude actually loads.
#
# Version dedup: if the same (marketplace, plugin) pair appears at multiple
# versions (e.g. superpowers 4.1.1 and 4.3.1), keep only the newest by mtime.
# -----------------------------------------------------------------------------
PLUGINS_CACHE_DIR = HOME / ".claude" / "plugins" / "cache"


def walk_plugin_skills():
    if not PLUGINS_CACHE_DIR.exists():
        return

    # Pass 1 — group SKILL.md files by (marketplace, plugin), tracking version mtimes.
    by_pack = {}  # (marketplace, plugin) -> {version: (version_dir, [skill_paths])}
    for skill_md in PLUGINS_CACHE_DIR.rglob("SKILL.md"):
        try:
            rel_parts = skill_md.relative_to(PLUGINS_CACHE_DIR).parts
        except ValueError:
            continue
        # Expect: <marketplace>/<plugin>/<version>/skills/<name>/SKILL.md (6 parts)
        # or rarer: <marketplace>/<plugin>/<version>/template/SKILL.md (5 parts, skip)
        if len(rel_parts) < 6:
            continue
        marketplace, plugin, version, container, skill_name = rel_parts[:5]
        if container != "skills":
            continue
        key = (marketplace, plugin)
        version_dir = PLUGINS_CACHE_DIR / marketplace / plugin / version
        by_pack.setdefault(key, {}).setdefault(version, (version_dir, []))[1].append(skill_md)

    # Pass 2 — for each pack, keep only the newest-mtime version's skills.
    for (marketplace, plugin), versions in by_pack.items():
        if not versions:
            continue
        # Pick newest version by version-dir mtime.
        newest_version = max(
            versions.keys(),
            key=lambda v: versions[v][0].stat().st_mtime if versions[v][0].exists() else 0.0,
        )
        _, skill_paths = versions[newest_version]

        for skill_md in sorted(skill_paths):
            rel_parts = skill_md.relative_to(PLUGINS_CACHE_DIR).parts
            skill_name = rel_parts[4]  # <marketplace>/<plugin>/<version>/skills/<name>/SKILL.md
            try:
                text = skill_md.read_text(encoding="utf-8", errors="replace")
            except Exception:
                text = ""
            fm, body = parse_frontmatter(text)
            desc = extract_description(fm, text, body)
            tags = parse_tags(fm.get("tags", ""))
            full_name = f"{plugin}:{skill_name}"
            item_id = f"skill:{full_name}"
            # Source points to the version root (for provenance + easy inspection).
            plugin_root = PLUGINS_CACHE_DIR / marketplace / plugin / newest_version
            items.append({
                "id": item_id,
                "kind": "skill",
                "name": full_name,
                "path": abbrev(skill_md),
                "description": desc,
                "tags": tags,
                "source": abbrev(plugin_root),
                "invoke_syntax": f"Skill({{skill: '{full_name}'}})",
            })


# -----------------------------------------------------------------------------
# Agents (~/.claude/agents/*.md)
# -----------------------------------------------------------------------------
def walk_agents():
    if not AGENTS_DIR.exists():
        return
    for md in sorted(AGENTS_DIR.rglob("*.md")):
        if md.name.lower() in {"readme.md", "index.md"}:
            continue
        try:
            text = md.read_text(encoding="utf-8", errors="replace")
        except Exception:
            text = ""
        fm, body = parse_frontmatter(text)
        name = fm.get("name", md.stem).strip() or md.stem
        desc = extract_description(fm, text, body)
        tags = parse_tags(fm.get("tags", ""))
        source = fm.get("model", "").strip()  # record model as source hint
        item_id = f"agent:{name}"
        items.append({
            "id": item_id,
            "kind": "agent",
            "name": name,
            "path": abbrev(md),
            "description": desc,
            "tags": tags,
            "source": source,
            "invoke_syntax": f"Task(subagent_type='{name}', ...)",
        })


# -----------------------------------------------------------------------------
# Commands (~/.claude/commands/**/*.md)
# Each file is a slash command. Subdir becomes the namespace.
# -----------------------------------------------------------------------------
def walk_commands():
    if not COMMANDS_DIR.exists():
        return
    for md in sorted(COMMANDS_DIR.rglob("*.md")):
        if md.name.lower() in {"readme.md", "index.md"}:
            continue
        rel = md.relative_to(COMMANDS_DIR)
        parts = list(rel.parts)
        stem = md.stem
        if len(parts) == 1:
            slash_name = f"/{stem}"
        else:
            namespace = ":".join(parts[:-1])
            slash_name = f"/{namespace}:{stem}"
        try:
            text = md.read_text(encoding="utf-8", errors="replace")
        except Exception:
            text = ""
        fm, body = parse_frontmatter(text)
        desc = extract_description(fm, text, body)
        tags = parse_tags(fm.get("tags", ""))
        source = fm.get("source", "").strip()
        item_id = f"command:{slash_name}"
        items.append({
            "id": item_id,
            "kind": "command",
            "name": slash_name,
            "path": abbrev(md),
            "description": desc,
            "tags": tags,
            "source": source,
            "invoke_syntax": slash_name,
        })


# -----------------------------------------------------------------------------
# MCPs (union of ~/.claude.json mcpServers + project-scoped + .mcp.json)
# -----------------------------------------------------------------------------
def walk_mcps():
    mcp_servers = {}  # name -> (source_path, config)

    # 1. ~/.claude.json root + per-project
    if USER_CLAUDE_JSON.exists():
        try:
            cfg = json.loads(USER_CLAUDE_JSON.read_text(encoding="utf-8"))
        except Exception:
            cfg = {}
        root_mcps = cfg.get("mcpServers", {}) or {}
        for n, c in root_mcps.items():
            mcp_servers.setdefault(n, (abbrev(USER_CLAUDE_JSON), c))
        for proj_path, proj_cfg in (cfg.get("projects", {}) or {}).items():
            for n, c in (proj_cfg.get("mcpServers", {}) or {}).items():
                mcp_servers.setdefault(n, (abbrev(USER_CLAUDE_JSON), c))

    # 2. Project .mcp.json
    if PROJ_MCP_JSON.exists():
        try:
            cfg = json.loads(PROJ_MCP_JSON.read_text(encoding="utf-8"))
        except Exception:
            cfg = {}
        for n, c in (cfg.get("mcpServers", {}) or {}).items():
            # Project scope wins for provenance if not in user scope.
            if n not in mcp_servers:
                mcp_servers[n] = (abbrev(PROJ_MCP_JSON), c)

    for name in sorted(mcp_servers):
        source_path, cfg = mcp_servers[name]
        kind_hint = cfg.get("type") or ("http" if "url" in cfg else "stdio")
        url = cfg.get("url", "")
        cmd = cfg.get("command", "")
        args = cfg.get("args", []) or []
        desc_bits = []
        if url:
            desc_bits.append(f"{kind_hint} {url}")
        elif cmd:
            joined = " ".join([cmd] + [str(a) for a in args])
            desc_bits.append(f"{kind_hint} {joined}")
        desc = " | ".join(desc_bits) or f"MCP server ({kind_hint})"
        items.append({
            "id": f"mcp:{name}",
            "kind": "mcp",
            "name": name,
            "path": source_path,
            "description": desc,
            "tags": [kind_hint],
            "source": source_path,
            "invoke_syntax": f"mcp__{name.replace('-', '_')}__<tool>",
        })


# -----------------------------------------------------------------------------
# Scripts (Mundi Princeps/scripts/**/*.{sh,py,js} up to depth 3)
# -----------------------------------------------------------------------------
def walk_scripts():
    if not SCRIPTS_DIR.exists():
        return
    exts = {".sh", ".py", ".js"}
    MAX_DEPTH = 3
    for p in sorted(SCRIPTS_DIR.rglob("*")):
        if not p.is_file():
            continue
        if p.suffix.lower() not in exts:
            continue
        try:
            rel_parts = p.relative_to(SCRIPTS_DIR).parts
        except ValueError:
            continue
        if len(rel_parts) > MAX_DEPTH:
            continue
        name = "/".join(rel_parts)  # keep subdirs for uniqueness
        desc = ""
        try:
            with p.open("r", encoding="utf-8", errors="replace") as fh:
                head_lines = []
                for i, line in enumerate(fh):
                    if i >= 40:
                        break
                    head_lines.append(line.rstrip("\n"))
        except Exception:
            head_lines = []
        # Extract first meaningful comment line as description.
        for line in head_lines:
            s = line.strip()
            if not s:
                continue
            if s.startswith("#!"):  # shebang
                continue
            if s.startswith("#"):
                cleaned = s.lstrip("#").strip()
                if cleaned:
                    desc = cleaned[:280]
                    break
            elif s.startswith('"""') or s.startswith("'''"):
                cleaned = s.strip('"\' ')
                if cleaned:
                    desc = cleaned[:280]
                    break
            elif s.startswith("//"):
                cleaned = s.lstrip("/").strip()
                if cleaned:
                    desc = cleaned[:280]
                    break
            elif s.startswith("/*"):
                cleaned = s.lstrip("/* ").rstrip("*/ ").strip()
                if cleaned:
                    desc = cleaned[:280]
                    break
        if not desc:
            desc = f"{p.suffix[1:]} script at {name}"
        items.append({
            "id": f"script:{name}",
            "kind": "script",
            "name": name,
            "path": abbrev(p),
            "description": desc,
            "tags": [p.suffix[1:]],
            "source": "",
            "invoke_syntax": f"bash '{abbrev(p)}'"
            if p.suffix == ".sh"
            else (f"python3 '{abbrev(p)}'" if p.suffix == ".py" else f"node '{abbrev(p)}'"),
        })


# Execute walks.
walk_skills()
walk_plugin_skills()
walk_agents()
walk_commands()
walk_mcps()
walk_scripts()

# -----------------------------------------------------------------------------
# De-duplicate by id (first occurrence wins) and record collisions.
# -----------------------------------------------------------------------------
seen_ids = {}
collisions = []
dedup = []
for it in items:
    if it["id"] in seen_ids:
        collisions.append({
            "id": it["id"],
            "first_path": seen_ids[it["id"]]["path"],
            "dup_path": it["path"],
        })
        continue
    seen_ids[it["id"]] = it
    dedup.append(it)

# Sort for deterministic output.
dedup.sort(key=lambda x: (x["kind"], x["id"]))

# Deterministic generated_at: newest mtime across considered sources.
def max_mtime(paths):
    best = 0.0
    for p in paths:
        try:
            if p.exists():
                best = max(best, p.stat().st_mtime)
                if p.is_dir():
                    for c in p.rglob("*"):
                        if c.is_file():
                            try:
                                best = max(best, c.stat().st_mtime)
                            except OSError:
                                pass
        except OSError:
            pass
    return best


latest = max_mtime([
    SKILLS_DIR, AGENTS_DIR, COMMANDS_DIR, USER_CLAUDE_JSON, PROJ_MCP_JSON, SCRIPTS_DIR,
    PLUGINS_CACHE_DIR,
])
from datetime import datetime, timezone
generated_at = (
    datetime.fromtimestamp(latest, tz=timezone.utc)
    .replace(microsecond=0)
    .isoformat()
    .replace("+00:00", "Z")
    if latest
    else "1970-01-01T00:00:00Z"
)

registry = {
    "version": "1.0",
    "generated_at": generated_at,
    "item_count": len(dedup),
    "embedding_method": "keyword-fallback",
    "kinds": sorted({it["kind"] for it in dedup}),
    "per_kind_count": {
        k: sum(1 for it in dedup if it["kind"] == k)
        for k in sorted({it["kind"] for it in dedup})
    },
    "collisions": collisions,
    "items": dedup,
}

# Keyword-fallback embeddings: tokenize name + description + tags.
embeddings = {
    it["id"]: tokenize(it["name"], it["description"], " ".join(it.get("tags", [])))
    for it in dedup
}

OUT_REGISTRY.parent.mkdir(parents=True, exist_ok=True)
OUT_REGISTRY.write_text(
    json.dumps(registry, indent=2, sort_keys=False, ensure_ascii=False) + "\n",
    encoding="utf-8",
)
OUT_EMBEDDINGS.write_text(
    json.dumps(embeddings, indent=2, sort_keys=True, ensure_ascii=False) + "\n",
    encoding="utf-8",
)

print(f"[registry] item_count={len(dedup)} collisions={len(collisions)} -> {OUT_REGISTRY}")
for k, v in registry["per_kind_count"].items():
    print(f"  {k}: {v}")
PYEOF

# -----------------------------------------------------------------------------
# Auto-regenerate toolkit-scout/SKILL.md from the freshly built registry
# so the static inventory never drifts from registry.json.
# -----------------------------------------------------------------------------
if [ -x "$HERE_DIR/build-toolkit-scout.sh" ]; then
  bash "$HERE_DIR/build-toolkit-scout.sh" || echo "[warn] toolkit-scout regeneration failed" >&2
fi
