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

### Active

- [ ] Carrinho ativo único por usuário autenticado (criar/recuperar com isolamento por tenant)
- [ ] Operações de item de carrinho (adicionar/remover/atualizar quantidade) com validação server-side transacional
- [ ] Finalização de carrinho ativo mudando status para `finished` e preparação de service para criação de pedido
- [ ] Bloqueios de segurança: não confiar em `id`, `quantity` e `price` do frontend; não permitir compra de produto próprio

### Out of Scope

- Login social (OAuth)
- Password reset / email verification
- MFA/2FA neste ciclo

## Current Milestone: v1.2 Cart and Checkout Foundation

**Goal:** Entregar carrinho seguro com operações de item validadas no backend e finalização preparada para iniciar pedidos.

**Target features:**
- Carrinho ativo único por usuário autenticado
- Operações de item com validação transacional de quantidade/preço
- Finalização do carrinho ativo para `finished` com pagamento por carteira
- Service de preparação para criação de pedido (sem criar pedido ainda)

## Current State

- **Shipped versions:** v1.0, v1.1
- **Current milestone:** v1.2 Cart and Checkout Foundation (active)
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
| Carrinho só aceita dados críticos validados no backend | Evitar fraude/abuso de payload manipulável | — Pending (v1.2) |
| Um carrinho ativo por usuário | Simplificar checkout e reduzir abuso por multiplicação de carrinhos | — Pending (v1.2) |

## Next Milestone Goals

1. Entregar carrinho seguro com operações de item validadas no backend.
2. Preparar finalização de carrinho e fundação do fluxo de pedido via service dedicado.
3. Reforçar regras cross-cutting de tenant/authz para impedir acesso indevido e abuso.

---
*Last updated: 2026-03-07 after milestone v1.2 initialization*
