---
phase: 03-auth-endpoints-and-rotation-flow
plan: 02
subsystem: auth
tags: [rails, login, credentials, anti-enumeration]
requires:
  - phase: 03-auth-endpoints-and-rotation-flow
    provides: signup auth serializer and refresh session creation service
provides:
  - Endpoint `POST /auth/login`
  - Erro público genérico para credenciais inválidas
  - Emissão de token pair no login
affects: [refresh-flow, auth-routes, client-auth-contract]
tech-stack:
  added: []
  patterns: [generic-credential-errors, unified-auth-contract]
key-files:
  created:
    - marketplace_backend/app/controllers/auth/logins_controller.rb
    - marketplace_backend/test/integration/auth_login_test.rb
  modified:
    - marketplace_backend/app/controllers/application_controller.rb
    - marketplace_backend/config/routes.rb
    - marketplace_backend/test/integration/healthcheck_test.rb
key-decisions:
  - "Credenciais inválidas sempre retornam 401 com mensagem única"
  - "Login segue o mesmo contrato de sucesso do signup"
patterns-established:
  - "Render helpers em ApplicationController para erros de auth"
  - "Rotas de auth explícitas no namespace /auth"
requirements-completed: [AUTH-02, AUTH-03, AUTH-04]
duration: 25min
completed: 2026-03-06
---

# Phase 3: Auth Endpoints and Rotation Flow Summary

**Login por email/senha foi adicionado com resposta anti-enumeração e token pair no contrato unificado de auth.**

## Performance

- **Duration:** 25 min
- **Started:** 2026-03-06T02:15:00Z
- **Completed:** 2026-03-06T02:40:00Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments
- Added `POST /auth/login` with email/password authentication.
- Standardized invalid-credentials behavior (`401 credenciais invalidas`).
- Covered login success and failure paths with integration tests.

## Task Commits

Each task was committed atomically:

1. **Task 1-3: login endpoint + error policy + tests** - `25a7b39` (feat)

## Files Created/Modified
- `marketplace_backend/app/controllers/auth/logins_controller.rb` - login orchestration and token issuance.
- `marketplace_backend/app/controllers/application_controller.rb` - shared auth error renderers.
- `marketplace_backend/config/routes.rb` - adds auth login/refresh routes.
- `marketplace_backend/test/integration/auth_login_test.rb` - success and generic invalid credential coverage.
- `marketplace_backend/test/integration/healthcheck_test.rb` - route exposure assertions.

## Decisions Made
- Missing login payload fields return `422 payload invalido`.
- Unknown/incorrect credentials always return the same public error.

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Refresh endpoint can now rely on established auth response/error contract.

---
*Phase: 03-auth-endpoints-and-rotation-flow*
*Completed: 2026-03-06*
