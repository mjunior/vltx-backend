---
phase: 29
slug: production-security-posture
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-03-11
---

# Phase 29 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Minitest (Rails 8) |
| **Config file** | `marketplace_backend/test/test_helper.rb` |
| **Quick run command** | `cd marketplace_backend && DATABASE_URL=postgresql://localhost/marketplace_backend_test RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test test/integration/healthcheck_test.rb test/integration/profile_photo_upload_test.rb` |
| **Full suite command** | `cd marketplace_backend && DATABASE_URL=postgresql://localhost/marketplace_backend_test PARALLEL_WORKERS=1 RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test` |
| **Estimated runtime** | ~90 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick command plus any new production config tests
- **After every plan wave:** Run full suite command
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 90 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 29-01-01 | 01 | 1 | SEC-01 | config/integration | `rails test test/config/production_security_posture_test.rb` | ❌ W0 | ⬜ pending |
| 29-01-02 | 01 | 1 | SEC-01, SEC-02 | integration | `rails test test/config/production_security_posture_test.rb test/integration/healthcheck_test.rb` | ❌ W0 | ⬜ pending |
| 29-02-01 | 02 | 2 | SEC-01 | integration | `rails test test/integration/cors_security_test.rb` | ❌ W0 | ⬜ pending |
| 29-02-02 | 02 | 2 | SEC-02 | regression | `rails test test/config/production_security_posture_test.rb test/integration/cors_security_test.rb test/integration/healthcheck_test.rb` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `marketplace_backend/test/config/production_security_posture_test.rb` — config regression for SSL, hosts, env failure mode
- [ ] `marketplace_backend/test/integration/cors_security_test.rb` — allowed vs denied origins in production posture
- [ ] Existing infrastructure covers full-suite regression after these files are added

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Railway public domain stays routable after host/CORS hardening | SEC-02 | Depends on deployed hostnames and provider headers | Deploy to Railway, request `/up` and one API route through the generated public domain, confirm no host rejection |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 90s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
