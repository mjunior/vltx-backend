# Marketplace Backend

## What This Is

API backend em Rails 8 para autenticação JWT segura, gestão de perfil do usuário, domínio de produtos e jornada de compra com carrinho. O foco atual evolui o catálogo público para permitir fluxo de compra seguro sem confiar em payload sensível vindo do frontend.

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

- [ ] Criar pedido persistido a partir do carrinho finalizado com snapshot de itens/valores
- [ ] Debitar carteira com trilha de saldo/ledger e rollback seguro em falha
- [ ] Introduzir estados do pedido (processing, failed, canceled) e idempotência de criação

### Out of Scope

- Login social (OAuth)
- Password reset / email verification
- MFA/2FA neste ciclo

## Current Milestone

Nenhum milestone ativo (v1.2 concluído). Próximo ciclo deve focar criação de pedido e débito de carteira.

## Current State

- **Shipped versions:** v1.0, v1.1, v1.2
- **Current milestone:** none (ready for `$gsd-new-milestone`)
- **Stack:** Rails API-only 8.0.4, Ruby 3.3.0, PostgreSQL, gem `jwt`

## Constraints

- Toda autorização de recursos privados usa usuário derivado do token.
- Endpoints privados exigem autenticação.
- Endpoints públicos não expõem dados sensíveis.

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

## Next Milestone Goals

1. Criar `Order` persistido a partir do carrinho finalizado com snapshot financeiro estável.
2. Integrar débito de carteira/ledger com garantias transacionais e idempotência.
3. Entregar estados de pedido e tratamento robusto de falha/cancelamento.

---
*Last updated: 2026-03-07 after v1.2 milestone completion*
