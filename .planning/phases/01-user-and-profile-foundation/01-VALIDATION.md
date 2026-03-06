---
phase: 1
slug: user-and-profile-foundation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-05
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Minitest (Rails test) |
| **Config file** | `marketplace_backend/test/test_helper.rb` |
| **Quick run command** | `RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test test/models test/services` |
| **Full suite command** | `RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test` |
| **Estimated runtime** | ~15-30 seconds (current codebase) |

---

## Sampling Rate

- **After every task commit:** Run quick suite command
- **After every plan wave:** Run full suite command
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 01-01-01 | 01 | 1 | AUTH-01 | model | `rails test test/models/user_test.rb` | ❌ W0 | ⬜ pending |
| 01-01-02 | 01 | 1 | PROF-01 | model | `rails test test/models/profile_test.rb` | ❌ W0 | ⬜ pending |
| 01-02-01 | 02 | 2 | AUTH-01 | service | `rails test test/services/users/create_test.rb` | ❌ W0 | ⬜ pending |
| 01-02-02 | 02 | 2 | PROF-02 | integration | `rails test test/integration/auth_signup_test.rb` | ❌ W0 | ⬜ pending |

---

## Wave 0 Requirements

- [ ] `marketplace_backend/test/models/user_test.rb`
- [ ] `marketplace_backend/test/models/profile_test.rb`
- [ ] `marketplace_backend/test/services/users/create_test.rb`
- [ ] `marketplace_backend/test/integration/auth_signup_test.rb`

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Signup response wording (`cadastro inválido`) | AUTH-01 | Política de mensagem pública | Confirmar payload de erro via request test/manual curl |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependency
- [ ] Sampling continuity maintained
- [ ] Wave 0 covers missing tests
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
