#!/bin/bash
# Site Health Check — Kadenwood / Mundi Princeps infrastructure

SITES=(
  "https://war.kadenwoodgroup.com|Kadenwood CRM (Production)|"
  "https://kadenwoodgroup.com|Kadenwood Group Website|"
  "http://149.28.37.34:8080|mundi-ralph Agent Runtime|"
  "http://108.61.158.220:3001|Uptime Kuma|"
  "http://108.61.158.220:3030|Grafana|"
  "http://108.61.158.220:5678|n8n Workflows|"
  "http://198.23.249.137:8025/health|KadenVerify Email Verification|"
)

if [ ${#SITES[@]} -eq 0 ]; then
  echo "⚠️  No sites configured. Edit SITES array in this script."
  exit 0
fi

FAILED=0

for entry in "${SITES[@]}"; do
  IFS='|' read -r url name expected <<< "$entry"

  STATUS=$(curl -s -o /tmp/health_body -w "%{http_code}" -L --max-time 10 "$url" 2>/dev/null)

  if [ "$STATUS" -eq 200 ] || [ "$STATUS" -eq 301 ] || [ "$STATUS" -eq 302 ]; then
    if [ -n "$expected" ]; then
      if grep -q "$expected" /tmp/health_body 2>/dev/null; then
        echo "✅ $name ($url) — $STATUS + content OK"
      else
        echo "❌ $name ($url) — $STATUS but missing expected text: '$expected'"
        FAILED=1
      fi
    else
      echo "✅ $name ($url) — $STATUS"
    fi
  else
    echo "❌ $name ($url) — HTTP $STATUS"
    FAILED=1
  fi
done

rm -f /tmp/health_body
exit $FAILED
