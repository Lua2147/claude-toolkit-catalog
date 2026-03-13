---
name: talking-head
description: Generate talking-head avatar videos from a script. Handles ElevenLabs TTS audio generation and video synthesis. Use for content creation, deal outreach videos, or personalized messaging.
---

# Talking Head Video Generator

Create lip-synced avatar videos from text scripts.

## Pipeline
1. **Write script** — the words your avatar will speak
2. **Generate audio** — ElevenLabs TTS with your chosen voice
3. **Generate video** — VEED Fabric 1.0 via Fal API or similar

## Prerequisites

1. **ElevenLabs API Key** — store at `~/.config/elevenlabs/api_key`
2. **Fal API Key** — store at `~/.config/fal/api_key` (for video generation)
3. **Avatar image** — clear, front-facing headshot (512x512+)

## Quick Start

```bash
EL_KEY=$(cat ~/.config/elevenlabs/api_key)

# List available voices
curl -s "https://api.elevenlabs.io/v1/voices" \
  -H "xi-api-key: $EL_KEY" | python3 -c "
import sys, json
for v in json.load(sys.stdin)['voices'][:20]:
    print(f\"{v['voice_id']}: {v['name']}\")"

# Generate TTS audio
curl -s -X POST "https://api.elevenlabs.io/v1/text-to-speech/VOICE_ID" \
  -H "xi-api-key: $EL_KEY" \
  -H "Content-Type: application/json" \
  -d '{"text": "Your script here", "model_id": "eleven_multilingual_v2"}' \
  --output audio.mp3

# Then use Fal API for video synthesis with the audio
```

## Use Cases for Kadenwood
- **Personalized deal outreach** — video messages to potential sellers/partners
- **Founder updates** — periodic investor/partner communications
- **Content marketing** — LinkedIn video posts about deal themes
- **Training content** — onboarding materials for team members

## Costs
- ElevenLabs TTS: ~$0.15-0.30 per minute of audio
- Fal Fabric 1.0: ~$0.10-0.20 per video generation
- Total: ~$0.30-0.50 per short video (~30s-1min)

## Tips
- Keep scripts under 60 seconds for best quality
- Use a consistent avatar image for brand recognition
- Test with a short phrase before generating full videos
- Professional, warm tone matches Kadenwood brand voice
