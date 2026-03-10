---
phase: 22-seller-finance-surface-contestation-and-ratings
plan: 03
subsystem: ratings
tags: [rails, ratings, products, sellers, post-delivery]
requires:
  - phase: 21-secure-order-workflow-and-cancellation-refunds
    provides: pedidos entregues com workflow auditavel
  - phase: 22-seller-finance-surface-contestation-and-ratings
    provides: contestacao pos-entrega
provides:
  - tabelas `product_ratings` e `seller_ratings`
  - endpoint `POST /orders/:order_id/items/:id/rating`
  - escrita atomica de rating duplo por `order_item`
affects: [orders, ratings, products, sellers, api]
tech-stack:
  added: []
  patterns: [dual-write transactional ratings, delivered-only eligibility, duplicate-safe order item rating]
key-files:
  created:
    - marketplace_backend/db/migrate/20260310020000_create_product_ratings.rb
    - marketplace_backend/db/migrate/20260310020100_create_seller_ratings.rb
    - marketplace_backend/app/models/product_rating.rb
    - marketplace_backend/app/models/seller_rating.rb
    - marketplace_backend/app/controllers/order_item_ratings_controller.rb
    - marketplace_backend/app/services/ratings/create_for_order_item.rb
    - marketplace_backend/test/models/product_rating_test.rb
    - marketplace_backend/test/models/seller_rating_test.rb
    - marketplace_backend/test/services/ratings/create_for_order_item_test.rb
    - marketplace_backend/test/integration/order_item_ratings_test.rb
  modified:
    - marketplace_backend/app/models/order.rb
    - marketplace_backend/app/models/order_item.rb
    - marketplace_backend/app/models/user.rb
    - marketplace_backend/config/routes.rb
    - marketplace_backend/db/schema.rb
    - marketplace_backend/test/integration/healthcheck_test.rb
key-decisions:
  - "As avaliacoes ficam fisicamente separadas por produto e por vendedor para facilitar medias futuras."
  - "Um `order_item` so pode gerar um par de avaliacoes uma unica vez."
  - "Elegibilidade usa a entrega ocorrida no workflow; pedido `contested` continua elegivel se ja passou por `delivered`."
patterns-established:
  - "Acao unica cria os dois datasets de avaliacao no mesmo commit transacional."
requirements-completed:
  - RATE-01
  - RATE-02
duration: 47 min
completed: 2026-03-10
---

# Phase 22 Plan 03: Ratings Summary

**O milestone foi fechado com ratings separados por produto e seller, escritos juntos a partir do mesmo `order_item` entregue.**

## Performance

- **Duration:** 47 min
- **Tasks:** 3
- **Files modified:** 15

## Accomplishments
- Criadas as tabelas `product_ratings` e `seller_ratings` com unicidade por `order_item` e score de 1 a 5.
- O endpoint `POST /orders/:order_id/items/:id/rating` grava os dois registros em uma transacao unica.
- A elegibilidade ficou presa ao historico de entrega do pedido, bloqueando item nao entregue e permitindo rating mesmo apos `contest`.

## Task Commits

1. **Task 1-3: dual rating schema + atomic service + secure endpoint** - pending commit

## Issues Encountered

- `db/schema.rb` ficou truncado no bloco de `product_ratings` durante a primeira passada; o arquivo foi corrigido e regenerado antes da regressao final.

## Verification

- `RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test test/models/product_rating_test.rb test/models/seller_rating_test.rb test/services/ratings/create_for_order_item_test.rb test/integration/order_item_ratings_test.rb`
- `RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test`
- Resultado final: `303 runs, 1059 assertions, 0 failures, 0 errors, 0 skips`

## Next Phase Readiness

- Milestone v1.4 ficou implementado; proximo passo natural e auditoria/fechamento do milestone.

---
*Phase: 22-seller-finance-surface-contestation-and-ratings*
*Completed: 2026-03-10*
