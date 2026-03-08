---
phase: 15-wallet-ledger-data-model-and-invariants
plan: 01
subsystem: api
tags: [rails, wallet, ledger, database, integrity]
requires:
  - phase: 14-cart-finalization-and-order-service-preparation
    provides: padrões de service transacional e contratos de erro
provides:
  - tabelas `wallets` e `wallet_transactions`
  - invariantes de domínio em centavos
  - proteção append-only para ledger
affects: [wallet-foundation, ledger-integrity, milestone-v1.3]
tech-stack:
  added: []
  patterns: [constraints de banco + validação de model para invariantes financeiros]
key-files:
  created:
    - marketplace_backend/db/migrate/20260307230000_create_wallets.rb
    - marketplace_backend/db/migrate/20260307230100_create_wallet_transactions.rb
    - marketplace_backend/db/migrate/20260307230200_add_wallet_transactions_append_only_trigger.rb
    - marketplace_backend/app/models/wallet.rb
    - marketplace_backend/app/models/wallet_transaction.rb
    - marketplace_backend/test/models/wallet_test.rb
    - marketplace_backend/test/models/wallet_transaction_test.rb
  modified:
    - marketplace_backend/app/models/user.rb
    - marketplace_backend/db/schema.rb
key-decisions:
  - "Wallet usa saldo materializado em `current_balance_cents` com constraint não-negativa."
  - "Ledger restringe tipo para `credit/debit/refund` e valores sempre em centavos inteiros."
  - "Append-only é protegido por trigger no banco e guarda read-only no model."
patterns-established:
  - "Invariantes financeiros críticos protegidos em duas camadas: DB + ActiveRecord."
requirements-completed:
  - WAL-01
  - WAL-02
  - WAL-04
duration: 18 min
completed: 2026-03-07
---

# Phase 15 Plan 01: Wallet Ledger Foundation Summary

**Base de carteira e ledger append-only foi implementada com invariantes de centavos e proteção contra mutações destrutivas.**

## Performance

- **Duration:** 18 min
- **Tasks:** 3
- **Files modified:** 9

## Accomplishments
- Criadas migrations para `wallets` e `wallet_transactions` com constraints de tipo e valores monetários.
- Criado trigger de banco para bloquear `UPDATE`/`DELETE` no ledger.
- Criados models `Wallet`/`WalletTransaction` e testes de domínio cobrindo tipos permitidos, unicidade de `operation_key` por wallet e append-only.

## Task Commits

1. **Task 1-3: schema/models/constraints/tests** - `0dab28c` (feat)

## Files Created/Modified
- `marketplace_backend/db/migrate/20260307230000_create_wallets.rb`
- `marketplace_backend/db/migrate/20260307230100_create_wallet_transactions.rb`
- `marketplace_backend/db/migrate/20260307230200_add_wallet_transactions_append_only_trigger.rb`
- `marketplace_backend/app/models/wallet_transaction.rb`

## Deviations from Plan
- Append-only também foi reforçado no model (`ReadOnlyRecord`) para garantir comportamento consistente no ambiente de teste baseado em `schema.rb`.

## Issues Encountered
None no escopo do plano.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Estrutura de dados pronta para service transacional de append ledger no plano 15-02.

---
*Phase: 15-wallet-ledger-data-model-and-invariants*
*Completed: 2026-03-07*
