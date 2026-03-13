#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "Claude Code Toolkit Installer"
echo "=============================="
echo ""

# Check prerequisites
if [ ! -d "$CLAUDE_DIR" ]; then
    echo "Creating ~/.claude directory..."
    mkdir -p "$CLAUDE_DIR"
fi

# Skills
echo "Installing 212 skills..."
mkdir -p "$CLAUDE_DIR/skills"
cp -R "$SCRIPT_DIR/skills/"* "$CLAUDE_DIR/skills/" 2>/dev/null || true
SKILL_COUNT=$(ls -d "$CLAUDE_DIR/skills"/*/ 2>/dev/null | wc -l | tr -d ' ')
echo "  ✓ $SKILL_COUNT skills installed to ~/.claude/skills/"

# Agents
echo "Installing agents..."
mkdir -p "$CLAUDE_DIR/agents"
cp "$SCRIPT_DIR/agents/"*.md "$CLAUDE_DIR/agents/" 2>/dev/null || true
AGENT_COUNT=$(ls "$CLAUDE_DIR/agents/"*.md 2>/dev/null | wc -l | tr -d ' ')
echo "  ✓ $AGENT_COUNT agents installed to ~/.claude/agents/"

# Commands
echo "Installing commands..."
mkdir -p "$CLAUDE_DIR/commands"
cp "$SCRIPT_DIR/commands/"*.md "$CLAUDE_DIR/commands/" 2>/dev/null || true
if [ -d "$SCRIPT_DIR/commands/gsd" ]; then
    cp -R "$SCRIPT_DIR/commands/gsd" "$CLAUDE_DIR/commands/"
fi
CMD_COUNT=$(find "$CLAUDE_DIR/commands" -name "*.md" | wc -l | tr -d ' ')
echo "  ✓ $CMD_COUNT commands installed to ~/.claude/commands/"

# GSD Pipeline System
echo "Installing GSD pipeline system..."
if [ -d "$SCRIPT_DIR/gsd" ]; then
    cp -R "$SCRIPT_DIR/gsd" "$CLAUDE_DIR/get-shit-done"
    GSD_COUNT=$(find "$CLAUDE_DIR/get-shit-done" -type f | wc -l | tr -d ' ')
    echo "  ✓ $GSD_COUNT GSD files installed to ~/.claude/get-shit-done/"
else
    echo "  ⚠ GSD directory not found, skipping"
fi

echo ""
echo "Installation complete!"
echo ""
echo "Next steps:"
echo "  1. Install plugin packs in Claude Code settings"
echo "  2. Configure MCP servers in ~/.claude.json"
echo "  3. Install CLI tools: RTK, QMD, GWS CLI"
echo "  4. See README.md for full setup guide"
