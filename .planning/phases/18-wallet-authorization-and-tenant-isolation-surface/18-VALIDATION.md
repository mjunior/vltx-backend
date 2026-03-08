---
phase: 18
slug: wallet-authorization-and-tenant-isolation-surface
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-03-08
---

# Phase 18 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Minitest (Rails 8) |
| **Config file** | `marketplace_backend/test/test_helper.rb` |
| **Quick run command** | `cd marketplace_backend && RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test test/integration/wallet_authorization_test.rb test/services/wallets/read/fetch_statement_test.rb` |
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
| 18-01-01 | 01 | 1 | AUTHZ-08 | integration | `rails test test/integration/wallet_authorization_test.rb` | ❌ W0 | ⬜ pending |
| 18-01-02 | 01 | 1 | AUTHZ-08 | service | `rails test test/services/wallets/read/fetch_statement_test.rb` | ❌ W0 | ⬜ pending |
| 18-01-03 | 01 | 1 | AUTHZ-09 | integration | `rails test test/integration/wallet_authorization_test.rb` | ❌ W0 | ⬜ pending |
| 18-02-01 | 02 | 2 | AUTHZ-09 | integration | `rails test test/integration/wallet_authorization_test.rb` | ❌ W0 | ⬜ pending |
| 18-02-02 | 02 | 2 | AUTHZ-08 | integration | `rails test test/integration/wallet_authorization_test.rb` | ❌ W0 | ⬜ pending |
| 18-02-03 | 02 | 2 | AUTHZ-08, AUTHZ-09 | regression | `rails test test/integration/wallet_authorization_test.rb test/services/wallets/read/fetch_statement_test.rb` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `marketplace_backend/test/integration/wallet_authorization_test.rb` — auth/token/tenant-isolation dos endpoints de wallet
- [ ] `marketplace_backend/test/services/wallets/read/fetch_statement_test.rb` — contrato fixo de ultimas 30 transacoes e campos expostos

---

## Manual-Only Verifications

All planned Phase 18 behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 90s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
