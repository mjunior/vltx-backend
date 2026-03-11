---
phase: 27-contestation-resolution-workflow
plan: 02
subsystem: admin-contest-resolution
tags: [rails, admin, orders, refunds, ledger]
requires:
  - phase: 20-order-linked-ledger-and-wallet-provisioning
    provides: ledger append-only e reversões seguras
provides:
  - endpoints `/admin/orders/:id/approve` e `/admin/orders/:id/deny`
  - approve admin com refund buyer-side e reversal seller-side
  - deny admin devolvendo pedido para `delivered`
affects: [admin, orders, wallet, ledger]
tech-stack:
  added: []
  patterns: [admin-contest-approve, admin-contest-deny, system-transition-audit]
key-files:
  created:
    - marketplace_backend/app/services/admin_orders/approve_contestation.rb
    - marketplace_backend/app/services/admin_orders/deny_contestation.rb
    - marketplace_backend/test/integration/admin_order_contest_resolution_test.rb
  modified:
    - marketplace_backend/app/controllers/admin/orders_controller.rb
    - marketplace_backend/config/routes.rb
key-decisions:
  - "A autoridade final da contestação passa a ser o admin, não o seller."
  - "Approve mantém o erro atual de `saldo insuficiente`."
  - "Deny registra transição administrativa e recoloca o pedido em `delivered`."
requirements-completed:
  - ADM-10
completed: 2026-03-11
---

# Phase 27 Plan 02: Admin Contestation Resolution Summary

**A decisão administrativa de contestação foi entregue com approve e deny explícitos.**

## Accomplishments
- Criados `POST /admin/orders/:id/approve` e `POST /admin/orders/:id/deny`.
- O approve admin gera refund buyer-side e reversal seller-side de forma segura e idempotente.
- O deny admin remove o pedido de `contested` e devolve o estado para `delivered`, sem mutação financeira.

## Verification
- `RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test test/integration/admin_order_contest_resolution_test.rb test/integration/admin_authorization_boundary_test.rb`

---
*Phase: 27-contestation-resolution-workflow*
*Completed: 2026-03-11*
