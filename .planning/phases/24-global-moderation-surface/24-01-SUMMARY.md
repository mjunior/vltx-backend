---
phase: 24-global-moderation-surface
plan: 01
subsystem: admin-user-moderation
tags: [rails, admin, users, auth, moderation]
requires:
  - phase: 23-admin-identity-boundary-and-verification-foundation
    provides: namespace `/admin` e `current_admin`
provides:
  - endpoint `/admin/users/:id/deactivate`
  - bloqueio operacional total de usuário
  - revogação imediata de refresh sessions
affects: [admin, auth, users]
tech-stack:
  added: []
  patterns: [global-user-deactivation, session-revocation-on-moderation, inactive-user-login-block]
key-files:
  created:
    - marketplace_backend/app/services/admin_users/deactivate.rb
    - marketplace_backend/test/integration/admin_users_deactivate_test.rb
  modified:
    - marketplace_backend/app/controllers/admin/users_controller.rb
    - marketplace_backend/app/controllers/auth/logins_controller.rb
    - marketplace_backend/app/services/auth/jwt/access_subject.rb
    - marketplace_backend/app/services/auth/sessions/find_active_session.rb
    - marketplace_backend/app/services/auth/sessions/rotate_session.rb
    - marketplace_backend/app/models/user.rb
key-decisions:
  - "Desativação de usuário passa a bloquear acesso imediatamente."
  - "Login de usuário desativado continua retornando erro genérico."
  - "Refresh sessions são revogadas no momento da moderação."
requirements-completed:
  - ADM-04
completed: 2026-03-10
---

# Phase 24 Plan 01: Admin User Moderation Summary

**A moderação global de usuário foi entregue com bloqueio total imediato.**

## Accomplishments
- Criado `PATCH /admin/users/:id/deactivate`.
- Usuário desativado perde acesso imediatamente via `access_token` e não consegue mais fazer login.
- `refresh_sessions` do usuário são revogadas no momento da desativação.

## Verification
- `RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test test/integration/admin_users_deactivate_test.rb test/integration/auth_login_test.rb`

---
*Phase: 24-global-moderation-surface*
*Completed: 2026-03-10*
