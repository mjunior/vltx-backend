---
phase: 25-administrative-user-operations
plan: 03
subsystem: admin-products-read
tags: [rails, admin, products, catalog, moderation]
requires:
  - phase: 24-global-moderation-surface
    provides: moderação admin de produto por `soft_delete`
provides:
  - endpoints `/admin/products` e `/admin/products/:id`
  - payload admin de anúncio com `price_cents`
  - leitura global de anúncios ativos e moderados
affects: [admin, products, catalog]
tech-stack:
  added: []
  patterns: [admin-product-listing, admin-product-detail, panel-ready-product-payload]
key-files:
  created:
    - marketplace_backend/app/serializers/admin/products/product_serializer.rb
    - marketplace_backend/test/integration/admin_products_index_test.rb
  modified:
    - marketplace_backend/app/controllers/admin/products_controller.rb
    - marketplace_backend/config/routes.rb
    - marketplace_backend/test/integration/admin_authorization_boundary_test.rb
key-decisions:
  - "A leitura admin de anúncios inclui ativos e soft-deletados."
  - "O contrato admin usa `price_cents` sem alterar os serializers públicos existentes."
  - "A nova leitura não interfere na vitrine pública nem no fluxo de seller."
requirements-completed:
  - ADM-07
completed: 2026-03-10
---

# Phase 25 Plan 03: Admin Products Read Summary

**A superfície do painel admin foi completada com listagem e detalhe de anúncios.**

## Accomplishments
- Criados `GET /admin/products` e `GET /admin/products/:id`.
- O admin agora enxerga anúncios ativos e moderados no mesmo namespace de moderação.
- O payload administrativo de produto expõe `price_cents`, `seller_id`, `active` e `deleted_at`.

## Verification
- `RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test test/integration/admin_products_index_test.rb test/integration/admin_products_soft_delete_test.rb test/integration/public_products_index_test.rb`

---
*Phase: 25-administrative-user-operations*
*Completed: 2026-03-10*
