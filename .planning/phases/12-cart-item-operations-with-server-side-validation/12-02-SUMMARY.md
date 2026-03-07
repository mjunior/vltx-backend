---
phase: 12-cart-item-operations-with-server-side-validation
plan: 02
subsystem: api
tags: [rails, cart, authz, update, delete]
requires:
  - phase: 12-cart-item-operations-with-server-side-validation
    provides: cart_items e add item transacional
provides:
  - endpoint `PATCH /cart/items/:id` para atualização de quantidade
  - endpoint `DELETE /cart/items/:id` para remoção segura de item
  - services dedicados de update/remove com máscara tenant (`404`)
affects: [checkout-foundation, tenant-safety, cart-integrity]
tech-stack:
  added: []
  patterns: [service per action + masked not_found + scoped active cart]
key-files:
  created:
    - marketplace_backend/app/services/carts/cart_finder.rb
    - marketplace_backend/app/services/carts/update_item.rb
    - marketplace_backend/app/services/carts/remove_item.rb
    - marketplace_backend/test/integration/cart_items_update_test.rb
    - marketplace_backend/test/integration/cart_items_destroy_test.rb
    - marketplace_backend/test/services/carts/update_item_test.rb
    - marketplace_backend/test/services/carts/remove_item_test.rb
  modified:
    - marketplace_backend/app/controllers/cart_items_controller.rb
    - marketplace_backend/app/serializers/carts/cart_serializer.rb
key-decisions:
  - "`quantity=0` é inválida (`422`) no update."
  - "Update/Delete de item fora do carrinho ativo do usuário retorna `404 nao encontrado`."
  - "Update mantém clamp por estoque atual do produto."
patterns-established:
  - "Resolução de carrinho ativo compartilhada via `Carts::CartFinder` para operações de item."
requirements-completed:
  - CART-04
  - CART-05
  - CART-06
  - CART-08
duration: 14 min
completed: 2026-03-07
---

# Phase 12 Plan 02: Update and Remove Item Summary

**Operações de update/remove foram concluídas com isolamento tenant e contrato de erro mascarado.**

## Performance

- **Duration:** 14 min
- **Tasks:** 3
- **Files modified:** 9

## Accomplishments
- Implementado `Carts::UpdateItem` com validação de quantidade e clamp de estoque.
- Implementado `Carts::RemoveItem` com escopo no carrinho ativo do usuário autenticado.
- Expandido `CartItemsController` para `update` e `destroy` com mapeamento seguro de `404` mascarado.
- Adicionada cobertura de integração e serviço para casos de sucesso e acesso cross-tenant.

## Task Commits

1. **Task 1-3: update/remove + escopo tenant + testes** - `29cf4a3`

## Deviations from Plan
None.

## Issues Encountered
None no escopo do plano.

## Next Phase Readiness
- Fluxos de item completos para fechar matriz anti-fraude e verificação formal.

---
*Phase: 12-cart-item-operations-with-server-side-validation*
*Completed: 2026-03-07*
