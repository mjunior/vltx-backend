# Marketplace Backend

## What This Is

API backend em Rails 8 para autenticação segura baseada em JWT, com suporte a cadastro/login, refresh rotativo, logout global, gestão de perfil e catálogo público de produtos.
A autenticação continua no recurso `User`; dados de perfil e anúncios são controlados por escopo de dono (owner) derivado do token.

## Core Value

Garantir autenticação segura e previsível com isolamento multi-tenant estrito e exposição pública mínima de dados.

## Requirements

### Validated

- ✓ Cadastro e login com email/senha — v1.0
- ✓ Access token (15 min) + refresh token (7 dias) com segredos distintos — v1.0
- ✓ Refresh token rotativo one-time com proteção contra replay — v1.0
- ✓ Logout global com revogação por `jti` — v1.0
- ✓ Relação `User has_one Profile` com separação de credenciais e perfil — v1.0

### Active

- [ ] Edição de perfil próprio (nome e endereço)
- [ ] CRUD de anúncios do vendedor com ownership estrito
- [ ] Listagem pública de produtos com busca, faixa de preço e ordenação
- [ ] Página pública de detalhe do produto com serializer seguro (sem dados sensíveis)
- [ ] Regras de segurança anti-forgery de owner (`owner_id`/`user_id` nunca vindo do frontend)

### Out of Scope

- Login social (OAuth)
- Password reset / email verification
- MFA/2FA neste milestone

## Current Milestone: v1.1 Profile and Catalog

**Goal:** Entregar perfil editável e domínio de produtos com controles de ownership e catálogo público seguro.

**Target features:**
- Edição de perfil próprio (`name`, `address`)
- Criação, edição, desativação e deleção de anúncios do próprio vendedor
- Listagem pública de produtos com busca/filtros/ordenação
- Detalhe público de produto com serializer dedicado sem dados sensíveis

## Context

- Stack atual: Rails API-only 8.0.4, Ruby 3.3.0, PostgreSQL, gem `jwt`.
- Milestone v1.0 validada e arquivada.
- Regras mandatórias desta milestone:
  - Multi-tenant estrito: usuário só altera recursos próprios
  - Nunca confiar em `user_id`/`owner_id` enviados pelo frontend
  - Contexto autenticado derivado exclusivamente do token
  - Endpoints públicos sob `/public`

## Constraints

- Toda autorização de recursos privados deve usar usuário do token.
- Endpoints privados exigem autenticação.
- Endpoints públicos não devem expor dados sensíveis (email, IDs internos de owner, hashes, etc.).
- Rotas públicas de catálogo devem ficar em `/public/products` e `/public/products/:id`.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Usar JWT com `jti` para sessões | Permite revogação explícita e rastreável de tokens | ✓ Good (v1.0) |
| Access/Refresh com segredos diferentes | Limita impacto se um segredo for comprometido | ✓ Good (v1.0) |
| Refresh token rotativo one-time | Mitiga replay e roubo de token | ✓ Good (v1.0) |
| Reuse de refresh revogado causa logout global | Resposta defensiva em evento suspeito | ✓ Good (v1.0) |
| Auth no `User`, dados pessoais no `Profile` | Separa credenciais de dados de apresentação | ✓ Good (v1.0) |
| Ownership sempre derivado do token | Evita spoofing multi-tenant via payload do frontend | ✓ Locked (v1.1) |
| Catálogo público com serializer específico | Evita vazamento de dados sensíveis | ✓ Locked (v1.1) |

## Current State

- **Shipped version:** v1.0
- **Current milestone:** v1.1 Profile and Catalog
- **Focus:** recursos de vendedor e catálogo público seguro

## Next Milestone Goals

1. Implementar edição de perfil próprio com autorização por token.
2. Implementar lifecycle de produtos do vendedor com ownership enforcement.
3. Expor catálogo público seguro com busca/filtro/sort e detalhe de produto.

---
*Last updated: 2026-03-06 after v1.1 kickoff*
