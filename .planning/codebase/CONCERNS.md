# CONCERNS

## Current Risk Profile
This is a newly bootstrapped Rails API codebase. Main risks are setup/operational consistency and future architectural drift.

## Immediate Technical Concerns
- Rails version pinned to `8.0.4` (not latest 8.1.x line).
- Ruby pinned to `3.3.0`; local environments must match to avoid dependency/runtime issues.
- Framework defaults were intentionally reduced (selected railties only), which can break assumptions when adding generators/features.

## Dependency/Tooling Concerns
- Gems for `solid_queue`, `solid_cache`, `solid_cable` are present but not exercised.
- Kamal deployment files were scaffolded but likely not production-ready yet.
- Security/lint tooling exists but CI policy is not yet enforced in repository workflow.

## Architecture Concerns
- No domain boundaries or API versioning strategy yet.
- No shared JSON response/error envelope defined.
- No authentication or authorization baseline.

## Operational Concerns
- Healthcheck exists (`/up`) but no readiness/dependency checks (DB/cache) beyond process liveness.
- No explicit observability stack (metrics/tracing/structured logging) configured.
- Database config assumes local PostgreSQL availability; onboarding friction is possible.

## Testing Concerns
- Very low functional surface tested (healthcheck only).
- No regression protection for future endpoint growth yet.

## Recommended Mitigations (Short Term)
- Define API error/response contract before first business endpoint.
- Introduce CI gates for `rails test`, `rubocop`, and `brakeman`.
- Document local setup in `marketplace_backend/README.md`.
- Decide whether to keep or remove unused scaffolded integration gems until needed.
