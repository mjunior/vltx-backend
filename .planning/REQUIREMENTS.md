# Requirements: Marketplace Backend

**Defined:** 2026-03-05
**Core Value:** Garantir autenticação segura e previsível, com controle forte de sessão

## v1 Requirements

### Authentication

- [x] **AUTH-01**: User can sign up with email and password.
- [ ] **AUTH-02**: User can log in with valid email and password.
- [ ] **AUTH-03**: Login and signup return an access token with 15-minute expiration.
- [ ] **AUTH-04**: Login and signup return a refresh token with 7-day expiration.
- [ ] **AUTH-05**: Access and refresh tokens are signed with different JWT secrets.

### Session Security

- [ ] **SESS-01**: Refresh token is stored only as hash in persistence (never plaintext).
- [ ] **SESS-02**: Refresh token can be used only once and is rotated on successful refresh.
- [ ] **SESS-03**: Successful refresh invalidates previous refresh token and returns a new token pair.
- [ ] **SESS-04**: Using revoked/previously-used refresh token triggers global logout of all user sessions.
- [ ] **SESS-05**: Logout endpoint revokes all active sessions for the authenticated user.
- [ ] **SESS-06**: JWT payload includes `jti` and revocation checks are enforced in refresh/logout flows.

### User Profile

- [x] **PROF-01**: User has exactly one profile (`User has_one Profile`).
- [x] **PROF-02**: Profile stores personal data fields (full name, photo URL) separately from authentication credentials.

## v2 Requirements

### Security Enhancements

- **SECV2-01**: Add MFA/2FA for sensitive accounts.
- **SECV2-02**: Add per-device session management UX and selective session revoke.

## Out of Scope

| Feature | Reason |
|---------|--------|
| OAuth/social login | Not required for this milestone's core security scope |
| MFA/2FA | Deferred to v2 after core auth flow is validated |
| Password reset/email verification | Not requested in current milestone scope |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| AUTH-01 | Phase 1 | Complete |
| AUTH-02 | Phase 3 | Pending |
| AUTH-03 | Phase 3 | Pending |
| AUTH-04 | Phase 3 | Pending |
| AUTH-05 | Phase 2 | Pending |
| SESS-01 | Phase 2 | Pending |
| SESS-02 | Phase 3 | Pending |
| SESS-03 | Phase 3 | Pending |
| SESS-04 | Phase 4 | Pending |
| SESS-05 | Phase 4 | Pending |
| SESS-06 | Phase 2 | Pending |
| PROF-01 | Phase 1 | Complete |
| PROF-02 | Phase 1 | Complete |

**Coverage:**
- v1 requirements: 13 total
- Mapped to phases: 13
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-05*
*Last updated: 2026-03-06 after phase 1 execution*
