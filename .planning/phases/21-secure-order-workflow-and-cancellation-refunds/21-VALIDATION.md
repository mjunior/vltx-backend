---
phase: 21
slug: secure-order-workflow-and-cancellation-refunds
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-03-10
---

# Phase 21 — Validation Strategy

> Per-phase validation contract for workflow, refund, stock, and seller-credit side effects.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Minitest (Rails 8) |
| **Config file** | `marketplace_backend/test/test_helper.rb` |
| **Quick run command** | `cd marketplace_backend && RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test test/models/order_transition_test.rb test/services/orders/apply_transition_test.rb test/services/orders/cancel_test.rb test/services/orders/mark_delivered_test.rb` |
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
| 21-01-01 | 01 | 1 | ORD-07 | model | `rails test test/models/order_transition_test.rb` | ❌ W0 | ⬜ pending |
| 21-01-02 | 01 | 1 | ORD-03 | service | `rails test test/services/orders/apply_transition_test.rb` | ❌ W0 | ⬜ pending |
| 21-01-03 | 01 | 1 | ORD-07 | regression | `rails test test/models/order_test.rb test/services/orders/apply_transition_test.rb` | ⚠️ partial | ⬜ pending |
| 21-02-01 | 02 | 2 | ORD-04, PAY-04, INV-02 | service | `rails test test/services/orders/cancel_test.rb` | ❌ W0 | ⬜ pending |
| 21-02-02 | 02 | 2 | ORD-05 | service | `rails test test/services/orders/mark_delivered_test.rb` | ❌ W0 | ⬜ pending |
| 21-02-03 | 02 | 2 | ORD-03, ORD-04, ORD-05 | integration | `rails test test/integration/orders_actions_test.rb` | ❌ W0 | ⬜ pending |
| 21-03-01 | 03 | 3 | PAY-04, INV-02 | concurrency | `rails test test/services/orders/cancel_idempotency_test.rb` | ❌ W0 | ⬜ pending |
| 21-03-02 | 03 | 3 | ORD-07 | negative | `rails test test/integration/orders_action_guards_test.rb` | ❌ W0 | ⬜ pending |
| 21-03-03 | 03 | 3 | all phase reqs | regression | `rails test test/services/orders test/integration/orders_actions_test.rb test/integration/orders_action_guards_test.rb` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ partial/flaky*

---

## Wave 0 Requirements

- [ ] `marketplace_backend/test/models/order_transition_test.rb` — invariantes do log de transicao auditavel
- [ ] `marketplace_backend/test/services/orders/apply_transition_test.rb` — avancos permitidos e proibidos por ator
- [ ] `marketplace_backend/test/services/orders/cancel_test.rb` — refund, reversao de recebivel e restauracao de estoque
- [ ] `marketplace_backend/test/services/orders/mark_delivered_test.rb` — credito seller e mudanca de recebivel
- [ ] `marketplace_backend/test/integration/orders_actions_test.rb` — surface HTTP de acoes seguras

---

## Manual-Only Verifications

All planned phase behaviors should have automated coverage. No manual-only checks are expected.

---

## Validation Sign-Off

- [x] All tasks have automated verification targets
- [x] Sampling continuity avoids long unchecked streaks
- [x] Wave 0 lists all missing test files required by the plans
- [x] Full-suite gate retained before phase completion
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
