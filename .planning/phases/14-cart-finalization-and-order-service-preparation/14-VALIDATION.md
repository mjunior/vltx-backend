---
phase: 14
slug: cart-finalization-and-order-service-preparation
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-03-07
---

# Phase 14 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Minitest (Rails 8) |
| **Config file** | `marketplace_backend/test/test_helper.rb` |
| **Quick run command** | `cd marketplace_backend && RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test test/services/carts/finalize_test.rb test/integration/cart_checkout_test.rb` |
| **Full suite command** | `cd marketplace_backend && RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test` |
| **Estimated runtime** | ~80 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick command
- **After every plan wave:** Run full suite command
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 90 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 14-01-01 | 01 | 1 | CHK-01 | service | `rails test test/services/carts/finalize_test.rb` | ❌ W0 | ⬜ pending |
| 14-01-02 | 01 | 1 | CHK-01, CHK-02 | integration | `rails test test/integration/cart_checkout_test.rb` | ❌ W0 | ⬜ pending |
| 14-01-03 | 01 | 1 | CHK-01, CHK-02 | integration | `rails test test/integration/cart_checkout_test.rb test/integration/cart_items_state_guards_test.rb` | ❌ W0 | ⬜ pending |
| 14-02-01 | 02 | 2 | CHK-03 | service | `rails test test/services/orders/prepare_from_cart_test.rb` | ❌ W0 | ⬜ pending |
| 14-02-02 | 02 | 2 | CHK-03 | service/integration | `rails test test/services/carts/finalize_test.rb test/services/orders/prepare_from_cart_test.rb test/integration/cart_checkout_test.rb` | ❌ W0 | ⬜ pending |
| 14-02-03 | 02 | 2 | CHK-01, CHK-02, CHK-03 | regression | `rails test test/integration/cart_* test/services/carts/*_test.rb test/services/orders/*_test.rb` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `marketplace_backend/test/services/carts/finalize_test.rb` — transição para `finished` e validações de checkout
- [ ] `marketplace_backend/test/integration/cart_checkout_test.rb` — contrato HTTP de finalização com `wallet`
- [ ] `marketplace_backend/test/services/orders/prepare_from_cart_test.rb` — service de preparação sem persistência de pedido

---

## Manual-Only Verifications

All planned Phase 14 behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 90s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
