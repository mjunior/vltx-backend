---
phase: 16-transaction-safety-and-non-negative-balance-enforcement
plan: 01
subsystem: api
tags: [rails, wallet, ledger, safety, antifraud]
requires:
  - phase: 15-wallet-ledger-data-model-and-invariants
    provides: base append-only de wallet e invariantes de centavos
provides:
  - service `Wallets::Operations::ApplyMovement`
  - validação de trusted amount + bloqueio de untrusted critical input
  - mapeamento determinístico de erros de segurança financeira
affects: [wallet-write-path, transaction-safety, milestone-v1.3]
tech-stack:
  added: []
  patterns: [service-orchestrator delegando escrita para ledger append-only]
key-files:
  created:
    - marketplace_backend/app/services/wallets/operations/apply_movement.rb
    - marketplace_backend/test/services/wallets/operations/apply_movement_test.rb
  modified: []
key-decisions:
  - "Movimentações críticas só aceitam `trusted_amount_cents` e rejeitam amount não confiável."
  - "Erros de segurança do ledger (`insufficient_funds`, `balance_mismatch`, `duplicate_operation`) propagam internamente sem quebrar contrato externo."
patterns-established:
  - "Camada de operação separa validação de origem confiável da persistência append-only no ledger."
requirements-completed:
  - WAL-06
  - WAL-07
  - WAL-08
duration: 14 min
completed: 2026-03-08
---

# Phase 16 Plan 01: Wallet Movement Safety Summary

**Camada de movimentação segura da wallet foi criada com validação anti-fraude e comportamento determinístico em erros de saldo/consistência.**

## Performance

- **Duration:** 14 min
- **Tasks:** 3
- **Files modified:** 2

## Accomplishments
- Criado `Wallets::Operations::ApplyMovement` para crédito/débito/reembolso com input confiável.
- Bloqueado caminho com valor crítico não confiável (`untrusted_amount_cents`) para cumprir WAL-08.
- Cobertos cenários de saldo insuficiente, duplicidade de operação e mismatch ledger/materializado.

## Task Commits

1. **Task 1-3: apply movement + testes de segurança** - `18873e9` (feat)

## Files Created/Modified
- `marketplace_backend/app/services/wallets/operations/apply_movement.rb`
- `marketplace_backend/test/services/wallets/operations/apply_movement_test.rb`

## Deviations from Plan
None.

## Issues Encountered
None no escopo do plano.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Serviço pronto para integração com boundary de checkout na sequência da fase.

---
*Phase: 16-transaction-safety-and-non-negative-balance-enforcement*
*Completed: 2026-03-08*
