---
phase: 15-wallet-ledger-data-model-and-invariants
plan: 02
subsystem: api
tags: [rails, wallet, ledger, service, transactions]
requires:
  - phase: 15-wallet-ledger-data-model-and-invariants
    provides: schema e invariantes de base
provides:
  - service `Wallets::Ledger::AppendTransaction`
  - cálculo server-side de `balance_after_cents`
  - política fail-closed para divergência ledger/materializado
affects: [wallet-ledger-write-path, transaction-integrity, milestone-v1.3]
tech-stack:
  added: []
  patterns: [lock + transação atômica em fluxo financeiro crítico]
key-files:
  created:
    - marketplace_backend/app/services/wallets/ledger/append_transaction.rb
    - marketplace_backend/test/services/wallets/ledger/append_transaction_test.rb
  modified: []
key-decisions:
  - "`balance_after_cents` é sempre calculado no backend e nunca aceito de caller/frontend."
  - "Mismatch entre saldo materializado e ledger corrige saldo e falha a operação corrente."
  - "Reembolso/débito que levaria a saldo negativo é bloqueado."
patterns-established:
  - "Service financeiro fail-closed com lock pessimista e validação em centavos."
requirements-completed:
  - WAL-03
  - WAL-01
  - WAL-04
duration: 14 min
completed: 2026-03-07
---

# Phase 15 Plan 02: Atomic Ledger Append Summary

**Fluxo transacional de append ledger foi entregue com cálculo de saldo pós-transação no servidor e proteção fail-closed.**

## Performance

- **Duration:** 14 min
- **Tasks:** 3
- **Files modified:** 2

## Accomplishments
- Implementado `Wallets::Ledger::AppendTransaction` com lock de wallet e transação única.
- Cálculo de `balance_after_cents` e sincronização de `wallet.current_balance_cents` no mesmo fluxo atômico.
- Cobertos cenários de crédito/débito/reembolso, duplicidade de `operation_key`, mismatch ledger/materializado e validações de centavos.

## Task Commits

1. **Task 1-3: service append + testes transacionais** - `fb96333` (feat)

## Files Created/Modified
- `marketplace_backend/app/services/wallets/ledger/append_transaction.rb`
- `marketplace_backend/test/services/wallets/ledger/append_transaction_test.rb`

## Deviations from Plan
None.

## Issues Encountered
None no escopo do plano.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Base pronta para evolução de lock/idempotência avançada na fase 16/17 com mesmas garantias de integridade.

---
*Phase: 15-wallet-ledger-data-model-and-invariants*
*Completed: 2026-03-07*
