---
phase: 10
slug: public-product-detail-and-safe-serialization
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-03-06
---

# Phase 10 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Minitest (Rails test) |
| **Config file** | `marketplace_backend/test/test_helper.rb` |
| **Quick run command** | `RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test test/integration/public_product_show_test.rb test/services/products/public_product_detail_test.rb test/serializers/products/public_product_detail_serializer_test.rb` |
| **Full suite command** | `RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test` |
| **Estimated runtime** | ~40-120 seconds |

---

## Sampling Rate

- **After every task commit:** Run `RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test test/integration/public_product_show_test.rb test/services/products/public_product_detail_test.rb test/serializers/products/public_product_detail_serializer_test.rb`
- **After every plan wave:** Run `RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 10-01-01 | 01 | 1 | PUB-05 | integration | `rails test test/integration/public_product_show_test.rb` | ✅ | ✅ green |
| 10-01-02 | 01 | 1 | PUB-05 | service | `rails test test/services/products/public_product_detail_test.rb` | ✅ | ✅ green |
| 10-02-01 | 02 | 2 | PUB-06 | serializer/integration | `rails test test/serializers/products/public_product_detail_serializer_test.rb test/integration/public_product_show_test.rb` | ✅ | ✅ green |
| 10-02-02 | 02 | 2 | PUB-05, PUB-06 | integration | `rails test test/integration/public_product_show_test.rb test/services/products/public_product_detail_test.rb test/serializers/products/public_product_detail_serializer_test.rb` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `marketplace_backend/test/integration/public_product_show_test.rb`
- [x] `marketplace_backend/test/services/products/public_product_detail_test.rb`
- [x] `marketplace_backend/test/serializers/products/public_product_detail_serializer_test.rb`

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Nenhum | - | Escopo coberto por integração/serviço/serializer | - |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-03-06
