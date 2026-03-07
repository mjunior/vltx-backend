---
phase: 13
slug: cart-state-guards-and-abuse-prevention
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-03-07
---

# Phase 13 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Minitest (Rails 8) |
| **Config file** | `marketplace_backend/test/test_helper.rb` |
| **Quick run command** | `cd marketplace_backend && RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test test/services/carts/add_item_test.rb test/services/carts/update_item_test.rb test/services/carts/remove_item_test.rb` |
| **Full suite command** | `cd marketplace_backend && RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test` |
| **Estimated runtime** | ~75 seconds |

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
| 13-01-01 | 01 | 1 | AUTHZ-07 | service | `rails test test/services/carts/add_item_test.rb test/services/carts/update_item_test.rb test/services/carts/remove_item_test.rb` | ❌ W0 | ⬜ pending |
| 13-01-02 | 01 | 1 | AUTHZ-07 | service | `rails test test/services/carts/inactive_cart_abuse_guard_test.rb` | ❌ W0 | ⬜ pending |
| 13-01-03 | 01 | 1 | AUTHZ-07 | integration | `rails test test/integration/cart_items_create_test.rb test/integration/cart_items_update_test.rb test/integration/cart_items_destroy_test.rb` | ✅ | ⬜ pending |
| 13-02-01 | 02 | 2 | AUTHZ-07 | integration | `rails test test/integration/cart_items_state_guards_test.rb` | ❌ W0 | ⬜ pending |
| 13-02-02 | 02 | 2 | AUTHZ-07 | integration | `rails test test/integration/cart_items_abuse_guard_test.rb` | ❌ W0 | ⬜ pending |
| 13-02-03 | 02 | 2 | AUTHZ-07 | regression | `rails test test/integration/cart_items_* test/services/carts/*item*_test.rb test/services/carts/inactive_cart_abuse_guard_test.rb` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `marketplace_backend/test/services/carts/inactive_cart_abuse_guard_test.rb` — limiar e revogação de sessão por repetição
- [ ] `marketplace_backend/test/integration/cart_items_state_guards_test.rb` — mutações bloqueadas em `finished`/`abandoned`
- [ ] `marketplace_backend/test/integration/cart_items_abuse_guard_test.rb` — comportamento HTTP após threshold de abuso

---

## Manual-Only Verifications

All planned Phase 13 behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 90s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
