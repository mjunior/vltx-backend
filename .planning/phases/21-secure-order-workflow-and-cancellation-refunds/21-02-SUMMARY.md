---
phase: 21-secure-order-workflow-and-cancellation-refunds
plan: 02
subsystem: order-actions
tags: [rails, orders, refunds, inventory, seller-credit]
requires:
  - phase: 21-secure-order-workflow-and-cancellation-refunds
    provides: transicoes auditaveis e boundary unica de workflow
provides:
  - acoes `advance`, `cancel`, `deliver`
  - refund idempotente buyer-side
  - restauracao de estoque e credito seller-side
affects: [orders, inventory, wallet, seller-finance, api]
tech-stack:
  added: []
  patterns: [intent-based endpoints, transactional side effects, one-shot refund and seller credit]
key-files:
  created:
    - marketplace_backend/app/controllers/orders_controller.rb
    - marketplace_backend/app/services/orders/advance.rb
    - marketplace_backend/app/services/orders/cancel.rb
    - marketplace_backend/app/services/orders/mark_delivered.rb
    - marketplace_backend/app/serializers/orders/order_serializer.rb
    - marketplace_backend/app/serializers/orders/order_item_serializer.rb
    - marketplace_backend/app/serializers/orders/order_transition_serializer.rb
    - marketplace_backend/test/services/orders/cancel_test.rb
    - marketplace_backend/test/services/orders/mark_delivered_test.rb
    - marketplace_backend/test/integration/orders_actions_test.rb
  modified:
    - marketplace_backend/config/routes.rb
    - marketplace_backend/app/services/wallets/ledger/append_transaction.rb
    - marketplace_backend/test/services/wallets/ledger/append_transaction_test.rb
    - marketplace_backend/test/integration/healthcheck_test.rb
key-decisions:
  - "Refund passou a ser tratado como delta positivo na wallet do comprador."
  - "API de pedidos aceita apenas acoes explicitas; nenhum endpoint aceita `status` cru."
  - "Credito seller e aplicado apenas em `delivered`, alinhado ao recebivel `credited`."
patterns-established:
  - "Endpoint por intencao em vez de update generico de recurso."
requirements-completed:
  - INV-02
  - ORD-04
  - ORD-05
  - PAY-04
duration: 58 min
completed: 2026-03-10
---

# Phase 21 Plan 02: Order Actions Summary

**A API de pedidos ganhou acoes seguras com side effects transacionais: seller avanca, buyer cancela com refund/estoque, buyer entrega com credito seller.**

## Performance

- **Duration:** 58 min
- **Tasks:** 3
- **Files modified:** 14

## Accomplishments
- Criados endpoints `GET /orders`, `GET /orders/:id`, `POST /orders/:id/advance`, `cancel` e `deliver`.
- Cancelamento agora restaura estoque, reverte recebivel seller e credita refund idempotente ao buyer.
- Entrega marcada pelo buyer libera `credit` real na wallet do vendedor e muda o recebivel para `credited`.

## Task Commits

1. **Task 1-3: actor-safe actions + order HTTP surface + financial side effects** - pending commit

## Deviations from Plan
- Nenhuma na regra de produto; o ajuste principal foi corrigir a semantica do ledger para que `refund` some saldo em vez de subtrair.

## Next Phase Readiness
- Surface de pedidos pronta para endurecimento final de retries, guards negativos e regressao ampla.

---
*Phase: 21-secure-order-workflow-and-cancellation-refunds*
*Completed: 2026-03-10*
