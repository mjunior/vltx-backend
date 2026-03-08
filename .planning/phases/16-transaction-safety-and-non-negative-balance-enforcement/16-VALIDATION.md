---
phase: 16
slug: transaction-safety-and-non-negative-balance-enforcement
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-03-08
---

# Phase 16 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Minitest (Rails 8) |
| **Config file** | `marketplace_backend/test/test_helper.rb` |
| **Quick run command** | `cd marketplace_backend && RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test test/services/wallets/ledger/append_transaction_test.rb test/services/wallets/operations/apply_movement_test.rb` |
| **Full suite command** | `cd marketplace_backend && RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test` |
| **Estimated runtime** | ~100 seconds |

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
| 16-01-01 | 01 | 1 | WAL-06 | service | `rails test test/services/wallets/operations/apply_movement_test.rb` | ❌ W0 | ⬜ pending |
| 16-01-02 | 01 | 1 | WAL-07 | service | `rails test test/services/wallets/operations/apply_movement_test.rb` | ❌ W0 | ⬜ pending |
| 16-01-03 | 01 | 1 | WAL-08 | service | `rails test test/services/wallets/operations/apply_movement_test.rb` | ❌ W0 | ⬜ pending |
| 16-02-01 | 02 | 2 | WAL-06, WAL-07 | regression | `rails test test/services/wallets/ledger/append_transaction_test.rb test/services/wallets/operations/apply_movement_test.rb` | ❌ W0 | ⬜ pending |
| 16-02-02 | 02 | 2 | WAL-08 | integration | `rails test test/integration/cart_checkout_wallet_safety_test.rb` | ❌ W0 | ⬜ pending |
| 16-02-03 | 02 | 2 | WAL-06..08 | regression | `rails test test/services/wallets/ledger/append_transaction_test.rb test/services/wallets/operations/apply_movement_test.rb test/integration/cart_checkout_wallet_safety_test.rb` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `marketplace_backend/test/services/wallets/operations/apply_movement_test.rb` — lock/saldo/validação de fonte confiável
- [ ] `marketplace_backend/test/integration/cart_checkout_wallet_safety_test.rb` — contrato anti-fraude no boundary HTTP

---

## Manual-Only Verifications

All planned Phase 16 behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 90s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
