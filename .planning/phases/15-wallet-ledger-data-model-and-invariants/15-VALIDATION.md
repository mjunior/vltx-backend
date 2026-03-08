---
phase: 15
slug: wallet-ledger-data-model-and-invariants
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-03-07
---

# Phase 15 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Minitest (Rails 8) |
| **Config file** | `marketplace_backend/test/test_helper.rb` |
| **Quick run command** | `cd marketplace_backend && RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test test/models/wallet_test.rb test/models/wallet_transaction_test.rb test/services/wallets/ledger/append_transaction_test.rb` |
| **Full suite command** | `cd marketplace_backend && RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test` |
| **Estimated runtime** | ~90 seconds |

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
| 15-01-01 | 01 | 1 | WAL-01, WAL-04 | migration/model | `rails test test/models/wallet_test.rb` | ❌ W0 | ⬜ pending |
| 15-01-02 | 01 | 1 | WAL-01, WAL-02 | migration/model | `rails test test/models/wallet_transaction_test.rb` | ❌ W0 | ⬜ pending |
| 15-01-03 | 01 | 1 | WAL-01 | integrity | `rails test test/models/wallet_transaction_test.rb` | ❌ W0 | ⬜ pending |
| 15-02-01 | 02 | 2 | WAL-03 | service | `rails test test/services/wallets/ledger/append_transaction_test.rb` | ❌ W0 | ⬜ pending |
| 15-02-02 | 02 | 2 | WAL-03, WAL-04 | service | `rails test test/services/wallets/ledger/append_transaction_test.rb test/models/wallet_transaction_test.rb` | ❌ W0 | ⬜ pending |
| 15-02-03 | 02 | 2 | WAL-01..04 | regression | `rails test test/models/wallet_test.rb test/models/wallet_transaction_test.rb test/services/wallets/ledger/append_transaction_test.rb` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `marketplace_backend/test/models/wallet_test.rb` — invariantes de saldo materializado
- [ ] `marketplace_backend/test/models/wallet_transaction_test.rb` — tipos/centavos/append-only
- [ ] `marketplace_backend/test/services/wallets/ledger/append_transaction_test.rb` — cálculo de `balance_after_cents`

---

## Manual-Only Verifications

All planned Phase 15 behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 90s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
