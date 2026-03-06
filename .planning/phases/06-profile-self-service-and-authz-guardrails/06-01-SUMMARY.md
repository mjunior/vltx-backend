---
phase: 06-profile-self-service-and-authz-guardrails
plan: 01
subsystem: api
tags: [rails, profile, authz, uuid, patch]
requires:
  - phase: 05-security-hardening-and-verification
    provides: jwt auth/session base and generic token error contract
provides:
  - uuid-first identity baseline for users/profiles/refresh_sessions
  - authenticated PATCH /profile endpoint with owner derived from token
  - patch semantics for name/address with null clearing
affects: [profile, authz, v1.1]
tech-stack:
  added: []
  patterns: [token-derived ownership, fail-closed payload allowlist]
key-files:
  created:
    - marketplace_backend/app/controllers/profiles_controller.rb
    - marketplace_backend/app/services/profiles/update_profile.rb
    - marketplace_backend/app/serializers/profiles/profile_serializer.rb
    - marketplace_backend/test/integration/profile_update_test.rb
    - marketplace_backend/test/services/profiles/update_profile_test.rb
  modified:
    - marketplace_backend/db/migrate/20260305220000_create_users.rb
    - marketplace_backend/db/migrate/20260305220100_create_profiles.rb
    - marketplace_backend/db/migrate/20260305221600_create_refresh_sessions.rb
    - marketplace_backend/db/schema.rb
    - marketplace_backend/app/controllers/application_controller.rb
    - marketplace_backend/config/routes.rb
key-decisions:
  - "Global IDs in v1.1 use UUID; reset of local DB accepted."
  - "Profile ownership is always resolved from access token, never from payload fields."
patterns-established:
  - "PATCH semantics: omitted fields unchanged, null explicitly clears field."
requirements-completed:
  - PROF-03
  - AUTHZ-01
  - AUTHZ-04
duration: 8 min
completed: 2026-03-06
---

# Phase 6 Plan 01: Profile Self-Service and AuthZ Guardrails Summary

**Profile self-update endpoint shipped with UUID baseline and strict tenant-safe payload contract.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-03-06T03:49:00Z
- **Completed:** 2026-03-06T03:57:10Z
- **Tasks:** 3
- **Files modified:** 13

## Accomplishments
- Migrated identity-related tables to UUID-first (`users`, `profiles`, `refresh_sessions`) with `pgcrypto` enabled.
- Added authenticated `PATCH /profile` that uses user from JWT and rejects unknown payload keys.
- Locked profile update behavior via integration and service tests for success/auth/token/payload scenarios.

## Task Commits

Each task was committed atomically:

1. **Task 1: Aplicar baseline UUID-first no dominio para a milestone v1.1** - `6a3e801` (feat)
2. **Task 2: Implementar PATCH /profile com usuario derivado do token** - `2edb793` (feat)
3. **Task 3: Criar cobertura inicial de integracao e servico para authz de perfil** - `5f707de` (test)

**Plan metadata:** `a32a735` (docs)

## Files Created/Modified
- `marketplace_backend/app/controllers/profiles_controller.rb` - authenticated profile update endpoint.
- `marketplace_backend/app/services/profiles/update_profile.rb` - allowlisted update rules and PATCH semantics.
- `marketplace_backend/app/serializers/profiles/profile_serializer.rb` - safe profile response (`id`, `name`, `address`).
- `marketplace_backend/test/integration/profile_update_test.rb` - request-level auth and payload contract coverage.
- `marketplace_backend/test/services/profiles/update_profile_test.rb` - service invariants for allowed keys and null handling.

## Decisions Made
- Keep generic unauthorized contract (`token invalido`) for invalid or missing bearer tokens.
- Fail closed on unknown payload keys (`payload invalido`) to block owner forging attempts.

## Deviations from Plan

None - plan executed as specified.

## Issues Encountered
- Initial controller guard used full params hash and rejected valid JSON due Rails wrapped params; fixed by validating only `request.request_parameters`.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Base profile endpoint and authz guards are stable for additional hardening.
- Ready for wave 2 verification and final phase closeout.

---
*Phase: 06-profile-self-service-and-authz-guardrails*
*Completed: 2026-03-06*
