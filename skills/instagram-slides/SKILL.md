---
name: instagram-slides
description: Turn content into Instagram/LinkedIn carousel slideshows with brand-consistent styling. Generates background images via AI and composites text overlays.
---

# Instagram / LinkedIn Slides

Turn content into carousel slideshows for social media.

## Pipeline
1. **Extract** — fetch content from URL or provide directly
2. **Plan** — write a `plan.json` with slide content and image prompts
3. **Generate Backgrounds** — AI image generation (Gemini or Fal API)
4. **Text Overlay** — Pillow composites text onto backgrounds with brand styling
5. **Output** — numbered slide images + `caption.txt`

## Quick Start

```bash
# Full pipeline
python3 ~/.claude/skills/instagram-slides/scripts/generate.py \
  --url "https://blog.example.com/post" \
  --slides 8 \
  --output ~/Desktop/slides

# Or from existing plan
python3 ~/.claude/skills/instagram-slides/scripts/generate.py \
  --plan-file ~/Desktop/slides/plan.json \
  --output ~/Desktop/slides
```

## Plan JSON Schema

```json
{
  "angle": "how-to | listicle | hot-take | story-arc | myth-busting",
  "style_prefix": "Shared image generation prompt prefix (~30 words)",
  "slides": [
    {
      "headline": "Short headline (≤8 words)",
      "body": "Supporting text (≤20 words)",
      "bg_prompt": "Background image description (NO text in image)",
      "is_title": true,
      "is_cta": false
    }
  ],
  "caption": "Full caption with hook, value, CTA, hashtags"
}
```

## Kadenwood Brand Style

- **Colors**: Navy (#1a2744), Gold (#c4a35a), White
- **Font feel**: Clean, modern, authoritative (sans-serif)
- **Image style**: "Professional editorial photography, warm natural lighting, premium financial services aesthetic"
- **Avoid**: Casual/startup vibes, baked-in text in generated images

## Use Cases
- LinkedIn thought leadership carousels
- Instagram deal highlights
- Conference/event recap slides
- Market insight summaries
- Team/culture content

## Dependencies
- Python 3 with `Pillow`, `requests`
- Gemini API key (in api_keys.json) or Fal API key
- Brand fonts in `~/.claude/skills/instagram-slides/fonts/`
