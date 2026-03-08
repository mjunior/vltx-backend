---
phase: 17
slug: idempotency-and-refund-deduplication
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-03-08
---

# Phase 17 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Minitest (Rails 8) |
| **Config file** | `marketplace_backend/test/test_helper.rb` |
| **Quick run command** | `cd marketplace_backend && RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test test/services/wallets/ledger/append_transaction_test.rb test/services/wallets/operations/apply_movement_test.rb` |
| **Full suite command** | `cd marketplace_backend && RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test` |
| **Estimated runtime** | ~120 seconds |

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
| 17-01-01 | 01 | 1 | IDEMP-01 | service | `rails test test/services/wallets/ledger/append_transaction_test.rb` | ✅ | ⬜ pending |
| 17-01-02 | 01 | 1 | WAL-05 | service | `rails test test/services/wallets/ledger/append_transaction_test.rb` | ✅ | ⬜ pending |
| 17-01-03 | 01 | 1 | IDEMP-01 | service | `rails test test/services/wallets/operations/apply_movement_test.rb` | ✅ | ⬜ pending |
| 17-02-01 | 02 | 2 | IDEMP-02 | service | `rails test test/services/wallets/ledger/append_transaction_test.rb` | ✅ | ⬜ pending |
| 17-02-02 | 02 | 2 | IDEMP-01, WAL-05 | service | `rails test test/services/wallets/operations/apply_movement_test.rb` | ✅ | ⬜ pending |
| 17-02-03 | 02 | 2 | WAL-05, IDEMP-01, IDEMP-02 | regression | `rails test test/services/wallets/ledger/append_transaction_test.rb test/services/wallets/operations/apply_movement_test.rb test/integration/cart_checkout_wallet_safety_test.rb` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

All planned Phase 17 behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 90s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
