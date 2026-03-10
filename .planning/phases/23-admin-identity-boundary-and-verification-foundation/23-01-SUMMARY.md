---
phase: 23-admin-identity-boundary-and-verification-foundation
plan: 01
subsystem: admin-foundation
tags: [rails, admin, auth, users, schema]
requires: []
provides:
  - tabela `admins`
  - tabela `admin_refresh_sessions`
  - campo `users.verification_status`
affects: [auth, admin, users, schema]
tech-stack:
  added: []
  patterns: [separate-admin-identity, separate-session-store, verification-status-foundation]
key-files:
  created:
    - marketplace_backend/db/migrate/20260310040000_create_admins.rb
    - marketplace_backend/db/migrate/20260310040100_create_admin_refresh_sessions.rb
    - marketplace_backend/db/migrate/20260310040200_add_verification_status_to_users.rb
    - marketplace_backend/app/models/admin.rb
    - marketplace_backend/app/models/admin_refresh_session.rb
  modified:
    - marketplace_backend/app/models/user.rb
    - marketplace_backend/db/schema.rb
    - marketplace_backend/test/models/user_test.rb
    - marketplace_backend/test/test_helper.rb
key-decisions:
  - "Admin foi modelado como entidade separada de User."
  - "Refresh sessions administrativas usam tabela dedicada."
  - "User passa a nascer com verification_status `unverified`."
patterns-established:
  - "Fundacoes de auth admin seguem a disciplina do auth atual sem compartilhar persistencia."
requirements-completed:
  - ADM-01
  - USR-01
duration: 20 min
completed: 2026-03-10
---

# Phase 23 Plan 01: Admin Foundation Summary

**A fundação de dados da superfície admin foi criada sem reaproveitar o domínio `User`.**

## Accomplishments
- Criadas as tabelas `admins` e `admin_refresh_sessions` com isolamento completo das sessões de usuário.
- `User` ganhou `verification_status` com enum `unverified`/`verified` e default seguro.
- Ambiente de teste passou a carregar secrets próprios de JWT admin.

## Verification
- `RBENV_VERSION=3.3.0 rbenv exec bundle exec rails db:migrate`
- `RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test test/models/admin_test.rb test/models/admin_refresh_session_test.rb test/models/user_test.rb`

## Next Phase Readiness
- Base de dados e configuração prontas para o namespace `/admin/auth`.

---
*Phase: 23-admin-identity-boundary-and-verification-foundation*
*Completed: 2026-03-10*
