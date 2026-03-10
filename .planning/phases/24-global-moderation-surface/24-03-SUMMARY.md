---
phase: 24-global-moderation-surface
plan: 03
subsystem: admin-orders-read
tags: [rails, admin, orders, moderation, backoffice]
requires:
  - phase: 24-global-moderation-surface
    provides: namespace admin funcional para moderação
provides:
  - endpoints `/admin/orders` e `/admin/orders/:id`
  - leitura global sem tenant scope
  - actor_role `admin` no serializer de pedido
affects: [admin, orders, api]
tech-stack:
  added: []
  patterns: [admin-global-order-read, serializer-reuse-with-admin-viewer, scope-safe-backoffice-read]
key-files:
  created:
    - marketplace_backend/app/controllers/admin/orders_controller.rb
    - marketplace_backend/test/integration/admin_orders_index_test.rb
  modified:
    - marketplace_backend/app/serializers/orders/order_serializer.rb
    - marketplace_backend/test/integration/admin_authorization_boundary_test.rb
    - marketplace_backend/config/routes.rb
key-decisions:
  - "Leitura global de pedidos entra sem filtros nesta fase."
  - "Serializer de pedido reaproveita o contrato atual, mas com actor_role `admin` e ações todas false."
  - "User token continua sem acesso a `/admin/orders`."
requirements-completed:
  - ADM-06
completed: 2026-03-10
---

# Phase 24 Plan 03: Admin Global Orders Summary

**O painel admin ganhou leitura global de pedidos sem romper o isolamento buyer/seller.**

## Accomplishments
- Criados `GET /admin/orders` e `GET /admin/orders/:id`.
- O serializer de pedido agora suporta `actor_role: "admin"` com `available_actions` zerado.
- A leitura global ficou restrita ao guard admin-only, sem afetar `OrdersController` já existente.

## Verification
- `RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test test/integration/admin_orders_index_test.rb test/integration/orders_actions_test.rb test/integration/admin_authorization_boundary_test.rb`

---
*Phase: 24-global-moderation-surface*
*Completed: 2026-03-10*
