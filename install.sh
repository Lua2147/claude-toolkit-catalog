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
echo "Installing skills..."
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
for dir in "$SCRIPT_DIR/commands"/*/; do
    [ -d "$dir" ] && cp -R "$dir" "$CLAUDE_DIR/commands/"
done
CMD_COUNT=$(find "$CLAUDE_DIR/commands" -name "*.md" | wc -l | tr -d ' ')
echo "  ✓ $CMD_COUNT commands installed to ~/.claude/commands/"

# Rules
echo "Installing rules..."
mkdir -p "$CLAUDE_DIR/rules"
cp "$SCRIPT_DIR/rules/"*.md "$CLAUDE_DIR/rules/" 2>/dev/null || true
RULE_COUNT=$(ls "$CLAUDE_DIR/rules/"*.md 2>/dev/null | wc -l | tr -d ' ')
echo "  ✓ $RULE_COUNT rules installed to ~/.claude/rules/"

# Contexts
echo "Installing contexts..."
mkdir -p "$CLAUDE_DIR/contexts"
cp "$SCRIPT_DIR/contexts/"*.md "$CLAUDE_DIR/contexts/" 2>/dev/null || true
CTX_COUNT=$(ls "$CLAUDE_DIR/contexts/"*.md 2>/dev/null | wc -l | tr -d ' ')
echo "  ✓ $CTX_COUNT contexts installed to ~/.claude/contexts/"

# Templates
echo "Installing CLAUDE.md templates..."
mkdir -p "$CLAUDE_DIR/templates/claude-md"
cp "$SCRIPT_DIR/templates/claude-md/"*.md "$CLAUDE_DIR/templates/claude-md/" 2>/dev/null || true
TPL_COUNT=$(ls "$CLAUDE_DIR/templates/claude-md/"*.md 2>/dev/null | wc -l | tr -d ' ')
echo "  ✓ $TPL_COUNT templates installed to ~/.claude/templates/claude-md/"

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
