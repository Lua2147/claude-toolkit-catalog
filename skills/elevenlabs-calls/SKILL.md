---
name: elevenlabs-calls
description: Make AI phone calls using ElevenLabs Conversational AI and Twilio/Telnyx. Use for automated outbound calls, appointment follow-ups, or deal outreach.
---

# AI Phone Calls — ElevenLabs + Telnyx/Twilio

Make outbound AI phone calls using conversational AI agents.

## Available Phone Infrastructure

### Telnyx (primary — configured)
- **Numbers**: configured in `config/api_keys.json`
- **10DLC registered**: brand and campaign IDs in `config/api_keys.json`
- **API key**: in `config/api_keys.json` under `telnyx`
- Supports: SMS, Voice, WebRTC

### Twilio (secondary)
- **Number**: configured in `config/api_keys.json`
- **Account SID**: in `config/api_keys.json` under `twilio`
- **Auth token**: in `config/api_keys.json` under `twilio`

## ElevenLabs Setup (required for AI voice)

1. Get API key at https://elevenlabs.io
2. Store at `~/.config/elevenlabs/api_key`
3. Create a Conversational AI agent at https://elevenlabs.io/app/agents
4. Import your Telnyx/Twilio number into ElevenLabs

## Quick Start

```bash
EL_KEY=$(cat ~/.config/elevenlabs/api_key)

# List agents
curl -s "https://api.elevenlabs.io/v1/convai/agents" \
  -H "xi-api-key: $EL_KEY"

# List voices
curl -s "https://api.elevenlabs.io/v1/voices" \
  -H "xi-api-key: $EL_KEY" | python3 -c "
import sys, json
for v in json.load(sys.stdin)['voices']:
    print(f\"{v['voice_id']}: {v['name']}\")"

# Make outbound call
curl -s -X POST "https://api.elevenlabs.io/v1/convai/twilio/outbound" \
  -H "xi-api-key: $EL_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "agent_id": "YOUR_AGENT_ID",
    "agent_phone_number_id": "YOUR_PHONE_ID",
    "to_number": "+15551234567",
    "custom_llm_extra_body": {
      "dynamic_variables": {
        "name": "John",
        "company": "Acme Corp",
        "reason": "Following up on our conversation about growth capital"
      }
    }
  }'
```

## Use Cases for Kadenwood

1. **Deal follow-up** — automated calls to prospects after initial outreach
2. **Appointment confirmation** — confirm meetings with capital partners
3. **Pipeline warming** — re-engage stale opportunities
4. **Data collection** — qualify leads via structured phone conversations

## Costs
- ElevenLabs: ~$0.07-0.15/min (depending on plan)
- Telnyx voice: ~$0.007/min outbound US
- Twilio voice: ~$0.014/min outbound US
