---
phase: 20
slug: order-linked-ledger-and-wallet-provisioning
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-03-09
---

# Phase 20 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Minitest (Rails 8) |
| **Config file** | `marketplace_backend/test/test_helper.rb` |
| **Quick run command** | `cd marketplace_backend && RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test test/models/checkout_group_test.rb test/models/seller_receivable_test.rb test/services/carts/finalize_test.rb test/services/seller_receivables/read_summary_test.rb` |
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
| 20-01-01 | 01 | 1 | PAY-03 | model | `rails test test/models/checkout_group_test.rb` | ❌ W0 | ⬜ pending |
| 20-01-02 | 01 | 1 | PAY-03 | service | `rails test test/services/carts/finalize_test.rb` | ❌ W0 | ⬜ pending |
| 20-01-03 | 01 | 1 | PAY-03 | integration | `rails test test/integration/cart_checkout_orders_test.rb` | ❌ W0 | ⬜ pending |
| 20-02-01 | 02 | 2 | PAY-03 | model | `rails test test/models/seller_receivable_test.rb` | ❌ W0 | ⬜ pending |
| 20-02-02 | 02 | 2 | PAY-03 | service | `rails test test/services/seller_receivables/read_summary_test.rb` | ❌ W0 | ⬜ pending |
| 20-02-03 | 02 | 2 | PAY-03 | regression | `rails test test/services/carts/finalize_test.rb test/services/seller_receivables/read_summary_test.rb test/integration/cart_checkout_orders_test.rb` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `marketplace_backend/test/models/checkout_group_test.rb` — invariantes do agrupador financeiro do checkout
- [ ] `marketplace_backend/test/models/seller_receivable_test.rb` — estados e vinculos do saldo a receber do seller
- [ ] `marketplace_backend/test/services/seller_receivables/read_summary_test.rb` — total pendente e lista por pedido

---

## Manual-Only Verifications

All planned Phase 20 behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 90s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
