---
phase: 17-idempotency-and-refund-deduplication
plan: 01
subsystem: api
tags: [rails, wallet, ledger, idempotency, refund]
requires:
  - phase: 16-transaction-safety-and-non-negative-balance-enforcement
    provides: engine de movimentacao com lock e invariantes de saldo
provides:
  - idempotencia deterministica por `wallet_id + operation_key`
  - conflito de idempotencia para payload divergente com mesma chave
  - deduplicacao de refund por referencia de negocio no banco
affects: [wallet-write-path, checkout-wallet-safety, milestone-v1.3]
tech-stack:
  added: []
  patterns: [idempotent read-before-write sob lock + fallback por unique constraint]
key-files:
  created:
    - marketplace_backend/db/migrate/20260308010000_add_wallet_refund_dedup_unique_index.rb
  modified:
    - marketplace_backend/app/services/wallets/ledger/append_transaction.rb
    - marketplace_backend/test/services/wallets/ledger/append_transaction_test.rb
    - marketplace_backend/test/services/wallets/operations/apply_movement_test.rb
key-decisions:
  - "Retry com mesma operation_key e payload equivalente retorna sucesso com transacao existente."
  - "Mesma operation_key com payload divergente retorna `idempotency_conflict`."
  - "Refund duplicado para mesma referencia e deduplicado por indice parcial unico + retorno idempotente."
patterns-established:
  - "Idempotencia financeira validada no service sob lock com banco como garantia final de corrida."
requirements-completed:
  - WAL-05
  - IDEMP-01
duration: 21 min
completed: 2026-03-08
---

# Phase 17 Plan 01: Idempotency Base and Refund Dedup Summary

**Base de idempotencia forte do ledger foi implementada com deduplicacao de refund por referencia e conflito deterministico para payload divergente.**

## Performance

- **Duration:** 21 min
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments
- `Wallets::Ledger::AppendTransaction` agora retorna sucesso idempotente para repeticao equivalente de `operation_key`.
- Conflito de payload com mesma chave passa a retornar `:idempotency_conflict` sem side effects adicionais.
- Migration adiciona indice unico parcial para refund por `wallet + reference_type + reference_id`.
- Testes de service cobrem retry idempotente, conflito deterministico e dedup de refund por referencia.

## Task Commits

1. **Task 1-3: idempotency + refund dedup + service tests** - `20e0c2b` (feat)

## Files Created/Modified
- `marketplace_backend/db/migrate/20260308010000_add_wallet_refund_dedup_unique_index.rb`
- `marketplace_backend/app/services/wallets/ledger/append_transaction.rb`
- `marketplace_backend/test/services/wallets/ledger/append_transaction_test.rb`
- `marketplace_backend/test/services/wallets/operations/apply_movement_test.rb`

## Deviations from Plan
- Deduplicacao por referencia de refund ignora `operation_key` e `metadata` para permitir retorno idempotente consistente em corridas com chaves diferentes para a mesma referencia.

## Issues Encountered
- Nenhum bloqueio de implementacao; apenas ajuste no matcher de idempotencia para acomodar dedup de refund concorrente.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Base pronta para prova de concorrencia/race e regressao integrada no plano 02.

---
*Phase: 17-idempotency-and-refund-deduplication*
*Completed: 2026-03-08*
