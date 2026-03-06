---
phase: 08-seller-product-lifecycle-edit-deactivate-delete
plan: 01
subsystem: api
tags: [rails, products, lifecycle, authz, soft-delete]
requires:
  - phase: 07-seller-product-creation-owner-derived-from-token
    provides: product domain and private creation endpoint with owner-by-token
provides:
  - update endpoint for owned products only
  - soft-delete base (`deleted_at`) and not-deleted query scope
  - update-specific authz tests with 404 masking for cross-tenant access
affects: [products, authz, lifecycle]
tech-stack:
  added: []
  patterns: [owner-scoped lookup, fail-closed update payload constraints]
key-files:
  created:
    - marketplace_backend/db/migrate/20260306043000_add_deleted_at_to_products.rb
    - marketplace_backend/app/services/products/update.rb
    - marketplace_backend/test/integration/product_lifecycle_test.rb
    - marketplace_backend/test/services/products/update_test.rb
  modified:
    - marketplace_backend/db/schema.rb
    - marketplace_backend/app/models/product.rb
    - marketplace_backend/app/controllers/products_controller.rb
    - marketplace_backend/config/routes.rb
key-decisions:
  - "Product update returns 404 for not-owned or missing product to avoid existence leakage."
  - "`active:false` is rejected on update; only `active:true` is accepted in PATCH /products/:id."
patterns-established:
  - "Lifecycle operations run against `user.products.not_deleted` to enforce ownership and soft-delete visibility."
requirements-completed:
  - PROD-02
  - AUTHZ-02
duration: 6 min
completed: 2026-03-06
---

# Phase 8 Plan 01: Product Update Lifecycle Summary

**Owned-product update shipped with 404 ownership masking and soft-delete-ready domain scope.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-03-06T04:34:00Z
- **Completed:** 2026-03-06T04:40:28Z
- **Tasks:** 3
- **Files modified:** 8

## Accomplishments
- Added `deleted_at` foundation and `Product.not_deleted` scope for lifecycle-safe lookups.
- Implemented `PATCH /products/:id` with owner-scoped resolution and `active:false` rejection.
- Added integration/service coverage for success, invalid payload, other-seller product, and missing product.

## Task Commits

Each task was committed atomically:

1. **Task 1: Preparar base de soft-delete e lookup seguro de produto próprio** - `369af30` (feat)
2. **Task 2: Implementar PATCH /products/:id com regra de ownership e active controlado** - `34654f4` (feat)
3. **Task 3: Cobrir update com cenários de sucesso, 404 e payload inválido** - `8fbc770` (test)

**Plan metadata:** `1c0e448` (docs)

## Files Created/Modified
- `marketplace_backend/app/services/products/update.rb` - update domain rules with ownership masking and active-control policy.
- `marketplace_backend/app/controllers/products_controller.rb` - new update action contract for lifecycle.
- `marketplace_backend/db/migrate/20260306043000_add_deleted_at_to_products.rb` - soft-delete column/indexes.
- `marketplace_backend/test/integration/product_lifecycle_test.rb` - request-level update lifecycle coverage.
- `marketplace_backend/test/services/products/update_test.rb` - service invariants for update/authz behavior.

## Decisions Made
- Keep ownership non-disclosure policy via `404` for cross-tenant or missing products.
- Restrict deactivation semantics to dedicated endpoint, not generic update.

## Deviations from Plan

None - plan executed as specified.

## Issues Encountered
None.

## User Setup Required
None.

## Next Phase Readiness
- Update lifecycle baseline is ready.
- Deactivate dedicated operation can be added without changing update contract.

---
*Phase: 08-seller-product-lifecycle-edit-deactivate-delete*
*Completed: 2026-03-06*
