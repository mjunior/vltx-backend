---
phase: 22
slug: seller-finance-surface-contestation-and-ratings
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-03-10
---

# Phase 22 — Validation Strategy

> Per-phase validation contract for seller finance, contestation, and delivered-only ratings.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Minitest (Rails 8) |
| **Config file** | `marketplace_backend/test/test_helper.rb` |
| **Quick run command** | `cd marketplace_backend && RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test test/services/seller_finance/read_summary_test.rb test/services/orders/contest_test.rb test/services/ratings/create_for_order_item_test.rb` |
| **Full suite command** | `cd marketplace_backend && RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test` |
| **Estimated runtime** | ~180 seconds |

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
| 22-01-01 | 01 | 1 | PAY-05 | service | `rails test test/services/seller_finance/read_summary_test.rb` | ❌ W0 | ⬜ pending |
| 22-01-02 | 01 | 1 | PAY-05 | integration | `rails test test/integration/seller_finance_test.rb` | ❌ W0 | ⬜ pending |
| 22-02-01 | 02 | 2 | ORD-06 | service | `rails test test/services/orders/contest_test.rb` | ❌ W0 | ⬜ pending |
| 22-02-02 | 02 | 2 | ORD-06 | integration | `rails test test/integration/orders_contest_test.rb` | ❌ W0 | ⬜ pending |
| 22-03-01 | 03 | 3 | RATE-01, RATE-02 | model | `rails test test/models/product_rating_test.rb test/models/seller_rating_test.rb` | ❌ W0 | ⬜ pending |
| 22-03-02 | 03 | 3 | RATE-01, RATE-02 | service | `rails test test/services/ratings/create_for_order_item_test.rb` | ❌ W0 | ⬜ pending |
| 22-03-03 | 03 | 3 | RATE-01, RATE-02 | integration | `rails test test/integration/order_item_ratings_test.rb` | ❌ W0 | ⬜ pending |
| 22-03-04 | 03 | 3 | all phase reqs | regression | `rails test test/services/seller_finance/read_summary_test.rb test/services/orders/contest_test.rb test/services/ratings/create_for_order_item_test.rb test/integration/seller_finance_test.rb test/integration/orders_contest_test.rb test/integration/order_item_ratings_test.rb` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ partial/flaky*

---

## Wave 0 Requirements

- [ ] `marketplace_backend/test/services/seller_finance/read_summary_test.rb` — seller pending/credited totals and tenant isolation
- [ ] `marketplace_backend/test/integration/seller_finance_test.rb` — seller finance HTTP surface
- [ ] `marketplace_backend/test/services/orders/contest_test.rb` — delivered-only contest guard
- [ ] `marketplace_backend/test/models/product_rating_test.rb` — product rating uniqueness and score bounds
- [ ] `marketplace_backend/test/models/seller_rating_test.rb` — seller rating uniqueness and score bounds
- [ ] `marketplace_backend/test/services/ratings/create_for_order_item_test.rb` — atomic write of product and seller ratings

---

## Manual-Only Verifications

All planned phase behaviors should have automated coverage.

---

## Validation Sign-Off

- [x] All tasks have automated verification targets
- [x] Sampling continuity avoids long unchecked streaks
- [x] Wave 0 covers all missing files introduced by the plans
- [x] Full-suite gate retained
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
