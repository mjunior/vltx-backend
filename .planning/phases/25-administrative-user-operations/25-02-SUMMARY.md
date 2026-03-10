---
phase: 25-administrative-user-operations
plan: 02
subsystem: admin-balance-adjustments
tags: [rails, admin, wallet, ledger, finance]
requires:
  - phase: 20-order-linked-ledger-and-wallet-provisioning
    provides: ledger append-only e wallet provisionada
provides:
  - endpoint `/admin/users/:id/balance-adjustments`
  - crédito e débito administrativos auditáveis
  - retorno do saldo atualizado com a transação criada
affects: [admin, wallet, ledger]
tech-stack:
  added: []
  patterns: [admin-ledger-adjustment, append-only-financial-update, metadata-audit-reason]
key-files:
  created:
    - marketplace_backend/app/controllers/admin/user_balance_adjustments_controller.rb
    - marketplace_backend/app/services/admin_users/apply_balance_adjustment.rb
    - marketplace_backend/app/serializers/admin/wallets/transaction_serializer.rb
    - marketplace_backend/test/integration/admin_user_balance_adjustments_test.rb
  modified:
    - marketplace_backend/config/routes.rb
key-decisions:
  - "Saldo admin nunca é alterado por overwrite; tudo passa pelo ledger."
  - "`reason` é obrigatório e vai para o metadata da transação."
  - "A resposta do ajuste usa serializer admin próprio para não expandir o contrato do `/wallet`."
requirements-completed:
  - ADM-07
completed: 2026-03-10
---

# Phase 25 Plan 02: Admin Balance Adjustments Summary

**O painel admin agora consegue aplicar crédito e débito sem violar as invariantes financeiras.**

## Accomplishments
- Criado `POST /admin/users/:id/balance-adjustments`.
- Ajustes administrativos usam o ledger append-only com `credit` e `debit`.
- A resposta devolve `current_balance_cents` atualizado e a transação criada com metadata auditável.

## Verification
- `RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test test/integration/admin_user_balance_adjustments_test.rb test/integration/wallet_authorization_test.rb`

---
*Phase: 25-administrative-user-operations*
*Completed: 2026-03-10*
