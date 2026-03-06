---
phase: 04-logout-global-and-reuse-incident-handling
plan: 02
subsystem: auth
tags: [rails, refresh, reuse-incident, global-revoke]
requires:
  - phase: 04-logout-global-and-reuse-incident-handling
    provides: global logout endpoint and revocation baseline
provides:
  - Reuse incidente com revogação global imediata
  - Bloqueio de refresh subsequente até novo login
  - Testes end-to-end de incidente
affects: [security-hardening, phase-5-verification]
tech-stack:
  added: []
  patterns: [signed-token-missing-jti-incident, fail-closed-refresh]
key-files:
  created:
    - marketplace_backend/test/integration/auth_reuse_incident_test.rb
  modified:
    - marketplace_backend/app/services/auth/sessions/detect_reuse.rb
    - marketplace_backend/app/services/auth/sessions/rotate_session.rb
    - marketplace_backend/test/services/auth/sessions/revocation_test.rb
key-decisions:
  - "Refresh token assinado com jti ausente na sessão ativa é tratado como incidente"
  - "Incidente derruba todas as refresh sessions e exige novo login"
patterns-established:
  - "DetectReuse com fail-closed para jti inexistente"
  - "RotateSession consulta incident policy antes de aceitar rotação"
requirements-completed: [SESS-04]
duration: 20min
completed: 2026-03-06
---

# Phase 4: Logout Global and Reuse Incident Handling Summary

**Detecção de reuse foi endurecida para revogar globalmente e bloquear qualquer refresh subsequente até reautenticação.**

## Performance

- **Duration:** 20 min
- **Started:** 2026-03-06T03:40:00Z
- **Completed:** 2026-03-06T04:00:00Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments
- Strengthened `DetectReuse` to treat signed unknown `jti` as incident.
- Updated `RotateSession` to enforce incident policy before rotation.
- Added end-to-end incident test proving global revoke + blocked subsequent refresh.

## Task Commits

Each task was committed atomically:

1. **Task 1-3: reuse incident hardening + tests** - `c3659bf` (feat)

## Files Created/Modified
- `marketplace_backend/app/services/auth/sessions/detect_reuse.rb` - incident policy for revoked/missing jti/hash mismatch.
- `marketplace_backend/app/services/auth/sessions/rotate_session.rb` - integrates incident detection before rotate.
- `marketplace_backend/test/integration/auth_reuse_incident_test.rb` - end-to-end incident behavior.
- `marketplace_backend/test/services/auth/sessions/revocation_test.rb` - service-level regressions.

## Decisions Made
- Unknown session for a signed refresh token is treated as probable replay incident.
- Public error remains `401 token invalido` with no state leakage.

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Incident handling is complete for v1 scope.
- Ready for phase 5 hardening and full security verification.

---
*Phase: 04-logout-global-and-reuse-incident-handling*
*Completed: 2026-03-06*
