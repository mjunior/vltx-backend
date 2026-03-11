---
phase: 28-rack-abuse-boundary
plan: 02
subsystem: api
tags: [rack-attack, rails, admin, cart, abuse-prevention]
requires:
  - phase: 28-01
    provides: auth throttle boundary and 429 responder
provides:
  - Actor-aware throttles for checkout and cart mutations
  - Actor-aware throttles for admin sensitive actions
  - Full regression coverage and verification evidence for phase 28
affects: [phase-28, phase-29, phase-30, admin, cart]
tech-stack:
  added: []
  patterns: [actor-based throttle keys with IP fallback, phase verification via serial full-suite run]
key-files:
  created: [.planning/phases/28-rack-abuse-boundary/28-VERIFICATION.md]
  modified: [marketplace_backend/config/initializers/rack_attack.rb, marketplace_backend/test/integration/cart_checkout_test.rb, marketplace_backend/test/integration/cart_items_create_test.rb, marketplace_backend/test/integration/cart_items_update_test.rb, marketplace_backend/test/integration/cart_items_destroy_test.rb, marketplace_backend/test/integration/admin_user_balance_adjustments_test.rb, marketplace_backend/test/integration/admin_products_soft_delete_test.rb, marketplace_backend/test/integration/admin_order_contest_resolution_test.rb, marketplace_backend/test/integration/admin_users_deactivate_test.rb, marketplace_backend/test/services/products/private_listing_test.rb, marketplace_backend/test/test_helper.rb]
key-decisions:
  - "Sensitive authenticated routes use actor-based keys decoded from bearer tokens with IP fallback."
  - "Admin user deactivation joined the protected surface even though it was not listed in files_modified."
patterns-established:
  - "Operational throttles can safely count requests that later become 404/422 because the Rack boundary executes first."
  - "Full-suite validation can run serially when local pg parallelism is unstable."
requirements-completed: [ABUSE-02, ABUSE-03]
duration: 25min
completed: 2026-03-11
---

# Phase 28: Rack Abuse Boundary Summary

**Checkout, cart writes, and high-impact admin mutations now share the same Rack abuse boundary with actor-aware keys and regression coverage across the whole suite.**

## Performance

- **Duration:** 25 min
- **Started:** 2026-03-11T03:45:00Z
- **Completed:** 2026-03-11T04:10:00Z
- **Tasks:** 2
- **Files modified:** 12

## Accomplishments
- Added actor-based throttles for checkout and cart item mutations.
- Protected admin balance adjustments, soft delete, contest resolution, and user deactivation.
- Closed the phase with focused suites plus a serial full-suite validation pass.

## Task Commits

Each task was committed atomically:

1. **Task 1: Aplicar throttles por ator autenticado em endpoints operacionais de alto risco** - `9e4c6c4`
2. **Task 2: Proteger ações administrativas sensíveis e fechar regressão da fase** - `9e4c6c4`

**Plan metadata:** `9e4c6c4`

## Files Created/Modified
- `marketplace_backend/config/initializers/rack_attack.rb` - Expanded throttle policy for cart and admin-sensitive routes.
- `marketplace_backend/test/integration/cart_checkout_test.rb` - Verifies checkout throttling by authenticated actor.
- `marketplace_backend/test/integration/admin_user_balance_adjustments_test.rb` - Verifies throttling on sensitive admin wallet actions.
- `marketplace_backend/test/integration/admin_users_deactivate_test.rb` - Extends the protected admin surface to account deactivation.
- `.planning/phases/28-rack-abuse-boundary/28-VERIFICATION.md` - Captures final evidence and commands for the completed phase.

## Decisions Made
- Grouped cart item throttles by method plus actor discriminator so repeated create/update/destroy bursts are isolated per user.
- Kept the admin-sensitive limits conservative and uniform to make abuse behavior predictable for operations.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added admin deactivation to the protected surface**
- **Found during:** Task 2 (Proteger ações administrativas sensíveis e fechar regressão da fase)
- **Issue:** `PATCH /admin/users/:id/deactivate` was already a sensitive admin mutation but was not covered in the original files list.
- **Fix:** Added throttle coverage and regression test for deactivation.
- **Files modified:** `marketplace_backend/config/initializers/rack_attack.rb`, `marketplace_backend/test/integration/admin_users_deactivate_test.rb`
- **Verification:** Focused admin abuse suite passed.
- **Committed in:** `9e4c6c4`

**2. [Rule 3 - Blocking] Full-suite validation exposed unrelated deterministic test failures**
- **Found during:** Task 2 (Proteger ações administrativas sensíveis e fechar regressão da fase)
- **Issue:** One private listing expectation conflicted with the live private catalog contract, and R2 tests were inheriting developer env vars.
- **Fix:** Aligned the stale unit test with the existing private listing contract and forced deterministic test env values in `test_helper`.
- **Files modified:** `marketplace_backend/test/services/products/private_listing_test.rb`, `marketplace_backend/test/test_helper.rb`
- **Verification:** Serial full suite passed with `402 runs, 0 failures`.
- **Committed in:** `9e4c6c4`

---

**Total deviations:** 2 auto-fixed (1 Rule 2, 1 Rule 3)
**Impact on plan:** Both fixes were required to keep the phase verifiable end-to-end without broadening runtime scope beyond abuse protection.

## Issues Encountered
Parallel local full-suite execution triggered a `pg` segmentation fault on macOS/Ruby 3.3.0. The application code was revalidated with a serial full-suite run, which passed cleanly.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
Phase 29 can harden production SSL/host/CORS settings on top of a now-tested Rack boundary and a stable 429 contract.

---
*Phase: 28-rack-abuse-boundary*
*Completed: 2026-03-11*
