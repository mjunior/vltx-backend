# Milestones

## v1.1 Profile and Catalog (Shipped: 2026-03-06)

**Scope delivered:**
- 5 phases
- 11 plans
- 33 tasks
- Timeline: 2026-03-06 -> 2026-03-06
- Git range: `6a3e801` -> `a0fd0cb`

**Key accomplishments:**
1. Self-service profile update (`PATCH /profile`) with strict token-derived identity and multi-tenant protection.
2. Seller product domain shipped with secure ownership derivation and forged owner payload rejection.
3. Full seller lifecycle (update/deactivate/soft-delete) with 404 ownership masking and idempotent deactivate route.
4. Public catalog listing (`GET /public/products`) with safe visibility filters, search, price range, and deterministic sorting.
5. Public product detail (`GET /public/products/:id`) with dedicated safe serializer, 404 anti-enumeration masking, and stock integrity check constraint.

**Known tech debt accepted:**
- Nyquist validation artifacts (`*-VALIDATION.md`) for phases 06-09 remain `draft` with `nyquist_compliant: false`.

**Archives:**
- `.planning/milestones/v1.1-ROADMAP.md`
- `.planning/milestones/v1.1-REQUIREMENTS.md`
- `.planning/milestones/v1.1-MILESTONE-AUDIT.md`

---

## v1.0 Milestone (Shipped: 2026-03-06)

**Name:** Milestone

**Scope delivered:**
- 5 phases
- 12 plans
- 36 tasks
- Timeline: 2026-03-05 -> 2026-03-06
- Git range: `d32c829` -> `a288f1c`

**Key accomplishments:**
1. User/Profile foundation with secure password storage and normalized unique email.
2. JWT core with separate access/refresh secrets, required `jti`, and strict verification.
3. Signup/login/refresh endpoints with one-time refresh rotation and consistent token-pair contract.
4. Global logout and refresh-reuse incident containment via global session revocation.
5. Final hardening with expanded auth security matrix and resilient incident logging.

**Known tech debt accepted:**
- Nyquist validation artifacts (`*-VALIDATION.md`) remain in `draft` with `nyquist_compliant: false`.

**Archives:**
- `.planning/milestones/v1.0-ROADMAP.md`
- `.planning/milestones/v1.0-REQUIREMENTS.md`
- `.planning/milestones/v1.0-MILESTONE-AUDIT.md`

---
