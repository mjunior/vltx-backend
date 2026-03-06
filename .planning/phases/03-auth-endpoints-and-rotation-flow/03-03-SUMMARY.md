---
phase: 03-auth-endpoints-and-rotation-flow
plan: 03
subsystem: auth
tags: [rails, refresh, rotation, one-time, replay-protection]
requires:
  - phase: 03-auth-endpoints-and-rotation-flow
    provides: login endpoint and unified auth contract
provides:
  - Endpoint `POST /auth/refresh` com validação estrita
  - Rotação transacional one-time do refresh token
  - Cobertura de rejeição para token reutilizado
affects: [phase-4-logout-global, security-hardening, client-session-flow]
tech-stack:
  added: []
  patterns: [one-time-refresh, session-row-lock-rotation]
key-files:
  created:
    - marketplace_backend/app/controllers/auth/refreshes_controller.rb
    - marketplace_backend/app/services/auth/sessions/rotate_session.rb
    - marketplace_backend/test/integration/auth_refresh_test.rb
    - marketplace_backend/test/services/auth/sessions/rotation_test.rb
  modified: []
key-decisions:
  - "Refresh aceita somente body JSON com refresh_token"
  - "Token refresh anterior torna-se inválido após rotação bem-sucedida"
patterns-established:
  - "Rotação com with_lock para impedir aceitação duplicada"
  - "Erro público de refresh inválido sempre 401 token invalido"
requirements-completed: [SESS-02, SESS-03]
duration: 30min
completed: 2026-03-06
---

# Phase 3: Auth Endpoints and Rotation Flow Summary

**Refresh endpoint agora rota tokens de forma one-time e rejeita reutilização do token anterior com resposta pública consistente.**

## Performance

- **Duration:** 30 min
- **Started:** 2026-03-06T02:40:00Z
- **Completed:** 2026-03-06T03:10:00Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments
- Added `POST /auth/refresh` with strict payload/content-type checks.
- Implemented transaction-safe session rotation using row lock.
- Added integration and service tests for one-time-use behavior.

## Task Commits

Each task was committed atomically:

1. **Task 1-3: refresh endpoint + rotation service + tests** - `5e0057d` (feat)

## Files Created/Modified
- `marketplace_backend/app/controllers/auth/refreshes_controller.rb` - refresh contract and error policy.
- `marketplace_backend/app/services/auth/sessions/rotate_session.rb` - lock-based rotation logic.
- `marketplace_backend/test/integration/auth_refresh_test.rb` - request-level refresh behavior coverage.
- `marketplace_backend/test/services/auth/sessions/rotation_test.rb` - one-time use guarantees.

## Decisions Made
- Non-JSON refresh requests are rejected as invalid payload.
- Reusing an already rotated refresh token returns `401 token invalido`.

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
- Refresh endpoint initially flagged `format`/`refresh` framework params as unknown; fixed by allowlisting those framework keys in payload filter.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Core refresh rotation behavior is complete.
- Phase 4 can focus on explicit logout endpoint and incident policy wiring.

---
*Phase: 03-auth-endpoints-and-rotation-flow*
*Completed: 2026-03-06*
