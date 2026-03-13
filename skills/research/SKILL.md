---
name: research
description: Research topics using web search, X/Twitter search, and multiple search APIs. Use for finding companies, people, deal intelligence, media appearances, news, or any task requiring real-time web data.
---

# Research — Multi-Source Intelligence

## Available Search APIs

### 1. Brave Search (primary web search)
```bash
curl -s "https://api.search.brave.com/res/v1/web/search?q=YOUR+QUERY" \
  -H "Accept: application/json" \
  -H "Accept-Encoding: gzip" \
  -H "X-Subscription-Token: BSAKFFdW4RtKamRKzhXi0BrpKH-dKp2"
```

### 2. Exa Search (semantic search + content extraction)
```bash
curl -s "https://api.exa.ai/search" \
  -H "x-api-key: 145d7497-320e-4c12-9df7-ab9360d3183c" \
  -H "Content-Type: application/json" \
  -d '{"query": "YOUR QUERY", "numResults": 10, "type": "neural"}'
```

### 3. X/Twitter Search (via bearer token)
```bash
curl -s "https://api.twitter.com/2/tweets/search/recent?query=YOUR+QUERY&max_results=10" \
  -H "Authorization: Bearer AAAAAAAAAAAAAAAAAAAAANV%2B7wEAAAAA7XROxzmNxNM4pHrpr%2Fvq3S3SiJ0%3D8NdUTuW7OFgA8tGxdYFP0pG7uVhPcDrG4a086MBoO2sSibSNko"
```

### 4. Google Custom Search
```bash
curl -s "https://www.googleapis.com/customsearch/v1?key=AIzaSyAjkf1PTGF-SWwkbuMcA-URtFcS2pKg1-4&cx=e72776cce7839439e&q=YOUR+QUERY"
```

### 5. NewsAPI (news articles)
```bash
curl -s "https://newsapi.org/v2/everything?q=YOUR+QUERY&sortBy=publishedAt&apiKey=90013b16c8664ab48f96472f4775d4b2"
```

### 6. GNews (alternative news)
```bash
curl -s "https://gnews.io/api/v4/search?q=YOUR+QUERY&token=58d57737ae8ecb031fb2e025cd2d972e&lang=en"
```

## Deal Research Workflow

For researching potential acquisition targets or deal opportunities:

1. **Company search** — Brave + Exa for company info, financials, news
2. **People search** — LinkedIn (via linkedin-cli or Unipile), Apollo enrichment
3. **News/sentiment** — NewsAPI + GNews for recent coverage
4. **Social signals** — X/Twitter for founder activity, company mentions
5. **Financial data** — Alpha Vantage, FMP, Finnhub for public companies
6. **SEC filings** — edgartools skill for regulatory filings

## Person Research Workflow

1. LinkedIn profile via `linkedin-cli` or Unipile API
2. Apollo enrichment: `curl -s "https://api.apollo.io/v1/people/match" -H "Content-Type: application/json" -H "X-Api-Key: 5wmwBt1U5tQr5wfO_WHxnA" -d '{"email": "target@company.com"}'`
3. X/Twitter presence via bearer token search
4. News mentions via NewsAPI/GNews

## Tips
- Use Exa for semantic/conceptual searches ("companies doing AI in healthcare")
- Use Brave for factual lookups ("company X revenue 2025")
- Use NewsAPI for time-sensitive news
- Rate limits: Brave (1/sec), Exa (100/day free), NewsAPI (100/day free)
- All API keys are in `~/Mundi Princeps/config/api_keys.json`
