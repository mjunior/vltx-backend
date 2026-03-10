---
phase: 21-secure-order-workflow-and-cancellation-refunds
plan: 01
subsystem: order-workflow
tags: [rails, orders, workflow, audit, transitions]
requires:
  - phase: 20-order-linked-ledger-and-wallet-provisioning
    provides: pedidos persistidos, checkout group e recebiveis seller
provides:
  - tabela `order_transitions`
  - camada unica de transicao de pedido
  - bloqueio de mudanca direta de `orders.status`
affects: [orders, checkout, seller-finance, refunds]
tech-stack:
  added: []
  patterns: [explicit transition log, materialized current status, actor-scoped transition service]
key-files:
  created:
    - marketplace_backend/db/migrate/20260310001000_create_order_transitions.rb
    - marketplace_backend/app/models/order_transition.rb
    - marketplace_backend/app/services/orders/transition_recorder.rb
    - marketplace_backend/app/services/orders/apply_transition.rb
    - marketplace_backend/test/models/order_transition_test.rb
    - marketplace_backend/test/services/orders/apply_transition_test.rb
  modified:
    - marketplace_backend/app/models/order.rb
    - marketplace_backend/app/models/user.rb
    - marketplace_backend/app/services/orders/create_from_cart.rb
    - marketplace_backend/db/schema.rb
    - marketplace_backend/test/models/order_test.rb
key-decisions:
  - "Implementada camada propria de workflow auditavel em vez de adicionar gem externa nesta fase."
  - "`orders.status` continua materializado para query simples, mas so muda via workflow interno."
  - "Checkout passou a registrar transicao inicial `paid` no momento da criacao do pedido."
patterns-established:
  - "Historico de status separado da coluna atual do pedido."
requirements-completed:
  - ORD-03
  - ORD-07
duration: 52 min
completed: 2026-03-10
---

# Phase 21 Plan 01: Workflow Substrate Summary

**O pedido deixou de depender de escrita livre em `status` e passou a ter uma trilha auditavel de transicoes com boundary unica por ator.**

## Performance

- **Duration:** 52 min
- **Tasks:** 3
- **Files modified:** 10

## Accomplishments
- Criada a tabela `order_transitions` com backfill para pedidos existentes.
- `Orders::ApplyTransition` virou o ponto unico para avancar workflow com regras por ator.
- `Order` agora rejeita mudanca direta de `status` fora da sincronizacao interna de workflow.

## Task Commits

1. **Task 1-3: workflow substrate + transition recorder + status guard** - pending commit

## Decisions Made
- Nao foi adicionada gem de workflow nesta iteracao; a camada propria cobriu o mesmo requisito de auditoria e reduziu risco de integracao desnecessaria.

## Deviations from Plan
- O plano sugeria `Statesman` como preferencia. A execucao optou por uma implementacao interna mais enxuta, mantendo tabela auditavel e service boundary equivalentes.

## Next Phase Readiness
- Base pronta para acoplar cancelamento, refund, restore de estoque e liberacao de credito seller.

---
*Phase: 21-secure-order-workflow-and-cancellation-refunds*
*Completed: 2026-03-10*
