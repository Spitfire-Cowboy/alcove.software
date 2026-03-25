# Federation Directory and Node Metadata Schema

Status: draft v0.1 (initial adopter-ready)

## 1) Objective

Define a stable directory format for discoverable Alcove nodes and federated query routing.

## 2) Registry Format

Registry document: JSON array of node records.

Example file:
- `site/federation/nodes.sample.json`

## 3) Node Schema

Required fields:

- `node_id` (string, globally unique, lowercase slug)
- `display_name` (string)
- `base_url` (HTTPS URL)
- `api_version` (string, example: `v1`)
- `mode` (enum: `public`, `private`, `hybrid`)
- `policy` (object)
- `capabilities` (object)

`policy` object:
- `allow_crawlers` (boolean)
- `contains_pii` (boolean)
- `data_license` (string)
- `notes` (string, optional)

`capabilities` object:
- `query` (boolean)
- `collections` (boolean)
- `health` (boolean)
- `languages` (array of ISO language codes)

## 4) Validation Rules

- `base_url` must be HTTPS.
- `node_id` must be unique within registry.
- `api_version` must match supported versions (`v1` initially).
- `mode=public` nodes must expose read-only query surface.
- Reject records missing required keys.

## 5) Health Probing Rules

Probe target:
- `GET {base_url}/health` (or `{base_url}/{api_version}/health` if declared)

Probe policy:
- interval: every 5 minutes
- timeout: 2 seconds
- unhealthy after 3 consecutive failures
- recover after 2 consecutive successes

## 6) Federated Merge/Ranking Strategy

1. Query fan-out to eligible nodes.
2. Normalize node-local scores to `0..1`.
3. Apply node trust weight (`default=1.0`, configurable by governance).
4. Deduplicate on canonical source key (`source.uri` hash preferred).
5. Enforce per-node result caps for diversity.
6. Return top-`k` globally ranked results with node attribution.

## 7) Compatibility and Evolution

- Backward-compatible additions allowed (new optional fields).
- Breaking changes require version bump and migration guidance.

