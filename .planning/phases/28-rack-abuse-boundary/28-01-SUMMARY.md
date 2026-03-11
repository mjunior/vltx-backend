---
phase: 28-rack-abuse-boundary
plan: 01
subsystem: api
tags: [rack-attack, rails, auth, rate-limiting]
requires: []
provides:
  - Rack boundary for user/admin auth throttling
  - Uniform 429 JSON contract for blocked requests
  - Healthcheck-safe abuse controls for Railway
affects: [phase-28, phase-29, phase-30, auth]
tech-stack:
  added: [rack-attack]
  patterns: [rack-boundary throttling, deterministic test cache reset]
key-files:
  created: [marketplace_backend/config/initializers/rack_attack.rb]
  modified: [marketplace_backend/Gemfile, marketplace_backend/Gemfile.lock, marketplace_backend/config/application.rb, marketplace_backend/test/test_helper.rb, marketplace_backend/test/integration/auth_login_test.rb, marketplace_backend/test/integration/auth_refresh_test.rb, marketplace_backend/test/integration/admin_auth_login_test.rb, marketplace_backend/test/integration/admin_auth_refresh_test.rb, marketplace_backend/test/integration/healthcheck_test.rb]
key-decisions:
  - "Auth throttles were applied in Rack before controllers to reduce brute-force cost."
  - "The 429 contract stays generic and `/up` is explicitly safelisted for Railway healthchecks."
patterns-established:
  - "Rack::Attack uses Rails.cache with a memory-store fallback when test cache is null."
  - "Throttle regression tests clear Rack::Attack state between runs to avoid cross-test IP bleed."
requirements-completed: [ABUSE-01, ABUSE-03]
duration: 20min
completed: 2026-03-11
---

# Phase 28: Rack Abuse Boundary Summary

**Rack::Attack now blocks repeated user/admin auth bursts with a single 429 contract while keeping Railway healthchecks outside the abuse boundary.**

## Performance

- **Duration:** 20 min
- **Started:** 2026-03-11T03:25:00Z
- **Completed:** 2026-03-11T03:45:00Z
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments
- Added `rack-attack` and mounted it in the API middleware stack.
- Implemented separate throttles for user/admin login and refresh flows.
- Standardized the 429 response and protected `/up` from accidental throttling.

## Task Commits

Each task was committed atomically:

1. **Task 1: Adicionar boundary de throttling em Rack para auth user/admin** - `9e4c6c4`
2. **Task 2: Padronizar resposta 429 e preservar caminhos de infraestrutura** - `9e4c6c4`

**Plan metadata:** `9e4c6c4`

## Files Created/Modified
- `marketplace_backend/config/initializers/rack_attack.rb` - Central throttle policy and 429 responder.
- `marketplace_backend/config/application.rb` - Mounts Rack::Attack in the API stack.
- `marketplace_backend/test/test_helper.rb` - Resets throttle cache and fixes deterministic test env state.
- `marketplace_backend/test/integration/auth_login_test.rb` - Covers user login throttling.
- `marketplace_backend/test/integration/admin_auth_login_test.rb` - Covers stricter admin login throttling.

## Decisions Made
- Used path-specific IP throttles for auth because request JSON bodies are not safely available at raw Rack parsing time.
- Logged minimal throttle metadata in the responder to keep operational traces without exposing sensitive request details.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Test boot required production-like DATABASE_URL**
- **Found during:** Task 1 (Adicionar boundary de throttling em Rack para auth user/admin)
- **Issue:** The production multi-db config parses during test boot and raises without `DATABASE_URL`.
- **Fix:** Added deterministic test-only env boot values in `test/test_helper.rb`.
- **Files modified:** `marketplace_backend/test/test_helper.rb`
- **Verification:** Focused auth and healthcheck suites booted and passed.
- **Committed in:** `9e4c6c4`

---

**Total deviations:** 1 auto-fixed (1 Rule 3)
**Impact on plan:** Necessary to execute the existing test harness under the current Railway-oriented database configuration.

## Issues Encountered
None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
Wave 2 can extend the same Rack boundary to cart and admin-sensitive mutations without changing the 429 contract or middleware pattern.

---
*Phase: 28-rack-abuse-boundary*
*Completed: 2026-03-11*
