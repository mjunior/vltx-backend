---
phase: 11
slug: cart-foundation-and-active-cart-invariant
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-03-07
---

# Phase 11 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Minitest (Rails 8) |
| **Config file** | `marketplace_backend/test/test_helper.rb` |
| **Quick run command** | `cd marketplace_backend && RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test test/integration/cart_upsert_test.rb test/services/carts/find_or_create_active_test.rb` |
| **Full suite command** | `cd marketplace_backend && RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test` |
| **Estimated runtime** | ~45 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick command
- **After every plan wave:** Run full suite command
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 11-01-01 | 01 | 1 | CART-01, AUTHZ-05 | integration | `rails test test/integration/cart_upsert_test.rb` | ❌ W0 | ⬜ pending |
| 11-01-02 | 01 | 1 | CART-01 | service | `rails test test/services/carts/find_or_create_active_test.rb` | ❌ W0 | ⬜ pending |
| 11-02-01 | 02 | 2 | CART-02 | service | `rails test test/services/carts/find_or_create_active_test.rb` | ❌ W0 | ⬜ pending |
| 11-02-02 | 02 | 2 | AUTHZ-06 | integration | `rails test test/integration/cart_authorization_test.rb` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `marketplace_backend/test/integration/cart_upsert_test.rb` — contratos HTTP do carrinho ativo
- [ ] `marketplace_backend/test/integration/cart_authorization_test.rb` — isolamento tenant/cross-tenant
- [ ] `marketplace_backend/test/services/carts/find_or_create_active_test.rb` — idempotência e corrida de criação

---

## Manual-Only Verifications

All planned Phase 11 behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
