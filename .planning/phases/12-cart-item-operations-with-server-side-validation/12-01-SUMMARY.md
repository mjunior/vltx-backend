---
phase: 12-cart-item-operations-with-server-side-validation
plan: 01
subsystem: api
tags: [rails, cart, cart-items, validation, transactions]
requires:
  - phase: 11-cart-foundation-and-active-cart-invariant
    provides: carrinho ativo idempotente e isolamento tenant base
provides:
  - estrutura `cart_items` com integridade relacional
  - endpoint `POST /cart/items` com validação server-side de payload
  - service transacional de adição com clamp de estoque e bloqueio de produto próprio
affects: [checkout-foundation, cart-contract, tenant-safety]
tech-stack:
  added: []
  patterns: [controller thin + service transacional + serializer de agregado]
key-files:
  created:
    - marketplace_backend/db/migrate/20260307123000_create_cart_items.rb
    - marketplace_backend/app/models/cart_item.rb
    - marketplace_backend/app/services/carts/add_item.rb
    - marketplace_backend/app/controllers/cart_items_controller.rb
    - marketplace_backend/test/integration/cart_items_create_test.rb
    - marketplace_backend/test/services/carts/add_item_test.rb
  modified:
    - marketplace_backend/app/models/cart.rb
    - marketplace_backend/app/models/product.rb
    - marketplace_backend/app/serializers/carts/cart_serializer.rb
    - marketplace_backend/config/routes.rb
key-decisions:
  - "`POST /cart/items` aceita `product_id` e `quantity`; `price` enviado é ignorado."
  - "Quantidade acima do estoque é ajustada para estoque disponível (clamp)."
  - "Produto próprio/inativo/deletado e `product_id` inválido retornam `422 payload invalido`."
patterns-established:
  - "Subtotal do carrinho passa a ser derivado server-side de `cart_items` e `products` atuais."
requirements-completed:
  - CART-03
  - CART-06
  - CART-07
  - CART-08
  - CART-09
duration: 18 min
completed: 2026-03-07
---

# Phase 12 Plan 01: Add Item Foundation Summary

**Adição de item no carrinho foi entregue com validação transacional e contrato seguro contra payload forjado.**

## Performance

- **Duration:** 18 min
- **Tasks:** 3
- **Files modified:** 10

## Accomplishments
- Criada tabela `cart_items` (UUID) com FK para `carts` e `products`, índice único por produto no carrinho e check de quantidade positiva.
- Implementado `Carts::AddItem` com validações de domínio (`product_id`, `quantity`, produto próprio, produto ativo/público).
- Criado endpoint `POST /cart/items` com controller fino e payload mínimo.
- Serializer de carrinho evoluído para retornar `items`, `total_items` e `subtotal` recalculado no backend.

## Task Commits

1. **Task 1-3: base de cart items + add item + contrato HTTP** - `29cf4a3`

## Deviations from Plan
None.

## Issues Encountered
None no escopo do plano.

## Next Phase Readiness
- Base pronta para `PATCH /cart/items/:id` e `DELETE /cart/items/:id` com guardas tenant.

---
*Phase: 12-cart-item-operations-with-server-side-validation*
*Completed: 2026-03-07*
