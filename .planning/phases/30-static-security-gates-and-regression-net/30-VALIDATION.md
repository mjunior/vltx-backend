---
phase: 30
slug: static-security-gates-and-regression-net
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-03-11
---

# Phase 30 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Minitest (Rails 8) + shell/CI workflow validation |
| **Config file** | `marketplace_backend/test/test_helper.rb`, `marketplace_backend/config/ci.rb` |
| **Quick run command** | `cd marketplace_backend && DATABASE_URL=postgresql://localhost/marketplace_backend_test RBENV_VERSION=3.3.0 rbenv exec ./bin/security-regression` |
| **Full suite command** | `cd marketplace_backend && DATABASE_URL=postgresql://localhost/marketplace_backend_test PARALLEL_WORKERS=1 RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test` |
| **Estimated runtime** | ~120 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick command plus the relevant bin/workflow smoke command
- **After every plan wave:** Run full suite command
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 30-01-01 | 01 | 1 | SEC-03 | shell | `RBENV_VERSION=3.3.0 rbenv exec ./bin/security` | ❌ W0 | ⬜ pending |
| 30-01-02 | 01 | 1 | SEC-03 | workflow/config | `ruby -c .github/workflows/ci.yml` | ❌ W0 | ⬜ pending |
| 30-02-01 | 02 | 2 | SEC-04 | shell/integration | `RBENV_VERSION=3.3.0 rbenv exec ./bin/security-regression` | ❌ W0 | ⬜ pending |
| 30-02-02 | 02 | 2 | SEC-03, SEC-04 | regression | `DATABASE_URL=postgresql://localhost/marketplace_backend_test PARALLEL_WORKERS=1 RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `marketplace_backend/bin/security` — fail-closed static security gate
- [ ] `marketplace_backend/bin/security-regression` — grouped hardening regression command
- [ ] `.github/workflows/ci.yml` — repository workflow executing the shared entrypoints

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Repository workflow appears and can be enabled in the hosting provider | SEC-03 | Depends on remote Git host, branch protection, and repo settings | Push branch, confirm CI workflow is discovered and executes on pull request or push |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
