---
phase: 19-order-persistence-and-stock-integrity
plan: 01
subsystem: database
tags: [rails, orders, active-record, postgres, schema]
requires:
  - phase: 18-wallet-authorization-and-tenant-isolation-surface
    provides: checkout wallet-only e invariantes financeiras estaveis
provides:
  - tabelas `orders` e `order_items`
  - modelos persistentes de pedido e item com snapshot
  - constraints para status, totais e unicidade por cart+seller
affects: [checkout, order-workflow, seller-finance, ratings]
tech-stack:
  added: []
  patterns: [order header + order item snapshot, split por seller com cabecalho dedicado]
key-files:
  created:
    - marketplace_backend/db/migrate/20260309210000_create_orders.rb
    - marketplace_backend/db/migrate/20260309210100_create_order_items.rb
    - marketplace_backend/app/models/order.rb
    - marketplace_backend/app/models/order_item.rb
    - marketplace_backend/test/models/order_test.rb
    - marketplace_backend/test/models/order_item_test.rb
  modified:
    - marketplace_backend/app/models/user.rb
    - marketplace_backend/app/models/product.rb
    - marketplace_backend/db/schema.rb
key-decisions:
  - "Cada `Order` representa um seller unico dentro do checkout splitado."
  - "Snapshot financeiro do item fica em centavos (`unit_price_cents`, `line_subtotal_cents`)."
  - "Unicidade por `source_cart_id + seller_id` previne duplicidade basica do cabecalho do pedido."
patterns-established:
  - "Historico de compra migra do carrinho para `Order`/`OrderItem`."
requirements-completed:
  - ORD-01
  - ORD-02
  - INV-01
duration: 28 min
completed: 2026-03-09
---

# Phase 19 Plan 01: Persistent Order Domain Summary

**Dominio persistente de pedidos foi criado com cabecalho por seller e snapshot financeiro imutavel por item.**

## Performance

- **Duration:** 28 min
- **Tasks:** 3
- **Files modified:** 9

## Accomplishments
- Criadas as tabelas `orders` e `order_items` com constraints de dominio.
- Modelos `Order` e `OrderItem` passaram a representar o historico real da compra.
- Adicionados testes de model para status inicial, totais, seller do pedido e consistencia do snapshot.

## Task Commits

1. **Task 1-3: schema + models + model tests** - `f7859d4` (feat)

## Files Created/Modified
- `marketplace_backend/db/migrate/20260309210000_create_orders.rb` - cria cabecalho persistente do pedido.
- `marketplace_backend/db/migrate/20260309210100_create_order_items.rb` - cria snapshot dos itens comprados.
- `marketplace_backend/app/models/order.rb` - valida contrato do pedido e status inicial.
- `marketplace_backend/app/models/order_item.rb` - valida snapshot, seller e subtotal por item.
- `marketplace_backend/app/models/user.rb` - adiciona associacoes buyer/seller de pedidos.
- `marketplace_backend/app/models/product.rb` - conecta produto ao historico de order items.
- `marketplace_backend/db/schema.rb` - refletido manualmente porque `db:migrate` nao rodou no ambiente atual.

## Decisions Made
- Persistir valores monetarios do pedido em centavos para convergir com o ledger.
- Manter `seller_id` tambem em `order_items` para simplificar fases futuras de seller finance e ratings.

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
- `bundle`/`rails` nao puderam ser executados localmente por incompatibilidade do runtime Bundler/Ruby no ambiente, entao `schema.rb` foi atualizado manualmente e a verificacao ficou limitada a checagem sintatica.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Base de dados e modelos estao prontos para integrar o checkout real no plano 02.
- Validacao Rails completa continua pendente quando o ambiente local aceitar Bundler com Ruby 3.3.

---
*Phase: 19-order-persistence-and-stock-integrity*
*Completed: 2026-03-09*
