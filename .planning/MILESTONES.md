# Milestones

## v1.3 Wallet Ledger Hardening (Shipped: 2026-03-08)

**Scope delivered:**
- 4 phases
- 8 plans
- 24 tasks
- Timeline: 2026-03-07 -> 2026-03-08
- Git range: `0dab28c` -> `1accc0d`
- Diff summary: 44 files changed, 2983 insertions(+), 50 deletions(-)

**Key accomplishments:**
1. Wallet e ledger append-only com invariantes de centavos, `balance_after_cents` e proteção contra `UPDATE/DELETE`.
2. Engine transacional de movimentação com lock de wallet, bloqueio de saldo negativo e fail-closed em inconsistência.
3. Idempotência forte por `operation_key` com conflito determinístico para payload divergente.
4. Deduplicação de refund por referência de negócio com guarda determinística no banco e no service.
5. Cobertura de concorrência/retry comprovando no máximo uma movimentação efetiva por operação lógica.
6. Endpoints de leitura de wallet (`GET /wallet`, `GET /wallet/transactions`) com isolamento tenant e extrato fixo de 30 transações.

**Known tech debt accepted:**
- Persistência de pedido e trilha financeira por `order_id` (ORD-01/02/03) ficou para o próximo milestone.
- Sem paginação/filtros no extrato de wallet (limite hardcoded em 30 por decisão inicial).

**Archives:**
- `.planning/milestones/v1.3-ROADMAP.md`
- `.planning/milestones/v1.3-REQUIREMENTS.md`

---

## v1.2 Cart and Checkout Foundation (Shipped: 2026-03-07)

**Scope delivered:**
- 4 phases
- 9 plans
- 27 tasks
- Timeline: 2026-03-07 -> 2026-03-07

**Key accomplishments:**
1. Invariante de um único carrinho `active` por usuário autenticado com isolamento tenant estrito.
2. Operações completas de item (`POST/PATCH/DELETE /cart/items`) com validação server-side de `product_id`, `quantity` e preço derivado do banco.
3. Hardening de estado com bloqueio de mutações em carrinhos `finished/abandoned` e resposta de erro consistente.
4. Proteção anti-abuso para tentativas repetidas em carrinhos inativos com revogação de sessões de refresh.
5. Checkout (`POST /cart/checkout`) com pagamento exclusivo por carteira e transição segura `active -> finished`.
6. Service `Orders::PrepareFromCart` integrado ao checkout para preparação de pedido sem persistência de `Order` neste milestone.

**Known tech debt accepted:**
- Persistência real de pedido/ledger (`ORD-01..03`) adiada para próximo milestone.

**Archives:**
- `.planning/milestones/v1.2-ROADMAP.md`
- `.planning/milestones/v1.2-REQUIREMENTS.md`

---

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
