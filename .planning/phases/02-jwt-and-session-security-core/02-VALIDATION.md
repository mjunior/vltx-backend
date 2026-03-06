---
phase: 2
slug: jwt-and-session-security-core
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-06
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Minitest (Rails test) |
| **Config file** | `marketplace_backend/test/test_helper.rb` |
| **Quick run command** | `RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test test/models/refresh_session_test.rb test/services/auth/jwt test/services/auth/sessions` |
| **Full suite command** | `RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test` |
| **Estimated runtime** | ~20-45 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick suite command
- **After every plan wave:** Run full suite command
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 90 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 02-01-01 | 01 | 1 | AUTH-05 | service | `rails test test/services/auth/jwt` | ❌ W0 | ⬜ pending |
| 02-01-02 | 01 | 1 | SESS-06 | service | `rails test test/services/auth/jwt/verifier_test.rb` | ❌ W0 | ⬜ pending |
| 02-02-01 | 02 | 1 | SESS-01 | model | `rails test test/models/refresh_session_test.rb` | ❌ W0 | ⬜ pending |
| 02-03-01 | 03 | 2 | SESS-06 | service | `rails test test/services/auth/sessions` | ❌ W0 | ⬜ pending |

---

## Wave 0 Requirements

- [ ] `marketplace_backend/test/models/refresh_session_test.rb`
- [ ] `marketplace_backend/test/services/auth/jwt/issuer_test.rb`
- [ ] `marketplace_backend/test/services/auth/jwt/verifier_test.rb`
- [ ] `marketplace_backend/test/services/auth/sessions/revocation_test.rb`

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Boot fail-fast sem secrets/pepper | AUTH-05 | Envolve configuração de ambiente por processo | Iniciar app removendo cada ENV e confirmar erro no boot |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependency
- [ ] Sampling continuity maintained
- [ ] Wave 0 covers missing tests
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
