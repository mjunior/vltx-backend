---
phase: 14-cart-finalization-and-order-service-preparation
plan: 01
subsystem: api
tags: [rails, checkout, cart, wallet, authz]
requires:
  - phase: 13-cart-state-guards-and-abuse-prevention
    provides: guardas de estado e segurança de mutações de carrinho
provides:
  - endpoint `POST /cart/checkout` autenticado
  - transição de carrinho `active -> finished` com validações
  - contrato de pagamento exclusivo por `wallet`
affects: [orders-preparation, checkout-contract, milestone-v1.2]
tech-stack:
  added: []
  patterns: [controller fino + service de domínio para checkout]
key-files:
  created:
    - marketplace_backend/app/controllers/cart_checkout_controller.rb
    - marketplace_backend/app/services/carts/finalize.rb
    - marketplace_backend/test/services/carts/finalize_test.rb
    - marketplace_backend/test/integration/cart_checkout_test.rb
  modified:
    - marketplace_backend/config/routes.rb
    - marketplace_backend/test/integration/healthcheck_test.rb
key-decisions:
  - "Checkout exige payload `checkout.payment_method` e aceita apenas `wallet`."
  - "Sem carrinho ativo retorna `404 nao encontrado`; carrinho inválido/vazio retorna `422 payload invalido`."
patterns-established:
  - "Finalização de carrinho ocorre via service transacional, nunca no controller."
requirements-completed:
  - CHK-01
  - CHK-02
duration: 20 min
completed: 2026-03-07
---

# Phase 14 Plan 01: Cart Checkout Finalization Summary

**Checkout autenticado foi entregue com finalização segura do carrinho ativo e regra de pagamento exclusiva por carteira.**

## Performance

- **Duration:** 20 min
- **Started:** 2026-03-07T20:46:00Z
- **Completed:** 2026-03-07T21:06:00Z
- **Tasks:** 3
- **Files modified:** 8

## Accomplishments
- Criado endpoint `POST /cart/checkout` com validação de payload e strong parameters.
- Implementado `Carts::Finalize` para transição atômica `active -> finished` com validação de carrinho vazio e método de pagamento.
- Cobertura de integração e serviço para sucesso e cenários negativos (`wallet` only, sem carrinho ativo, carrinho vazio).

## Task Commits

1. **Task 1-3: checkout endpoint + finalização + testes** - `e67012c` (feat)

## Files Created/Modified
- `marketplace_backend/app/controllers/cart_checkout_controller.rb` - endpoint de checkout e mapeamento de erro.
- `marketplace_backend/app/services/carts/finalize.rb` - regras de finalização do carrinho ativo.
- `marketplace_backend/test/integration/cart_checkout_test.rb` - contrato HTTP de checkout.

## Decisions Made
- Finalização mantém semântica de erro genérica e não expõe estado interno do carrinho.

## Deviations from Plan
None.

## Issues Encountered
None no escopo do plano.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Fluxo de checkout pronto para integrar service explícito de preparação de pedido.

---
*Phase: 14-cart-finalization-and-order-service-preparation*
*Completed: 2026-03-07*
