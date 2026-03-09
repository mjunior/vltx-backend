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

- [ ] Criar domínio de `Order` persistido com snapshot, baixa/reposição de estoque e pagamento exclusivo por carteira (`ORD-01`, `INV-01`, `PAY-01`)
- [ ] Modelar fluxo seguro de status do pedido com transições permitidas por ator e trilha auditável (`ORD-02`..`ORD-07`)
- [ ] Integrar ledger financeiro buyer/seller por `order_id`, incluindo crédito inicial, refund automático e painel de recebíveis do seller (`PAY-02`..`PAY-05`)
- [ ] Permitir avaliação pós-entrega com registros separados por produto e por vendedor para cálculo de média (`RATE-01`, `RATE-02`)

### Out of Scope

- Login social (OAuth)
- Password reset / email verification
- MFA/2FA neste ciclo

## Current Milestone: v1.4 Orders, Status Flow, and Ratings

**Goal:** Transformar checkout em pedido real com fluxo seguro de status, liquidação financeira rastreável por `order_id` e avaliações pós-entrega.

**Target features:**
- Pedidos persistidos com snapshot, estoque consistente e pagamento apenas via carteira interna
- Máquina de estados de pedido com avanço controlado pelo seller, cancelamento do buyer e contestação pós-entrega
- Ledger buyer/seller referenciado por `order_id`, crédito inicial de signup e painel financeiro do seller
- Avaliações vinculadas a compra entregue com tabela por produto e por vendedor

## Current State

- **Shipped versions:** v1.0, v1.1, v1.2, v1.3
- **Current milestone:** v1.4 Orders, Status Flow, and Ratings
- **Stack:** Rails API-only 8.0.4, Ruby 3.3.0, PostgreSQL, gem `jwt`

## Constraints

- Toda autorização de recursos privados usa usuário derivado do token.
- Endpoints privados exigem autenticação.
- Endpoints públicos não expõem dados sensíveis.
- Operações de carteira nunca confiam em valores enviados pelo frontend.
- Ledger de carteira é append-only: sem `UPDATE`/`DELETE` em transações.
- Transições críticas de pedido devem ser autorizadas por ator e validadas server-side; cliente nunca escolhe estado arbitrário.

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
| `order_id` será a referência principal de ledger neste milestone | Rastreabilidade ponta a ponta de cobrança, refund e repasse seller | — Pending |
| Fluxo de status do pedido exigirá transições explícitas e auditáveis | Evitar troca indevida de estado por payload manipulado ou corrida | — Pending |
| Avaliações serão persistidas em registros separados por produto e por vendedor | Simplificar cálculo futuro de médias agregadas sem ambiguidade | — Pending |

## Next Milestone Goals

1. Criar `Order` persistido no checkout com snapshot completo e impacto correto em estoque.
2. Vincular movimentações financeiras buyer/seller a `order_id`, incluindo crédito inicial do usuário.
3. Implementar fluxo seguro de status com avanço seller, cancelamento buyer, entrega e contestação.
4. Expor visão financeira do seller e avaliações pós-entrega por produto e por vendedor.

---
*Last updated: 2026-03-09 after starting v1.4 milestone*
