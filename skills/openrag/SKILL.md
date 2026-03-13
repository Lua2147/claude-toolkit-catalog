---
name: openrag
description: Deploy and use OpenRAG — a single-command RAG platform built on Langflow, Docling, and OpenSearch. Use for document Q&A, semantic search over deal materials, CIMs, financials, and any document corpus.
---

# OpenRAG

Open-source RAG platform that bundles Langflow (orchestration), Docling (document processing), and OpenSearch (vector + hybrid search) into a single deployable package.

## Quick Start

```bash
# Install and launch (requires Python 3.13 + uv)
mkdir openrag-workspace && cd openrag-workspace
uvx --python 3.13 openrag

# Or via pip
pip install openrag
```

The installer pulls Docker containers for all services. During setup:
1. Generate or enter OpenSearch + Langflow admin passwords
2. Press `N` to skip optional config and use defaults
3. Answer `Y` to start services

Config saves to `~/.openrag/tui/.env` with docker-compose files in same location.

## Requirements

- Python 3.13
- `uv` package manager (`pip install uv` or `brew install uv`)
- Docker or Podman
- OpenAI API key (for LLM; can be swapped for other providers in Langflow)

## Architecture

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│  Frontend    │────▶│  Backend     │────▶│  OpenSearch  │
│  (Next.js)   │     │  (FastAPI)   │     │  (vectors)   │
└─────────────┘     └──────┬───────┘     └─────────────┘
                           │
                    ┌──────┴───────┐
                    │  Langflow    │──── LLM Provider
                    │  (agents)    │
                    └──────┬───────┘
                           │
                    ┌──────┴───────┐
                    │  Docling     │
                    │  (parsing)   │
                    └──────────────┘
```

## SDK Usage

### Python
```python
import asyncio
from openrag_sdk import OpenRAGClient

async def main():
    async with OpenRAGClient() as client:
        # Upload a document
        await client.knowledge.upload("path/to/document.pdf")

        # Chat with your documents
        response = await client.chat.create(message="Summarize the key financials")
        print(response.response)

asyncio.run(main())
```

Install: `pip install openrag-sdk`

### TypeScript/JavaScript
```typescript
import { OpenRAGClient } from "openrag-sdk";

const client = new OpenRAGClient();
const response = await client.chat.create({ message: "What are the deal terms?" });
console.log(response.response);
```

Install: `npm install openrag-sdk`

## MCP Server Integration

Connect OpenRAG to Claude Code or Cursor as an MCP tool:

```bash
pip install openrag-mcp
```

Environment variables needed:
- `OPENRAG_URL` — URL of your running OpenRAG instance
- `OPENRAG_API_KEY` — API key for authentication

## Docker Deployment

```bash
# Standard
docker compose up -d

# Development
docker compose -f docker-compose.dev.yml up -d

# GPU-enabled (for local embeddings)
docker compose -f docker-compose.gpu.yml up -d
```

## Kadenwood Use Cases

- **Deal document Q&A** — Upload CIMs, teasers, financials; ask questions across the corpus
- **Due diligence research** — Ingest DD materials and run semantic search for specific clauses, risks, or metrics
- **Portfolio knowledge base** — Index all portfolio company documents for cross-company analysis
- **DDQ generation** — Chat with historical DDQs to draft new responses
- **Market research synthesis** — Upload research reports and extract insights via natural language

## Deployment Options

| Option | Best for |
|--------|----------|
| `uvx openrag` | Local dev, quick testing |
| Docker Compose | Production single-node |
| Kubernetes/Helm | Enterprise scale (`kubernetes/helm/openrag/`) |

## Key URLs (when running locally)

- Frontend UI: `http://localhost:3000`
- Backend API: `http://localhost:8000`
- Langflow editor: `http://localhost:7860`
- OpenSearch: `http://localhost:9200`

## Tips

- Docling handles messy PDFs well — scanned documents, tables, mixed layouts
- Use the Langflow visual editor to customize the RAG pipeline (re-rankers, chunking strategy, agent behavior)
- OpenSearch supports hybrid search (keyword + vector) out of the box
- Swap OpenAI for any LLM provider via Langflow settings
- Apache 2.0 licensed — safe for commercial use
