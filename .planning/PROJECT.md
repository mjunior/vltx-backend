# Marketplace Backend

## What This Is

API backend em Rails 8 para autenticação JWT segura, gestão de perfil do usuário, domínio de produtos e jornada de compra com carrinho. O foco atual evolui checkout para criação de pedido com débito real de carteira em modelo ledger, priorizando segurança transacional e isolamento multi-tenant.

## Core Value

Isolamento multi-tenant estrito com contratos de autenticação e catálogo previsíveis.

## Requirements

### Validated

- ✓ Cadastro e login com email/senha — v1.0
- ✓ Access token (15 min) + refresh token (7 dias) com segredos distintos — v1.0
- ✓ Refresh token rotativo one-time com proteção contra replay — v1.0
- ✓ Logout global com revogação por `jti` — v1.0
- ✓ Relação `User has_one Profile` com separação de credenciais e perfil — v1.0
- ✓ Edição de perfil próprio (`PATCH /profile`) — v1.1
- ✓ CRUD privado de produtos com ownership derivado do token — v1.1
- ✓ Listagem pública com busca/faixa/sort (`GET /public/products`) — v1.1
- ✓ Detalhe público seguro (`GET /public/products/:id`) com serializer dedicado — v1.1
- ✓ Carrinho ativo único por usuário autenticado com isolamento tenant — v1.2
- ✓ Operações de item com validação server-side, transação e anti-fraude — v1.2
- ✓ Guardas de estado para carrinhos `finished`/`abandoned` com prevenção de abuso — v1.2
- ✓ Checkout com `wallet` only e transição segura para `finished` — v1.2
- ✓ Service de preparação de pedido sem persistência de `Order` (foundation) — v1.2

### Active

- [ ] Criar carteira em modelo ledger append-only (transactions insert-only com `balance_after`)
- [ ] Garantir débito/crédito/reembolso idempotentes e seguros contra corrida, sem saldo negativo
- [ ] Restringir visibilidade/operação da carteira ao próprio usuário autenticado

### Out of Scope

- Login social (OAuth)
- Password reset / email verification
- MFA/2FA neste ciclo

## Current Milestone: v1.3 Wallet Ledger Hardening

**Goal:** Implementar carteira com ledger append-only e garantias fortes de segurança transacional e isolamento por usuário.

**Target features:**
- Tabela de transações de carteira com tipos `credit`, `debit`, `refund`, `balance_after` e bloqueio a reembolso duplicado.
- Operações financeiras com lock, idempotência e proteção contra race conditions.
- Regras server-side para valores em centavos, validação anti-fraude e proibição de saldo negativo.

## Current State

- **Shipped versions:** v1.0, v1.1, v1.2
- **Current milestone:** v1.3 Wallet Ledger Hardening
- **Stack:** Rails API-only 8.0.4, Ruby 3.3.0, PostgreSQL, gem `jwt`

## Constraints

- Toda autorização de recursos privados usa usuário derivado do token.
- Endpoints privados exigem autenticação.
- Endpoints públicos não expõem dados sensíveis.
- Operações de carteira nunca confiam em valores enviados pelo frontend.
- Ledger de carteira é append-only: sem `UPDATE`/`DELETE` em transações.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| JWT com `jti` e revogação por sessão | Controle explícito de sessão | ✓ Good (v1.0) |
| Refresh one-time rotativo com resposta a reuse | Mitigar replay de refresh token | ✓ Good (v1.0) |
| Ownership sempre derivado do token | Bloquear spoofing via frontend | ✓ Good (v1.1) |
| Catálogo público em `/public` com serializer dedicado | Evitar vazamento e estabilizar contrato | ✓ Good (v1.1) |
| Detalhe público com máscara uniforme de 404 | Reduzir enumeração de recursos | ✓ Good (v1.1) |
| Carrinho só aceita dados críticos validados no backend | Evitar fraude/abuso de payload manipulável | ✓ Good (v1.2) |
| Um carrinho ativo por usuário | Simplificar checkout e reduzir abuso por multiplicação de carrinhos | ✓ Good (v1.2) |
| Checkout `wallet` only com finalização atômica | Garantir caminho de pagamento mínimo seguro antes de persistir pedidos | ✓ Good (v1.2) |
| Preparação de pedido sem persistência nesta etapa | Permitir evolução incremental para ORD-01..03 | ✓ Good (v1.2) |
| Ledger de carteira append-only com lock por operação | Priorizar integridade financeira sobre simplicidade | — Pending (v1.3) |

## Next Milestone Goals

1. Criar modelo de carteira e transações com trilha imutável de saldo em centavos.
2. Implementar motor de movimentação (crédito/débito/reembolso) com lock e idempotência forte.
3. Integrar segurança de autorização para impedir qualquer acesso a carteira de terceiros.

---
*Last updated: 2026-03-07 after starting v1.3 milestone*
