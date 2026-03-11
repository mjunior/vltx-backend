---
phase: 28
slug: rack-abuse-boundary
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-03-11
---

# Phase 28 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Minitest (Rails 8) |
| **Config file** | `marketplace_backend/test/test_helper.rb` |
| **Quick run command** | `cd marketplace_backend && RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test test/integration/auth_login_test.rb test/integration/auth_refresh_test.rb test/integration/admin_auth_login_test.rb test/integration/admin_auth_refresh_test.rb test/integration/cart_checkout_test.rb` |
| **Full suite command** | `cd marketplace_backend && RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test` |
| **Estimated runtime** | ~120 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick command
- **After every plan wave:** Run full suite command
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 28-01-01 | 01 | 1 | ABUSE-01 | integration | `rails test test/integration/auth_login_test.rb test/integration/auth_refresh_test.rb test/integration/admin_auth_login_test.rb test/integration/admin_auth_refresh_test.rb` | ✅ | ⬜ pending |
| 28-01-02 | 01 | 1 | ABUSE-03 | integration | `rails test test/integration/healthcheck_test.rb test/integration/auth_login_test.rb test/integration/admin_auth_login_test.rb` | ✅ | ⬜ pending |
| 28-02-01 | 02 | 2 | ABUSE-02 | integration | `rails test test/integration/cart_checkout_test.rb test/integration/cart_items_create_test.rb test/integration/admin_user_balance_adjustments_test.rb test/integration/admin_order_contest_resolution_test.rb` | ✅ | ⬜ pending |
| 28-02-02 | 02 | 2 | ABUSE-02, ABUSE-03 | regression | `rails test test/integration/cart_checkout_test.rb test/integration/cart_items_create_test.rb test/integration/cart_items_update_test.rb test/integration/cart_items_destroy_test.rb test/integration/admin_user_balance_adjustments_test.rb test/integration/admin_products_soft_delete_test.rb test/integration/admin_order_contest_resolution_test.rb test/integration/healthcheck_test.rb` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- Existing infrastructure covers all phase requirements.
- Expand current integration suites or add dedicated throttle assertions within the Rails test tree as needed.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Threshold calibration on Railway traffic | ABUSE-01, ABUSE-02 | Valores reais de produção dependem de volume e health probes externos | Validar no Railway após deploy que `/up` não sofre throttle e que login legítimo não bloqueia usuários sob uso normal |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
