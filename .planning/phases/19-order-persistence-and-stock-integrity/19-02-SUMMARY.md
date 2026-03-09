---
phase: 19-order-persistence-and-stock-integrity
plan: 02
subsystem: api
tags: [rails, checkout, orders, wallet, stock]
requires:
  - phase: 19-order-persistence-and-stock-integrity
    provides: dominio persistente de pedidos
provides:
  - service `Orders::CreateFromCart`
  - checkout com split automatico por seller
  - response de `/cart/checkout` com `order_ids` e resumo
affects: [cart-checkout, stock-integrity, order-history]
tech-stack:
  added: []
  patterns: [service transacional de checkout, um debito wallet-only com multiplos pedidos]
key-files:
  created:
    - marketplace_backend/app/services/orders/create_from_cart.rb
    - marketplace_backend/test/integration/cart_checkout_orders_test.rb
  modified:
    - marketplace_backend/app/services/orders/prepare_from_cart.rb
    - marketplace_backend/app/services/carts/finalize.rb
    - marketplace_backend/app/controllers/cart_checkout_controller.rb
    - marketplace_backend/test/integration/cart_checkout_test.rb
    - marketplace_backend/test/services/carts/finalize_test.rb
    - marketplace_backend/test/services/orders/prepare_from_cart_test.rb
key-decisions:
  - "Carrinho continua unico; o split para `Order` por seller acontece apenas no checkout."
  - "O comprador continua com um unico debito wallet-only por checkout."
  - "Sucesso do checkout retorna apenas `order_ids` e resumo, sem payload completo de pedidos."
patterns-established:
  - "Checkout passa a orquestrar preparacao -> debito wallet -> criacao de pedidos -> limpeza do carrinho."
requirements-completed:
  - ORD-01
  - ORD-02
  - INV-01
  - PAY-01
duration: 42 min
completed: 2026-03-09
---

# Phase 19 Plan 02: Checkout Order Creation Summary

**Checkout wallet-only agora cria pedidos reais por seller, baixa estoque e responde com IDs dos pedidos e resumo enxuto.**

## Performance

- **Duration:** 42 min
- **Tasks:** 3
- **Files modified:** 8

## Accomplishments
- Criado `Orders::CreateFromCart` para split automatico por seller com snapshot e decremento de estoque.
- `Carts::Finalize` foi refatorado para debitar a wallet e persistir pedidos no mesmo fluxo.
- `CartCheckoutController` deixou de expor `order_preparation` e passou a responder com `order_ids` + resumo.
- Carrinho agora termina `finished` e com itens limpos apos sucesso.

## Task Commits

1. **Task 1-3: order creation service + checkout integration + API contract** - `b6d4c9e` (feat)

## Files Created/Modified
- `marketplace_backend/app/services/orders/create_from_cart.rb` - cria pedidos por seller e baixa estoque.
- `marketplace_backend/app/services/orders/prepare_from_cart.rb` - prepara agrupamento por seller e totais em centavos.
- `marketplace_backend/app/services/carts/finalize.rb` - integra wallet debit com criacao real de pedidos.
- `marketplace_backend/app/controllers/cart_checkout_controller.rb` - altera o contrato HTTP de sucesso do checkout.
- `marketplace_backend/test/integration/cart_checkout_orders_test.rb` - cobre contrato novo e cart misto.
- `marketplace_backend/test/services/carts/finalize_test.rb` - cobre resumo, limpeza do carrinho e falha fechada.

## Decisions Made
- Manter os erros existentes do checkout (`payload invalido`, `nao encontrado`, `pagamento recusado`) para evitar drift desnecessario de contrato.
- Reaproveitar `Orders::PrepareFromCart` como etapa de preparacao dos dados confiaveis usados no checkout.

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
- A validacao automatizada prevista em `rails test` nao rodou por problema local de Bundler, entao a confirmacao deste plano ficou em verificacao estatica + coerencia entre controller, services e testes.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Fluxo principal de checkout ja produz `Order`s reais.
- Hardening contra retry e regressao financeira ficou isolado para o plano 03.

---
*Phase: 19-order-persistence-and-stock-integrity*
*Completed: 2026-03-09*
