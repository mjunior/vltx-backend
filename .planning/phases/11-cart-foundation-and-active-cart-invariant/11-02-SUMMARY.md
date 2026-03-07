---
phase: 11-cart-foundation-and-active-cart-invariant
plan: 02
subsystem: api
tags: [rails, cart, database, authz, concurrency]
requires:
  - phase: 11-cart-foundation-and-active-cart-invariant
    provides: domínio base de carrinho e endpoint de upsert do carrinho ativo
provides:
  - índice único parcial para garantir um carrinho ativo por usuário
  - tratamento de corrida em criação de carrinho com retorno idempotente
  - testes de isolamento tenant para tentativas de targeting forjado
affects: [checkout-foundation, tenant-isolation, data-integrity]
tech-stack:
  added: []
  patterns: [db invariant + service recovery + negative integration tests]
key-files:
  created:
    - marketplace_backend/db/migrate/20260307112000_add_unique_active_cart_index.rb
    - marketplace_backend/test/integration/cart_authorization_test.rb
    - marketplace_backend/test/models/cart_test.rb
  modified:
    - marketplace_backend/app/models/cart.rb
    - marketplace_backend/app/services/carts/find_or_create_active.rb
    - marketplace_backend/db/schema.rb
    - marketplace_backend/test/services/carts/find_or_create_active_test.rb
    - marketplace_backend/test/integration/cart_upsert_test.rb
key-decisions:
  - "Invariável de unicidade de carrinho ativo foi aplicada no banco com índice parcial único."
  - "Service recupera de `RecordNotUnique` lendo carrinho ativo já persistido."
  - "Tentativas de targeting cross-tenant são rejeitadas com `422 payload invalido` neste endpoint sem id."
patterns-established:
  - "Regras de unicidade crítica protegidas em duas camadas: validação de model + constraint de banco."
requirements-completed:
  - CART-02
  - AUTHZ-06
duration: 12 min
completed: 2026-03-07
---

# Phase 11 Plan 02: Uniqueness and Tenant Hardening Summary

**Hardening da fundação de carrinho foi concluído com invariável de unicidade ativa e cobertura anti-abuso tenant.**

## Performance

- **Duration:** 12 min
- **Tasks:** 3
- **Files modified:** 8

## Accomplishments
- Adicionada migration de índice único parcial `index_carts_on_user_id_active_unique`.
- Reforçada regra de unicidade de carrinho ativo no model e no service.
- Cobertos cenários de targeting forjado por query/payload e validação da proteção de tenant.
- Incluído teste de modelo para provar bloqueio de segundo carrinho ativo no banco.

## Task Commits

1. **Task 1-3 (plan 02): hardening de unicidade/tenant e testes negativos** - `0777a8e`

## Files Created/Modified
- `marketplace_backend/db/migrate/20260307112000_add_unique_active_cart_index.rb` - restrição de unicidade ativa no banco.
- `marketplace_backend/app/models/cart.rb` - validação condicional de unicidade para status `active`.
- `marketplace_backend/app/services/carts/find_or_create_active.rb` - recuperação robusta de corrida (`RecordNotUnique`).
- `marketplace_backend/test/integration/cart_authorization_test.rb` - testes de targeting forjado.
- `marketplace_backend/test/models/cart_test.rb` - prova de invariantes de status/índice.

## Decisions Made
- Garantia de um único carrinho ativo por usuário ficou no banco, não só em aplicação.
- Contrato de endpoint permanece fail-closed para chaves de targeting.

## Deviations from Plan
None.

## Issues Encountered
Execução de suíte completa detectou erro em teste legado fora do escopo (`test/services/auth/jwt/issuer_test.rb` com `JWT::ExpiredSignature`).

## User Setup Required
None.

## Next Phase Readiness
- Fase 11 pronta para seguir para a fase 12 (operações de itens) com base de tenant e unicidade consolidada.

---
*Phase: 11-cart-foundation-and-active-cart-invariant*
*Completed: 2026-03-07*
