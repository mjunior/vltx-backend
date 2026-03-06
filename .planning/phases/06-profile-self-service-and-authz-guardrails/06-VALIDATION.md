---
phase: 6
slug: profile-self-service-and-authz-guardrails
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-06
---

# Phase 6 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Minitest (Rails test) |
| **Config file** | `marketplace_backend/test/test_helper.rb` |
| **Quick run command** | `RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test test/integration/profile_update_test.rb test/services/profiles/update_profile_test.rb` |
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
| 06-01-01 | 01 | 1 | PROF-03 | integration | `rails test test/integration/profile_update_test.rb` | ❌ W0 | ⬜ pending |
| 06-01-02 | 01 | 1 | AUTHZ-04 | integration | `rails test test/integration/profile_update_test.rb` | ❌ W0 | ⬜ pending |
| 06-01-03 | 01 | 1 | AUTHZ-01 | service/integration | `rails test test/services/profiles/update_profile_test.rb test/integration/profile_update_test.rb` | ❌ W0 | ⬜ pending |
| 06-02-01 | 02 | 2 | AUTHZ-01 | integration | `rails test test/integration/profile_update_test.rb` | ❌ W0 | ⬜ pending |
| 06-02-02 | 02 | 2 | PROF-03 | integration | `rails test test/integration/profile_update_test.rb` | ❌ W0 | ⬜ pending |

---

## Wave 0 Requirements

- [ ] `marketplace_backend/test/integration/profile_update_test.rb`
- [ ] `marketplace_backend/test/services/profiles/update_profile_test.rb`

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
