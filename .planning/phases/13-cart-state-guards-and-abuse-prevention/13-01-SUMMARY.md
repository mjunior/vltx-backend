---
phase: 13-cart-state-guards-and-abuse-prevention
plan: 01
subsystem: api
tags: [rails, cart, authz, security, session]
requires:
  - phase: 12-cart-item-operations-with-server-side-validation
    provides: operações completas de cart item com escopo tenant
provides:
  - guardas de estado para bloquear mutações em carrinhos inativos
  - política anti-abuso por ação com limiar e revogação de sessão
  - contrato consistente de erro sem vazamento de estado interno
affects: [checkout-foundation, tenant-safety, auth-session-security]
tech-stack:
  added: []
  patterns: [service guard por estado + log estruturado + revogação de sessão por limiar]
key-files:
  created:
    - marketplace_backend/app/services/carts/inactive_cart_abuse_guard.rb
    - marketplace_backend/test/services/carts/inactive_cart_abuse_guard_test.rb
  modified:
    - marketplace_backend/app/services/carts/add_item.rb
    - marketplace_backend/app/services/carts/update_item.rb
    - marketplace_backend/app/services/carts/remove_item.rb
    - marketplace_backend/test/services/carts/update_item_test.rb
    - marketplace_backend/test/services/carts/remove_item_test.rb
key-decisions:
  - "Item de carrinho inativo do próprio usuário retorna `422 payload invalido` quando existe carrinho ativo."
  - "Sem carrinho ativo, `PATCH/DELETE` mantém `404 nao encontrado` para evitar enumeração."
  - "Após limiar de tentativas indevidas, backend revoga sessões de refresh do usuário."
patterns-established:
  - "Tentativa de mutação em estado inválido gera log estruturado com `user_id`, `cart_id`, `status`, `action`."
requirements-completed:
  - AUTHZ-07
duration: 20 min
completed: 2026-03-07
---

# Phase 13 Plan 01: State Guard and Abuse Control Summary

**Serviços de cart item foram endurecidos para bloquear mutações em carrinhos inativos e acionar revogação de sessão em abuso repetido.**

## Performance

- **Duration:** 20 min
- **Started:** 2026-03-07T20:33:00Z
- **Completed:** 2026-03-07T20:53:00Z
- **Tasks:** 3
- **Files modified:** 7

## Accomplishments
- Implementado `Carts::InactiveCartAbuseGuard` com contador por ação, limiar e revogação de sessões via `Auth::Sessions::RevokeAll`.
- `UpdateItem` e `RemoveItem` agora retornam `:invalid_payload` para item em carrinho `finished/abandoned` do próprio usuário (com carrinho ativo).
- Regras de ausência de carrinho ativo continuam mascaradas como `:not_found` para update/delete.
- Cobertura de serviço adicionada para estado inválido e comportamento do limiar de abuso.

## Task Commits

1. **Task 1-3: guardas de estado + anti-abuso + testes de serviço** - `98553b1` (feat)

## Files Created/Modified
- `marketplace_backend/app/services/carts/inactive_cart_abuse_guard.rb` - aplica contagem/limiar de abuso com log estruturado.
- `marketplace_backend/app/services/carts/add_item.rb` - bloqueia mutação se carrinho ficar inativo durante operação transacional.
- `marketplace_backend/app/services/carts/update_item.rb` - diferencia item inativo próprio (`422`) de recurso fora de escopo (`404`).
- `marketplace_backend/app/services/carts/remove_item.rb` - mesma política de estado do fluxo de update.

## Decisions Made
- Mantido contrato de erro genérico (`payload invalido`) para estado inválido, sem expor `finished/abandoned` na resposta.
- Limiar de abuso definido em 3 tentativas por ação dentro da janela da fase.

## Deviations from Plan
None.

## Issues Encountered
None no escopo do plano.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Base de segurança pronta para validação de contrato HTTP e fechamento formal da fase.

---
*Phase: 13-cart-state-guards-and-abuse-prevention*
*Completed: 2026-03-07*
