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
- ✓ Pedidos persistidos com split por seller, snapshot, estoque consistente e pagamento via wallet — v1.4
- ✓ Workflow seguro de pedido com transições auditáveis e ações explícitas por ator — v1.4
- ✓ Ledger buyer/seller rastreável com `checkout_group`, refund automático e painel financeiro do seller — v1.4
- ✓ Contestação pós-entrega e avaliações separadas por produto/vendedor vinculadas ao `order_item` — v1.4

### Active

- [ ] Confirmar e-mail e emitir bônus promocional de R$ 10 após confirmação (`PAY-02`)
- [ ] Implementar payout/liquidação externa do saldo seller (`PAY-06`)
- [ ] Suportar meios de pagamento externos como cartão e Pix (`PAY-07`)
- [ ] Evoluir contestação para mediação operacional completa com novos estados internos (`ORD-08`)
- [ ] Expor leitura agregada de médias e resposta pública do seller para avaliações (`RATE-03`)

### Out of Scope

- Login social (OAuth)
- Password reset / email verification
- MFA/2FA neste ciclo

## Current Milestone

Nenhum milestone ativo. Último entregue: **v1.4 Orders, Status Flow, and Ratings**.

## Current State

- **Shipped versions:** v1.0, v1.1, v1.2, v1.3, v1.4
- **Current milestone:** nenhum ativo; pronto para iniciar o próximo
- **Stack:** Rails API-only 8.0.4, Ruby 3.3.0, PostgreSQL, gem `jwt`
- **Functional scope now shipped:** auth JWT, perfil, catálogo, carrinho, checkout wallet-only, pedidos, wallet ledger, painel financeiro seller, contestação e avaliações pós-entrega

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
| Débito buyer agregado por `checkout_group` com pedidos splitados por seller | Manter UX de uma compra única com rastreabilidade interna por pedido | ✓ Good (v1.4) |
| Fluxo de status do pedido via ações explícitas e trilha auditável | Evitar troca indevida de estado por payload manipulado ou corrida | ✓ Good (v1.4) |
| Crédito seller só em `delivered` | Reduzir risco de refund após liberação financeira | ✓ Good (v1.4) |
| Avaliações persistidas separadamente por produto e por vendedor | Simplificar cálculo futuro de médias agregadas sem ambiguidade | ✓ Good (v1.4) |
| Query de pedido deve nascer tenant-scoped, não apenas validar ownership após busca | Reduzir superfície de cross-access e endurecer isolamento | ✓ Good (v1.4) |

## Next Milestone Goals

1. Definir e implementar confirmação de e-mail com crédito promocional pós-confirmação.
2. Projetar payout real do seller e política de liquidação.
3. Evoluir mediação de contestação com workflow operacional dedicado.
4. Expor surfaces de leitura agregada para reputação de produto e seller.

<details>
<summary>Historical Milestone Context</summary>

### v1.4 Orders, Status Flow, and Ratings

- Pedidos persistidos com snapshot, split por seller e baixa/restauração de estoque
- Workflow seguro com `advance`, `cancel`, `deliver` e `contest`
- `checkout_group`, `seller_receivables` e painel financeiro seller
- Ratings separados por produto e por vendedor

</details>

---
*Last updated: 2026-03-10 after shipping v1.4 milestone*
