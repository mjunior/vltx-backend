---
phase: 22-seller-finance-surface-contestation-and-ratings
plan: 02
subsystem: contestation
tags: [rails, orders, contestation, workflow, authz]
requires:
  - phase: 21-secure-order-workflow-and-cancellation-refunds
    provides: workflow auditavel e acoes seguras de pedido
provides:
  - acao `contest`
  - endpoint `POST /orders/:id/contest`
  - cobertura de no-financial-reversal
affects: [orders, workflow, api, seller-finance]
tech-stack:
  added: []
  patterns: [intent-based endpoint, buyer-only transition, no automatic clawback]
key-files:
  created:
    - marketplace_backend/app/services/orders/contest.rb
    - marketplace_backend/test/services/orders/contest_test.rb
    - marketplace_backend/test/integration/orders_contest_test.rb
  modified:
    - marketplace_backend/app/controllers/orders_controller.rb
    - marketplace_backend/app/services/orders/apply_transition.rb
    - marketplace_backend/config/routes.rb
key-decisions:
  - "Contestation reutiliza o mesmo boundary auditavel de transicao do pedido."
  - "A fase nao faz refund automatico nem reverte credito seller ao contestar."
  - "A transicao elegivel ficou `delivered -> contested`, restrita ao buyer."
patterns-established:
  - "Fluxo pos-entrega continua seguro sem reabrir ledger reversals automaticos."
requirements-completed:
  - ORD-06
duration: 24 min
completed: 2026-03-10
---

# Phase 22 Plan 02: Contestation Summary

**O buyer agora consegue contestar um pedido entregue sem reabrir automaticamente o fluxo financeiro.**

## Performance

- **Duration:** 24 min
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- Criada a acao `Orders::Contest` sobre a mesma camada de workflow auditavel das demais transicoes.
- Exposto `POST /orders/:id/contest` com as mesmas guardas de ator e payload das outras acoes.
- Coberto que contestacao nao mexe em refund buyer nem em saldo creditado do seller nesta fase.

## Task Commits

1. **Task 1-2: contest service + secure endpoint + side-effect guard tests** - pending commit

## Verification

- `RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test test/services/orders/contest_test.rb test/integration/orders_contest_test.rb`

## Next Phase Readiness

- Workflow pronto para coexistir com avaliacoes pos-entrega e futura mediacao manual.

---
*Phase: 22-seller-finance-surface-contestation-and-ratings*
*Completed: 2026-03-10*
