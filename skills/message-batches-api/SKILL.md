---
name: message-batches-api
description: Claude Message Batches API for processing 10,000+ items at 50% cost — batch lifecycle, polling, result retrieval, and error handling. Maps to CCA Domain 4.
---

# Message Batches API

## Overview

The Message Batches API processes large volumes of Claude requests asynchronously at 50% of standard API cost. Ideal for bulk classification, extraction, scoring, and review tasks where latency tolerance allows batch processing.

## Core Workflow

```
Create batch -> Poll status -> Retrieve results
     |              |               |
  POST /batches   GET /batches/{id}  GET /batches/{id}/results
```

## Creating a Batch

```python
import anthropic
import json

client = anthropic.Anthropic()

# Prepare requests (max 10,000 per batch)
requests = []
for i, document in enumerate(documents):
    requests.append({
        "custom_id": f"doc-{i}",  # Your tracking ID, returned with results
        "params": {
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 1024,
            "messages": [
                {"role": "user", "content": f"Classify this document:\n\n{document}"}
            ]
        }
    })

# Create the batch
batch = client.messages.batches.create(requests=requests)
print(f"Batch ID: {batch.id}")  # msgbatch_abc123
print(f"Status: {batch.processing_status}")  # "in_progress"
```

## Batch Lifecycle

| Status | Meaning | Action |
|--------|---------|--------|
| `in_progress` | Processing requests | Poll periodically |
| `ended` | All requests processed | Retrieve results |
| `canceling` | Cancel requested, finishing in-flight | Wait for `ended` |
| `expired` | Results not retrieved within 29 days | Data lost |

### Request-Level Status (within a batch)

| Status | Meaning |
|--------|---------|
| `succeeded` | Request completed successfully |
| `errored` | Request failed (invalid params, content policy) |
| `expired` | Request was not processed before batch timeout |
| `canceled` | Batch was canceled before this request ran |

## Polling for Completion

```python
import time

batch_id = batch.id
while True:
    batch = client.messages.batches.retrieve(batch_id)

    # Check counts
    total = batch.request_counts.processing + batch.request_counts.succeeded + \
            batch.request_counts.errored + batch.request_counts.expired + \
            batch.request_counts.canceled
    done = batch.request_counts.succeeded + batch.request_counts.errored

    print(f"Progress: {done}/{total}")

    if batch.processing_status == "ended":
        break

    time.sleep(60)  # Poll every 60 seconds
```

## Retrieving Results

```python
# Stream results (handles large result sets efficiently)
results = {}
for result in client.messages.batches.results(batch_id):
    custom_id = result.custom_id

    if result.result.type == "succeeded":
        message = result.result.message
        text = message.content[0].text
        results[custom_id] = {"status": "ok", "output": text}

    elif result.result.type == "errored":
        error = result.result.error
        results[custom_id] = {"status": "error", "error": error.message}

    elif result.result.type == "expired":
        results[custom_id] = {"status": "expired"}

print(f"Succeeded: {sum(1 for r in results.values() if r['status'] == 'ok')}")
print(f"Failed: {sum(1 for r in results.values() if r['status'] != 'ok')}")
```

## Cost Optimization

| Approach | Cost per 1M input tokens (Sonnet) |
|----------|----------------------------------|
| Standard API | $3.00 |
| Message Batches | $1.50 (50% discount) |
| + Prompt caching | ~$0.38 (cached portion at 90% discount) |

### Combining with Prompt Caching

For batches where all requests share a long system prompt:

```python
requests = [{
    "custom_id": f"doc-{i}",
    "params": {
        "model": "claude-sonnet-4-20250514",
        "max_tokens": 1024,
        "system": [
            {
                "type": "text",
                "text": long_system_prompt,  # Same across all requests
                "cache_control": {"type": "ephemeral"}
            }
        ],
        "messages": [{"role": "user", "content": doc}]
    }
} for i, doc in enumerate(documents)]
```

## Error Handling

```python
# Retry failed requests in a new batch
failed_ids = [cid for cid, r in results.items() if r["status"] == "error"]
if failed_ids:
    retry_requests = [r for r in original_requests if r["custom_id"] in failed_ids]
    retry_batch = client.messages.batches.create(requests=retry_requests)
```

## Canceling a Batch

```python
# Cancel stops unprocessed requests (in-flight requests still complete)
client.messages.batches.cancel(batch_id)
```

## When to Use

- Classifying or scoring 100+ documents
- Bulk extraction from financial filings, contracts, resumes
- Nightly data enrichment pipelines
- Generating embeddings/summaries for a document corpus
- Any workload where results are not needed in real-time

## Common Mistakes

1. **Not using `custom_id`**: Without it, you cannot match results back to source documents
2. **Polling too frequently**: Once per minute is sufficient — polling every second wastes API calls
3. **Ignoring partial failures**: Always check per-request status — a batch can "end" with some requests errored
4. **Exceeding 10,000 requests**: Split into multiple batches and track them independently
5. **Not retrieving results within 29 days**: Results expire — download and store them promptly
6. **Forgetting prompt caching**: For batches with shared system prompts, caching stacks with the 50% batch discount
