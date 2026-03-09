---
phase: 19
slug: order-persistence-and-stock-integrity
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-03-09
---

# Phase 19 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Minitest (Rails 8) |
| **Config file** | `marketplace_backend/test/test_helper.rb` |
| **Quick run command** | `cd marketplace_backend && RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test test/models/order_test.rb test/models/order_item_test.rb test/services/orders/create_from_cart_test.rb test/integration/cart_checkout_orders_test.rb` |
| **Full suite command** | `cd marketplace_backend && RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test` |
| **Estimated runtime** | ~150 seconds |

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
| 19-01-01 | 01 | 1 | ORD-01, ORD-02 | model | `rails test test/models/order_test.rb test/models/order_item_test.rb` | ❌ W0 | ⬜ pending |
| 19-01-02 | 01 | 1 | INV-01 | model | `rails test test/models/order_test.rb test/models/order_item_test.rb` | ❌ W0 | ⬜ pending |
| 19-01-03 | 01 | 1 | ORD-01 | service | `rails test test/services/orders/create_from_cart_test.rb` | ❌ W0 | ⬜ pending |
| 19-02-01 | 02 | 2 | ORD-01, PAY-01 | integration | `rails test test/integration/cart_checkout_orders_test.rb` | ❌ W0 | ⬜ pending |
| 19-02-02 | 02 | 2 | INV-01, ORD-02 | service | `rails test test/services/orders/create_from_cart_test.rb test/integration/cart_checkout_orders_test.rb` | ❌ W0 | ⬜ pending |
| 19-02-03 | 02 | 2 | ORD-01, ORD-02, PAY-01 | regression | `rails test test/services/carts/finalize_test.rb test/integration/cart_checkout_orders_test.rb` | ❌ W0 | ⬜ pending |
| 19-03-01 | 03 | 3 | INV-01, ORD-02 | concurrency | `rails test test/services/orders/create_from_cart_test.rb` | ❌ W0 | ⬜ pending |
| 19-03-02 | 03 | 3 | INV-01 | integration | `rails test test/integration/cart_checkout_orders_test.rb` | ❌ W0 | ⬜ pending |
| 19-03-03 | 03 | 3 | INV-01, ORD-01, ORD-02, PAY-01 | regression | `rails test test/models/order_test.rb test/models/order_item_test.rb test/services/orders/create_from_cart_test.rb test/integration/cart_checkout_orders_test.rb test/services/carts/finalize_test.rb` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `marketplace_backend/test/models/order_test.rb` — invariantes de cabecalho e status inicial do pedido
- [ ] `marketplace_backend/test/models/order_item_test.rb` — snapshot, ownership operacional e totais por item
- [ ] `marketplace_backend/test/services/orders/create_from_cart_test.rb` — split por seller, estoque, rollback e retry
- [ ] `marketplace_backend/test/integration/cart_checkout_orders_test.rb` — contrato HTTP do checkout com `order_ids` + resumo

---

## Manual-Only Verifications

All planned Phase 19 behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 90s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
