# Marketplace Backend

## What This Is

API backend em Rails 8 para autenticação JWT segura, gestão de perfil do usuário e domínio de produtos com catálogo público seguro.

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

- [ ] Definir escopo da v1.2

### Out of Scope

- Login social (OAuth)
- Password reset / email verification
- MFA/2FA neste ciclo

## Current State

- **Shipped versions:** v1.0, v1.1
- **Current milestone:** none active (ready for v1.2 definition)
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

## Next Milestone Goals

1. Definir requisitos da v1.2.
2. Planejar roadmap incremental sobre base v1.1 já entregue.

---
*Last updated: 2026-03-06 after v1.1 milestone completion*
