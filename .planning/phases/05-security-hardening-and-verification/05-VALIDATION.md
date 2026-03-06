---
phase: 5
slug: security-hardening-and-verification
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-06
---

# Phase 5 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Minitest (Rails test) |
| **Config file** | `marketplace_backend/test/test_helper.rb` |
| **Quick run command** | `RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test test/integration/auth_signup_test.rb test/integration/auth_login_test.rb test/integration/auth_refresh_test.rb test/integration/auth_logout_test.rb test/integration/auth_reuse_incident_test.rb test/services/auth/sessions/revocation_test.rb test/services/auth/sessions/rotation_test.rb` |
| **Full suite command** | `RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test` |
| **Estimated runtime** | ~30-70 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick suite command
- **After every plan wave:** Run full suite command
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 05-01-01 | 01 | 1 | AUTH-01..05 | integration | `rails test test/integration/auth_*_test.rb` | ✅ partial | ⬜ pending |
| 05-01-02 | 01 | 1 | SESS-01..06 | integration/service | `rails test test/integration/auth_*_test.rb test/services/auth/sessions/*_test.rb` | ✅ partial | ⬜ pending |
| 05-02-01 | 02 | 2 | cross-cutting v1 | full-suite | `rails test` | ✅ | ⬜ pending |
| 05-02-02 | 02 | 2 | cross-cutting v1 | verification | `rails test && verify report` | ✅ W0 | ⬜ pending |

---

## Wave 0 Requirements

- [ ] `marketplace_backend/test/integration/auth_security_matrix_test.rb` (if matrix consolidation is extracted)
- [ ] `marketplace_backend/test/support/auth_contract_assertions.rb` (optional helper)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Nenhum | - | Escopo da fase exige cobertura automatizada completa | - |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependency
- [ ] Sampling continuity maintained
- [ ] Wave 0 covers missing tests
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
