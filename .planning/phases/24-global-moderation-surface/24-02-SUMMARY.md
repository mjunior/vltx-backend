---
phase: 24-global-moderation-surface
plan: 02
subsystem: admin-product-moderation
tags: [rails, admin, products, moderation, catalog]
requires:
  - phase: 23-admin-identity-boundary-and-verification-foundation
    provides: auth admin
provides:
  - endpoint `/admin/products/:id/soft_delete`
  - remoção imediata do catálogo público
  - visibilidade privada mantida para seller
affects: [admin, products, public-catalog]
tech-stack:
  added: []
  patterns: [admin-soft-delete, public-catalog-hide, seller-private-visibility-after-moderation]
key-files:
  created:
    - marketplace_backend/app/controllers/admin/products_controller.rb
    - marketplace_backend/app/services/admin_products/soft_delete.rb
    - marketplace_backend/test/integration/admin_products_soft_delete_test.rb
  modified:
    - marketplace_backend/app/services/products/private_listing.rb
    - marketplace_backend/app/serializers/products/private_product_serializer.rb
    - marketplace_backend/config/routes.rb
key-decisions:
  - "Moderação de anúncio usa soft delete direto."
  - "Produto moderado sai do público, mas continua visível ao seller no contexto privado."
  - "Resposta de sucesso da moderação permanece mínima."
requirements-completed:
  - ADM-05
completed: 2026-03-10
---

# Phase 24 Plan 02: Admin Product Moderation Summary

**O admin agora consegue remover anúncios inapropriados com `soft_delete` global.**

## Accomplishments
- Criado `PATCH /admin/products/:id/soft_delete`.
- Produto moderado some imediatamente de `/public/products` e `/public/products/:id`.
- Seller continua vendo o produto moderado em `/products`, com `deleted_at` exposto.

## Verification
- `RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test test/integration/admin_products_soft_delete_test.rb test/integration/public_products_index_test.rb test/integration/public_product_show_test.rb test/integration/product_index_test.rb`

---
*Phase: 24-global-moderation-surface*
*Completed: 2026-03-10*
