---
phase: 11-cart-foundation-and-active-cart-invariant
plan: 01
subsystem: api
tags: [rails, cart, authz, services, api]
requires:
  - phase: 10-public-product-detail-and-safe-serialization
    provides: padrões de controller fino, serializer dedicado e contratos de erro
provides:
  - endpoint privado `POST /cart` com autenticação obrigatória
  - serviço de obtenção/criação idempotente de carrinho ativo
  - contrato inicial do carrinho com resumo estrutural (`total_items`, `subtotal`)
affects: [checkout-foundation, tenant-isolation, private-api]
tech-stack:
  added: []
  patterns: [controller thin + domain service + serializer + integration tests]
key-files:
  created:
    - marketplace_backend/app/controllers/carts_controller.rb
    - marketplace_backend/app/models/cart.rb
    - marketplace_backend/app/services/carts/find_or_create_active.rb
    - marketplace_backend/app/serializers/carts/cart_serializer.rb
    - marketplace_backend/db/migrate/20260307110000_create_carts.rb
    - marketplace_backend/test/integration/cart_upsert_test.rb
    - marketplace_backend/test/services/carts/find_or_create_active_test.rb
  modified:
    - marketplace_backend/config/routes.rb
    - marketplace_backend/app/models/user.rb
    - marketplace_backend/test/integration/healthcheck_test.rb
key-decisions:
  - "`POST /cart` retorna `200` e reaproveita o mesmo carrinho ativo para chamadas repetidas."
  - "Controller de carrinho não aceita targeting por `user_id/owner_id/cart_id` no payload/query."
  - "Resposta não expõe `status` ou `user_id`; apenas envelope seguro para fase 11."
patterns-established:
  - "Find-or-create idempotente de recurso privado derivado de `current_user`."
requirements-completed:
  - CART-01
  - AUTHZ-05
duration: 18 min
completed: 2026-03-07
---

# Phase 11 Plan 01: Cart Foundation Summary

**Fundação de carrinho ativo foi entregue com endpoint privado idempotente e autenticação obrigatória.**

## Performance

- **Duration:** 18 min
- **Tasks:** 3
- **Files modified:** 10

## Accomplishments
- Criado domínio `Cart` com estados (`active`, `finished`, `abandoned`) e associação com `User`.
- Entregue `POST /cart` com controller fino + service `Carts::FindOrCreateActive`.
- Adicionada serialização segura com resumo estrutural (`total_items: 0`, `subtotal: "0.00"`).
- Cobertura de integração e serviço para autenticação obrigatória e idempotência.

## Task Commits

1. **Task 1-3 (plan 01 + base plan 02): implementação de carrinho e testes base** - `0777a8e`

## Files Created/Modified
- `marketplace_backend/app/controllers/carts_controller.rb` - endpoint privado `POST /cart` com validação fail-closed.
- `marketplace_backend/app/models/cart.rb` - modelo de carrinho com enum de status.
- `marketplace_backend/app/services/carts/find_or_create_active.rb` - regra de obtenção/criação idempotente.
- `marketplace_backend/app/serializers/carts/cart_serializer.rb` - contrato de resposta da fase 11.
- `marketplace_backend/db/migrate/20260307110000_create_carts.rb` - tabela `carts`.
- `marketplace_backend/test/integration/cart_upsert_test.rb` - contrato HTTP do endpoint.
- `marketplace_backend/test/services/carts/find_or_create_active_test.rb` - invariantes do service.

## Decisions Made
- Endpoint de carrinho exige JSON e token válido.
- Payload/query com chaves de targeting (`user_id`, `owner_id`, `cart_id`, `id`) é rejeitado.
- Requisição repetida mantém o mesmo carrinho ativo por usuário.

## Deviations from Plan
None.

## Issues Encountered
None no escopo do plano.

## User Setup Required
None.

## Next Phase Readiness
- Base pronta para hardening de unicidade em banco e cobertura cross-tenant (plan 02).

---
*Phase: 11-cart-foundation-and-active-cart-invariant*
*Completed: 2026-03-07*
