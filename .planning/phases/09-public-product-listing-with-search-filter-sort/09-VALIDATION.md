---
phase: 9
slug: public-product-listing-with-search-filter-sort
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-06
---

# Phase 9 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Minitest (Rails test) |
| **Config file** | `marketplace_backend/test/test_helper.rb` |
| **Quick run command** | `RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test test/integration/public_products_index_test.rb test/services/products/public_listing_test.rb` |
| **Full suite command** | `RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test` |
| **Estimated runtime** | ~40-120 seconds |

---

## Sampling Rate

- **After every task commit:** Run `RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test test/integration/public_products_index_test.rb test/services/products/public_listing_test.rb`
- **After every plan wave:** Run `RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 09-01-01 | 01 | 1 | PUB-01 | integration | `rails test test/integration/public_products_index_test.rb` | ❌ W0 | ⬜ pending |
| 09-01-02 | 01 | 1 | PUB-02 | service/integration | `rails test test/services/products/public_listing_test.rb test/integration/public_products_index_test.rb` | ❌ W0 | ⬜ pending |
| 09-01-03 | 01 | 1 | PUB-03 | integration | `rails test test/integration/public_products_index_test.rb` | ❌ W0 | ⬜ pending |
| 09-02-01 | 02 | 2 | PUB-04 | integration | `rails test test/integration/public_products_index_test.rb` | ❌ W0 | ⬜ pending |
| 09-02-02 | 02 | 2 | PUB-01 | integration | `rails test test/integration/public_products_index_test.rb test/services/products/public_listing_test.rb` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `marketplace_backend/test/integration/public_products_index_test.rb`
- [ ] `marketplace_backend/test/services/products/public_listing_test.rb`

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Nenhum | - | Escopo deve ser coberto por integração/serviço | - |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
