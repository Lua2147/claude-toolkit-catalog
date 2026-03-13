---
name: blog-image-generator
description: Generate blog post hero images and marketing visuals using Google Gemini's image generation model. Use for content marketing, social media assets, or presentation graphics.
---

# Blog Image Generator

Generate high-quality images using Gemini's native image generation.

## API Key

From `~/Mundi Princeps/config/api_keys.json` under `deal_intent_signals_v1.gemini`:
```
API Key: AIzaSyAXviv9nylpdcF46132PJNtRYT1cPPyNQ4
```

## Quick Start

```bash
GEMINI_KEY="AIzaSyAXviv9nylpdcF46132PJNtRYT1cPPyNQ4"

curl -s -X POST \
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=$GEMINI_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "contents": [{
      "parts": [{"text": "Generate a blog hero image: bright, modern, clean composition showing [YOUR SUBJECT]. No text in the image. Photorealistic editorial style, warm natural lighting."}]
    }],
    "generationConfig": {
      "responseModalities": ["TEXT", "IMAGE"]
    }
  }' | python3 -c "
import sys, json, base64
data = json.load(sys.stdin)
for part in data['candidates'][0]['content']['parts']:
    if 'inlineData' in part:
        img = base64.b64decode(part['inlineData']['data'])
        with open('hero-image.png', 'wb') as f:
            f.write(img)
        print(f'Saved hero-image.png ({len(img)} bytes)')
"
```

## Kadenwood Brand Guidelines

When generating images for Kadenwood Group:
- **Colors**: Navy/dark blue, gold/amber accents, white space
- **Style**: Professional, institutional, premium financial services aesthetic
- **Subjects**: Modern office settings, skylines, abstract financial/growth imagery
- **Avoid**: Casual/startup vibes, bright neon colors, stock photo clichés

## Style Tips
- Always specify "no text in the image"
- Include lighting direction ("warm natural lighting", "soft diffused light")
- Reference a photographic style ("editorial", "lifestyle", "product photography")
- Aspect ratio defaults to square — crop after generation for blog headers (16:9)

## Use Cases
- Kadenwood website blog posts
- LinkedIn article headers
- Presentation slide backgrounds
- Deal teaser cover images
- Email campaign hero images
