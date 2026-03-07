---
phase: 12
slug: cart-item-operations-with-server-side-validation
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-03-07
---

# Phase 12 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Minitest (Rails 8) |
| **Config file** | `marketplace_backend/test/test_helper.rb` |
| **Quick run command** | `cd marketplace_backend && RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test test/integration/cart_items_create_test.rb test/services/carts/add_item_test.rb` |
| **Full suite command** | `cd marketplace_backend && RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test` |
| **Estimated runtime** | ~70 seconds |

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
| 12-01-01 | 01 | 1 | CART-03, CART-06 | integration | `rails test test/integration/cart_items_create_test.rb` | ❌ W0 | ⬜ pending |
| 12-01-02 | 01 | 1 | CART-07, CART-08, CART-09 | service | `rails test test/services/carts/add_item_test.rb` | ❌ W0 | ⬜ pending |
| 12-02-01 | 02 | 2 | CART-05, CART-06 | integration | `rails test test/integration/cart_items_update_test.rb` | ❌ W0 | ⬜ pending |
| 12-02-02 | 02 | 2 | CART-04 | integration | `rails test test/integration/cart_items_destroy_test.rb` | ❌ W0 | ⬜ pending |
| 12-03-01 | 03 | 3 | CART-08, CART-09 | integration | `rails test test/integration/cart_items_fraud_guard_test.rb` | ❌ W0 | ⬜ pending |
| 12-03-02 | 03 | 3 | CART-03..CART-09 | regression | `rails test test/integration/cart_items_* test/services/carts/*item*_test.rb` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `marketplace_backend/test/integration/cart_items_create_test.rb` — contrato de add item
- [ ] `marketplace_backend/test/integration/cart_items_update_test.rb` — contrato de update quantity
- [ ] `marketplace_backend/test/integration/cart_items_destroy_test.rb` — contrato de remove item
- [ ] `marketplace_backend/test/integration/cart_items_fraud_guard_test.rb` — cenários anti-fraude e tenant
- [ ] `marketplace_backend/test/services/carts/add_item_test.rb` — regras de preço/estoque/produto próprio
- [ ] `marketplace_backend/test/services/carts/update_item_test.rb` — clamp e validações de quantidade
- [ ] `marketplace_backend/test/services/carts/remove_item_test.rb` — remoção segura no carrinho ativo

---

## Manual-Only Verifications

All planned Phase 12 behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 90s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
