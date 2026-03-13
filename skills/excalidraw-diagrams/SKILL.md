---
name: excalidraw-diagrams
description: "Use when users explicitly mention 'Excalidraw' or request diagrams specifically with Excalidraw. Generates complete, valid .excalidraw files from natural language descriptions. Do NOT trigger for generic diagram requests without Excalidraw mention."
---

# Excalidraw Diagram Generator

## Overview

Generate complete, valid `.excalidraw` files that users can directly open at excalidraw.com. Creates beautiful, well-structured diagrams from descriptions with automatic layout calculation.

**Two visual styles:**
- **Professional Mode** (default): Clean, polished — `roughness: 0`, `fillStyle: "solid"`
- **Hand-drawn Mode**: Sketch-style — `roughness: 1`, `fillStyle: "hachure"`

## Supported Diagram Types

1. **Flowcharts** — Process flows, decision trees, workflows
2. **Architecture Diagrams** — System architectures, network topologies
3. **UML Diagrams** — Class diagrams, sequence diagrams
4. **Mind Maps** — Hierarchical concept maps

## Workflow

1. **Understand the request** — Identify diagram type and key content
2. **Choose style** — Professional (default) or hand-drawn if requested
3. **Generate elements** — Build JSON with proper properties and layout
4. **Calculate layout** — Use spacing guidelines
5. **Save to file** — Write complete JSON as `.excalidraw` file

## Element Types

- `rectangle` — Boxes, containers, processes
- `ellipse` — Start/end nodes, databases
- `diamond` — Decisions, conditional branches
- `arrow` / `line` — Connections, flows
- `text` — Labels, descriptions

## Essential Element Properties

```json
{
  "id": "unique-id",
  "type": "rectangle",
  "x": 100, "y": 100,
  "width": 150, "height": 80,
  "strokeColor": "#1e1e1e",
  "backgroundColor": "#a5d8ff",
  "fillStyle": "solid",
  "strokeWidth": 2,
  "roughness": 0,
  "opacity": 100,
  "roundness": { "type": 3 },
  "boundElements": [],
  "isDeleted": false
}
```

## Layout Guidelines

| Parameter | Value |
|-----------|-------|
| Min spacing between elements | 80-100px |
| Vertical flow gap | 120px |
| Horizontal sibling spacing | 150px |
| Arrow padding from edge | 10-20px |
| Small boxes | 120×60 |
| Medium boxes | 150×80 |
| Large boxes | 200×100 |

**Text height:** `fontSize × 1.25 × numberOfLines`

## Color Palettes

### Professional Mode (light backgrounds)
- Primary: `#e7f5ff` (light blue)
- Success: `#ebfbee` (light green)
- Warning: `#fff9db` (light yellow)
- Accent: `#f3f0ff` (light purple)
- Secondary: `#fff4e6` (light orange)

### Hand-drawn Mode (medium saturation)
- Primary: `#a5d8ff` (blue)
- Success: `#b2f2bb` (green)
- Warning: `#ffec99` (yellow)
- Error: `#ffc9c9` (red)
- Accent: `#d0bfff` (purple)

## Output

Always save directly as a `.excalidraw` file (not JSON in a code block). Name descriptively (e.g., `user-login-flow.excalidraw`).

After saving, tell the user: "Open the file at excalidraw.com using 'Open' → 'Open from your computer', or drag and drop the file into the browser."

## Tips

- Generate random 8-16 character IDs for each element
- Follow spacing guidelines strictly
- Match text width to container width with padding
- Position arrow start/end points precisely
- Use random integers for `versionNonce` and `seed`
