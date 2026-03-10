---
phase: 23-admin-identity-boundary-and-verification-foundation
plan: 02
subsystem: admin-auth
tags: [rails, admin, auth, jwt, sessions]
requires:
  - phase: 23-admin-identity-boundary-and-verification-foundation
    provides: entidades e config base de admin
provides:
  - endpoints `/admin/auth/login`, `/admin/auth/refresh`, `/admin/auth/logout`
  - `current_admin` e `authenticate_admin!`
  - JWT admin com secrets dedicados
affects: [auth, admin, api]
tech-stack:
  added: []
  patterns: [parallel-auth-stack, current-admin-guard, admin-refresh-rotation]
key-files:
  created:
    - marketplace_backend/app/controllers/admin/application_controller.rb
    - marketplace_backend/app/controllers/admin/auth/logins_controller.rb
    - marketplace_backend/app/controllers/admin/auth/refreshes_controller.rb
    - marketplace_backend/app/controllers/admin/auth/logouts_controller.rb
    - marketplace_backend/app/services/admin_auth/jwt/config.rb
    - marketplace_backend/app/services/admin_auth/jwt/issuer.rb
    - marketplace_backend/app/services/admin_auth/jwt/verifier.rb
    - marketplace_backend/app/services/admin_auth/jwt/access_subject.rb
    - marketplace_backend/app/services/admin_auth/sessions/create_session.rb
    - marketplace_backend/app/services/admin_auth/sessions/rotate_session.rb
    - marketplace_backend/app/serializers/admin_auth/token_pair_serializer.rb
  modified:
    - marketplace_backend/config/routes.rb
key-decisions:
  - "JWT admin usa secrets e pepper dedicados."
  - "Guard HTTP admin usa `current_admin`, sem tocar em `current_user`."
  - "Fluxo admin replica access+refresh+logout do auth atual com storage separado."
patterns-established:
  - "Namespace `/admin` nasce com auth própria e contratos genéricos de erro."
requirements-completed:
  - ADM-01
  - ADM-02
duration: 35 min
completed: 2026-03-10
---

# Phase 23 Plan 02: Admin Auth Summary

**O namespace `/admin/auth` foi entregue com login, refresh e logout em stack de JWT totalmente separada.**

## Accomplishments
- Criado `Admin::ApplicationController` com `authenticate_admin!` e `current_admin`.
- Implementado JWT admin com rotação one-time de refresh e revogação global de sessões administrativas.
- Expostos os endpoints `POST /admin/auth/login`, `POST /admin/auth/refresh` e `POST /admin/auth/logout`.

## Verification
- `RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test test/integration/admin_auth_login_test.rb test/integration/admin_auth_refresh_test.rb test/integration/admin_auth_logout_test.rb`
- `RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test test/services/auth/jwt/issuer_test.rb test/services/auth/jwt/verifier_test.rb test/services/auth/sessions/rotation_test.rb`

## Next Phase Readiness
- O namespace admin pode crescer com endpoints funcionais sem refatorar auth.

---
*Phase: 23-admin-identity-boundary-and-verification-foundation*
*Completed: 2026-03-10*
