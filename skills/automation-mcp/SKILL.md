---
name: automation-mcp
description: Control your Mac with mouse, keyboard, screen capture, and window management via MCP. Use when the user wants AI to click, type, take screenshots, manage windows, or automate desktop tasks that have no API.
origin: ashwwwin/automation-mcp
---

# Automation MCP — macOS Desktop Control

MCP server giving Claude full desktop automation on macOS: mouse, keyboard, screenshots, window management.

## When to Activate

- User wants Claude to click buttons, fill forms, or navigate desktop apps
- Automating legacy software with no API
- Taking screenshots and analyzing screen content
- Managing windows (focus, resize, minimize)
- Any task requiring mouse/keyboard control

## Setup

### Prerequisites
- **Bun** runtime: `curl -fsSL https://bun.sh/install | bash`
- macOS **Accessibility** permission granted
- macOS **Screen Recording** permission granted

### Install
```bash
git clone https://github.com/ashwwwin/automation-mcp.git
cd automation-mcp
bun install
```

### Configure in Claude
Add to `~/.claude.json` under `mcpServers`:
```json
{
  "automation": {
    "command": "bun",
    "args": ["run", "/path/to/automation-mcp/index.ts", "--stdio"]
  }
}
```

Or use furi: `furi add ashwwwin/automation-mcp && furi start ashwwwin/automation-mcp`

## Available Tools

### Mouse Control
| Tool | What It Does |
|------|-------------|
| `mouseClick` | Click at coordinates (left/right/middle) |
| `mouseDoubleClick` | Double-click at coordinates |
| `mouseMove` | Move cursor to position |
| `mouseGetPosition` | Get current cursor location |
| `mouseScroll` | Scroll in any direction |
| `mouseDrag` | Drag from current position to target |
| `mouseMovePath` | Follow smooth path with multiple points |

### Keyboard Input
| Tool | What It Does |
|------|-------------|
| `type` | Type text or press key combinations |
| `keyControl` | Advanced key press/release control |
| `systemCommand` | Shortcuts: copy, paste, undo, save, etc. |

### Screen Capture & Analysis
| Tool | What It Does |
|------|-------------|
| `screenshot` | Capture full screen, regions, or windows |
| `screenInfo` | Get screen dimensions |
| `screenHighlight` | Highlight regions visually |
| `colorAt` | Get color of any pixel |
| `waitForImage` | Wait for image to appear (template matching) |

### Window Management
| Tool | What It Does |
|------|-------------|
| `getWindows` | List all open windows |
| `getActiveWindow` | Get current active window |
| `windowControl` | Focus, move, resize, minimize windows |

## Workflow Pattern

1. Take a `screenshot` to see the current state
2. Identify the target element coordinates
3. Use `mouseClick` or `type` to interact
4. Take another `screenshot` to verify the action
5. Repeat until task is complete

## Permissions Required

Grant in **System Settings > Privacy & Security**:
- **Accessibility** — mouse, keyboard, window control
- **Screen Recording** — screenshots, screen analysis, color detection

## Troubleshooting
- Permission denied: re-check Accessibility + Screen Recording toggles
- Xcode CLI tools needed: `xcode-select --install`
