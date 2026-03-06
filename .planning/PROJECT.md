# Marketplace Backend

## What This Is

API backend em Rails 8 para autenticação segura baseada em JWT com suporte a cadastro, login, refresh token rotativo e logout global.
O sistema autentica no recurso `User` (email + senha), enquanto `Profile` fica responsável por dados de perfil (nome completo, foto, endereço e dados de apresentação).
Foco inicial do produto: segurança de sessão e controle robusto de revogação.

## Core Value

Garantir autenticação segura e previsível, com controle forte de sessão (rotação e revogação), sem brechas de reuso de token.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Cadastro e login com email/senha
- [ ] Access token JWT (15 min) + refresh token JWT (7 dias) com segredos distintos
- [ ] Refresh token rotativo, one-time use, com proteção contra replay
- [ ] Logout global com revogação por `jti`
- [ ] Relação `User has_one Profile`

### Out of Scope

- Login social (OAuth) — não é necessário para o escopo inicial de autenticação segura
- MFA/2FA — importante, mas fora do escopo da primeira milestone
- Gestão avançada de sessão por dispositivo — será tratada após validação do fluxo base

## Context

- Stack atual: Rails API-only 8.0.4, Ruby 3.3.0, PostgreSQL.
- Endpoint existente: `GET /up`.
- Objetivo desta milestone: entregar base de auth pronta para uso em produção inicial com foco explícito em segurança.
- Decisões do usuário para esta milestone:
- uso de `jti` para revogação
- access token 15 minutos
- refresh token 7 dias
- refresh rotativo de uso único
- tentativa de reutilização de refresh revogado => logout global
- segredos distintos para access/refresh
- refresh token persistido apenas em hash

## Constraints

- **Security**: Refresh token deve ser armazenado somente como hash — reduzir impacto de vazamento de banco.
- **Security**: Access e refresh devem usar segredos JWT diferentes — reduzir blast radius de comprometimento.
- **Security**: Reuso de refresh revogado deve invalidar todas as sessões do usuário — bloqueio de replay.
- **Tech stack**: Implementar com gem `jwt` em Rails API-only — manter consistência com stack atual.
- **Scope**: Incluir cadastro + login + refresh + logout global + perfil básico ligado ao usuário.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Usar JWT com `jti` para sessões | Permite revogação explícita e rastreável de tokens | — Pending |
| Access/Refresh com segredos diferentes | Limita impacto se um segredo for comprometido | — Pending |
| Refresh token rotativo one-time | Mitiga replay e roubo de token | — Pending |
| Reuse de refresh revogado causa logout global | Resposta defensiva em evento suspeito | — Pending |
| Auth no `User`, dados pessoais no `Profile` | Separa credenciais de dados de apresentação | — Pending |

---
*Last updated: 2026-03-05 after milestone v1.0 kickoff*
