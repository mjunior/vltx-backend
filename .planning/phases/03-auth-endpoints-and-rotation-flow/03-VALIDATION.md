---
phase: 3
slug: auth-endpoints-and-rotation-flow
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-06
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Minitest (Rails test) |
| **Config file** | `marketplace_backend/test/test_helper.rb` |
| **Quick run command** | `RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test test/integration/auth_signup_test.rb test/integration/auth_login_test.rb test/integration/auth_refresh_test.rb test/services/auth/sessions/rotation_test.rb` |
| **Full suite command** | `RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test` |
| **Estimated runtime** | ~30-60 seconds |

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
| 03-01-01 | 01 | 1 | AUTH-03 | integration | `rails test test/integration/auth_signup_test.rb` | ⚠️ partial | ⬜ pending |
| 03-02-01 | 02 | 1 | AUTH-02 | integration | `rails test test/integration/auth_login_test.rb` | ❌ W0 | ⬜ pending |
| 03-02-02 | 02 | 1 | AUTH-04 | integration | `rails test test/integration/auth_login_test.rb` | ❌ W0 | ⬜ pending |
| 03-03-01 | 03 | 2 | SESS-02 | integration | `rails test test/integration/auth_refresh_test.rb` | ❌ W0 | ⬜ pending |
| 03-03-02 | 03 | 2 | SESS-03 | service | `rails test test/services/auth/sessions/rotation_test.rb` | ❌ W0 | ⬜ pending |

---

## Wave 0 Requirements

- [ ] `marketplace_backend/test/integration/auth_login_test.rb`
- [ ] `marketplace_backend/test/integration/auth_refresh_test.rb`
- [ ] `marketplace_backend/test/services/auth/sessions/rotation_test.rb`

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Nenhum | - | Todos comportamentos críticos devem ser automatizados | - |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependency
- [ ] Sampling continuity maintained
- [ ] Wave 0 covers missing tests
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
