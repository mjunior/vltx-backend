---
phase: 08-seller-product-lifecycle-edit-deactivate-delete
plan: 02
subsystem: api
tags: [rails, products, deactivate, authz, idempotency]
requires:
  - phase: 08-seller-product-lifecycle-edit-deactivate-delete
    provides: owned update flow and soft-delete lookup scope
provides:
  - dedicated deactivate service and endpoint
  - idempotent deactivate behavior with stable 200 responses
  - regression tests for deactivate ownership constraints
affects: [products, authz, lifecycle]
tech-stack:
  added: []
  patterns: [idempotent command endpoint, ownership lookup with 404 masking]
key-files:
  created:
    - marketplace_backend/app/services/products/deactivate.rb
    - marketplace_backend/test/services/products/deactivate_test.rb
  modified:
    - marketplace_backend/app/controllers/products_controller.rb
    - marketplace_backend/config/routes.rb
    - marketplace_backend/test/integration/product_lifecycle_test.rb
key-decisions:
  - "Deactivate remains dedicated endpoint (`PATCH /products/:id/deactivate`) with idempotent 200 contract."
  - "Not-owned deactivate attempts keep same 404 masking policy as update/delete operations."
patterns-established:
  - "Deactivate service is authoritative for active state transitions to avoid update endpoint bypass."
requirements-completed:
  - PROD-03
  - AUTHZ-02
duration: 4 min
completed: 2026-03-06
---

# Phase 8 Plan 02: Product Deactivate Summary

**Dedicated product deactivation delivered with idempotent behavior and strict ownership enforcement.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-06T04:40:29Z
- **Completed:** 2026-03-06T04:41:58Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments
- Added `Products::Deactivate` service with idempotent inactive transitions.
- Exposed `PATCH /products/:id/deactivate` with same authz and not-found masking policy.
- Added integration/service tests for success, already-inactive idempotency, and cross-tenant 404 behavior.

## Task Commits

Each task was committed atomically:

1. **Task 1: Implementar serviço de desativação idempotente com ownership scope** - `a58fb71` (feat)
2. **Task 2: Expor PATCH /products/:id/deactivate no controller** - `75d0e2f` (feat)
3. **Task 3: Adicionar cobertura de integração e serviço para deactivate** - `15ab99c` (test)

## Files Created/Modified
- `marketplace_backend/app/services/products/deactivate.rb` - idempotent deactivate logic on owned not-deleted products.
- `marketplace_backend/app/controllers/products_controller.rb` - dedicated deactivate action.
- `marketplace_backend/test/services/products/deactivate_test.rb` - service behavior and ownership masking checks.
- `marketplace_backend/test/integration/product_lifecycle_test.rb` - deactivate contract tests.

## Decisions Made
- Keep deactivate command separate from update to preserve explicit business intent.
- Preserve 404 policy for all not-accessible resources.

## Deviations from Plan

None - plan executed as specified.

## Issues Encountered
None.

## User Setup Required
None.

## Next Phase Readiness
- Delete operation can now reuse ownership and not-deleted patterns from update/deactivate.

---
*Phase: 08-seller-product-lifecycle-edit-deactivate-delete*
*Completed: 2026-03-06*
