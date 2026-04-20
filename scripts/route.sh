#!/usr/bin/env bash
# route.sh — thin forwarder to the real router-hub implementation
# Source of truth: ~/.claude/skills/router-hub/scripts/route.sh
# This wrapper exists so docs, skills, and memory can cite a stable path.
exec bash "${HOME}/.claude/skills/router-hub/scripts/route.sh" "$@"
