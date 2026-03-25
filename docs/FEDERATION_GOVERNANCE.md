# Federation Directory Governance

## Scope

Governance policy for federation registry files and schema updates.

## Change Process

1. Open PR with:
   - schema or registry change
   - rationale
   - compatibility note
2. Validate:
   - JSON parse checks
   - schema-required fields present
   - unique `node_id`
3. Merge after review and policy checks.

## Admission Policy

- Nodes must publish an explicit operator/contact path.
- Nodes must expose health endpoint and read-only query policy.
- Nodes with `contains_pii=true` are excluded from public default routing.

## Trust Weight Policy

- Default node weight: `1.0`.
- Lower weights for unstable or low-transparency nodes.
- Weights and rationale must be documented in PR discussion.

## Removal/Suspension

Immediate removal conditions:
- repeated health failures
- abuse/malicious behavior
- policy non-compliance

Removal is handled by PR to registry with linked incident note.

