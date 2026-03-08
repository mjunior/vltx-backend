# Marketplace Backend

## What This Is

API backend em Rails 8 para autenticação JWT segura, gestão de perfil do usuário, domínio de produtos, carrinho e carteira financeira em ledger append-only.

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
- ✓ Carteira em ledger append-only com `balance_after` e centavos inteiros — v1.3
- ✓ Movimentação segura com lock, não-negativação e anti-fraude server-side — v1.3
- ✓ Idempotência de operação e deduplicação de refund sob corrida/retry — v1.3
- ✓ Surface de wallet com isolamento tenant e authz por token (`GET /wallet`, `GET /wallet/transactions`) — v1.3

### Active

- [ ] Persistir `Order` no checkout com snapshot de itens e totais (`ORD-01`)
- [ ] Integrar ledger financeiro por `order_id` ponta a ponta (`ORD-02`)
- [ ] Suportar estado de pedido com cancelamento e refund automático de pedido pago (`ORD-03` + Req 21)
- [ ] Entregar painel seller com saldo a receber e histórico financeiro de pedidos (Req 22)

### Out of Scope

- Login social (OAuth)
- Password reset / email verification
- MFA/2FA neste ciclo

## Current Milestone: v1.4 Orders and Settlement Foundation (planned)

**Goal:** Evoluir checkout para criação de pedido persistido e iniciar trilha financeira buyer/seller baseada em `order_id`.

## Current State

- **Shipped versions:** v1.0, v1.1, v1.2, v1.3
- **Current milestone:** none (v1.4 pendente de abertura)
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
| Ledger de carteira append-only com lock por operação | Priorizar integridade financeira sobre simplicidade | ✓ Good (v1.3) |
| Extrato de wallet hardcoded em últimas 30 transações | Simplicidade e previsibilidade com superfície mínima inicial | ✓ Good (v1.3) |

## Next Milestone Goals

1. Criar `Order` persistido no checkout com snapshot completo.
2. Vincular movimentações financeiras a `order_id` (buyer/seller) com rastreabilidade fim a fim.
3. Implementar cancelamento de pedido pago com refund automático idempotente.
4. Expor visão financeira do seller (saldo a receber e histórico de transações de pedidos).

---
*Last updated: 2026-03-08 after completing v1.3 milestone*
