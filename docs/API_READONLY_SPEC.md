# Read-Only API Surface Spec (`api.alcove.software`)

Status: draft v0.1 (implementation-ready baseline)

## 1) Scope

Public API is read-only. It exposes discovery and query over explicitly public collections.

Out of scope:
- ingest/index mutation APIs
- private index exposure
- user account/session APIs

## 2) Base URL and Versioning

- Base URL: `https://api.alcove.software`
- Version prefix: `/v1`
- Media type: `application/json`

## 3) Endpoint Set

### `GET /v1/health`

Returns service readiness and version metadata.

Response example:

```json
{
  "status": "ok",
  "service": "alcove-readonly-api",
  "version": "0.1.0",
  "time_utc": "2026-03-25T00:00:00Z"
}
```

### `GET /v1/collections`

Returns public collection descriptors.

Response example:

```json
{
  "collections": [
    {
      "id": "public-demo",
      "title": "Public Demo Corpus",
      "mode": "public",
      "languages": ["en"],
      "document_count": 1240,
      "updated_at": "2026-03-20T16:00:00Z"
    }
  ]
}
```

### `GET /v1/collections/{collection_id}/stats`

Returns read-only aggregate stats for one collection.

Response example:

```json
{
  "id": "public-demo",
  "document_count": 1240,
  "chunk_count": 8650,
  "languages": ["en"],
  "last_indexed_at": "2026-03-20T16:00:00Z"
}
```

### `POST /v1/query`

Read-only query endpoint against one collection.

Request schema:

```json
{
  "query": "local-first retrieval",
  "collection_id": "public-demo",
  "k": 5,
  "mode": "hybrid",
  "language_filter": "en"
}
```

Response schema:

```json
{
  "query_id": "q_01HX...",
  "collection_id": "public-demo",
  "results": [
    {
      "id": "chunk_123",
      "score": 0.914,
      "text": "Alcove is local-first retrieval infrastructure...",
      "source": {
        "uri": "https://example.org/doc/abc",
        "title": "Example Doc",
        "license": "CC-BY-4.0"
      },
      "metadata": {
        "language": "en"
      }
    }
  ]
}
```

### `GET /v1/limits`

Publishes current rate limits and payload boundaries.

```json
{
  "query_per_minute_per_ip": 60,
  "max_k": 20,
  "max_query_chars": 500
}
```

## 4) Error Model

Standard envelope:

```json
{
  "error": {
    "code": "RATE_LIMITED",
    "message": "Too many requests",
    "request_id": "req_..."
  }
}
```

Common status codes:
- `400` invalid request
- `404` unknown collection
- `429` rate limited
- `500` internal error

## 5) Abuse Controls

- Per-IP rate limiting at edge and app layers.
- Request body size limits.
- Query payload validation and normalization.
- WAF/bot controls via Cloudflare.

## 6) Caching

- `GET /health`, `GET /collections`, and `GET /collections/{id}/stats` are cacheable.
- `POST /query` is non-cacheable by default unless explicit query caching is enabled.

## 7) Logging Policy

- Request ID + status + latency logged.
- Do not log full result text payloads at edge.
- Query text retention minimized and configurable by operator policy.

## 8) Deployment Topology

- Cloudflare edge (TLS, WAF, rate limits)
- Read-only API service (FastAPI)
- Public-index read replica (no write credentials)

## 9) Authentication Stance

- Default: anonymous read-only access with strict quotas.
- Optional API keys for higher quotas and partner integrations.
- No auth surface for private collections in this public API.

