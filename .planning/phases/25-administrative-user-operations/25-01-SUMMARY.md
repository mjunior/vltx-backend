---
phase: 25-administrative-user-operations
plan: 01
subsystem: admin-user-update
tags: [rails, admin, users, profile, backoffice]
requires:
  - phase: 24-global-moderation-surface
    provides: leitura admin de usuários e ação de desativação
provides:
  - endpoint `PATCH /admin/users/:id`
  - payload admin canônico com perfil e saldo atual
  - reativação controlada de usuário inativo
affects: [admin, users, profiles]
tech-stack:
  added: []
  patterns: [admin-controlled-user-update, inactive-user-reactivation-gate, shared-admin-user-serializer]
key-files:
  created:
    - marketplace_backend/app/services/admin_users/update.rb
    - marketplace_backend/test/integration/admin_users_update_test.rb
  modified:
    - marketplace_backend/app/controllers/admin/users_controller.rb
    - marketplace_backend/app/serializers/admin/users/user_serializer.rb
    - marketplace_backend/config/routes.rb
key-decisions:
  - "Usuário inativo só pode ser reativado por patch admin."
  - "Desativação por `active: false` delega para o fluxo de moderação já existente."
  - "O serializer admin de usuário passa a incluir perfil e saldo atual."
requirements-completed:
  - ADM-07
completed: 2026-03-10
---

# Phase 25 Plan 01: Admin User Update Summary

**A edição administrativa de usuários foi entregue com guardrails para status e perfil.**

## Accomplishments
- Criado `PATCH /admin/users/:id`.
- Admin agora consegue atualizar email, `verification_status`, nome, endereço e `photo_url`.
- Usuário inativo só aceita reativação e o payload admin passou a incluir perfil e saldo atual.

## Verification
- `RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test test/integration/admin_users_update_test.rb test/integration/admin_authorization_boundary_test.rb`

---
*Phase: 25-administrative-user-operations*
*Completed: 2026-03-10*
