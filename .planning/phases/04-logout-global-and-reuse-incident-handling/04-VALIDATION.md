---
phase: 4
slug: logout-global-and-reuse-incident-handling
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-06
---

# Phase 4 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Minitest (Rails test) |
| **Config file** | `marketplace_backend/test/test_helper.rb` |
| **Quick run command** | `RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test test/integration/auth_logout_test.rb test/integration/auth_reuse_incident_test.rb test/services/auth/sessions/revocation_test.rb` |
| **Full suite command** | `RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test` |
| **Estimated runtime** | ~25-50 seconds |

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
| 04-01-01 | 01 | 1 | SESS-05 | integration | `rails test test/integration/auth_logout_test.rb` | ❌ W0 | ⬜ pending |
| 04-01-02 | 01 | 1 | SESS-05 | integration | `rails test test/integration/auth_logout_test.rb` | ❌ W0 | ⬜ pending |
| 04-02-01 | 02 | 2 | SESS-04 | integration | `rails test test/integration/auth_reuse_incident_test.rb` | ❌ W0 | ⬜ pending |
| 04-02-02 | 02 | 2 | SESS-04 | service | `rails test test/services/auth/sessions/revocation_test.rb` | ✅ | ⬜ pending |

---

## Wave 0 Requirements

- [ ] `marketplace_backend/test/integration/auth_logout_test.rb`
- [ ] `marketplace_backend/test/integration/auth_reuse_incident_test.rb`

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Nenhum | - | Cobertura automatizada planejada para todo escopo da fase | - |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependency
- [ ] Sampling continuity maintained
- [ ] Wave 0 covers missing tests
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
