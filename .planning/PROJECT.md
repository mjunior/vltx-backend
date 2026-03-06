# Marketplace Backend

## What This Is

API backend em Rails 8 para autenticação segura baseada em JWT, com cadastro, login, refresh token rotativo de uso único e logout global.
A autenticação acontece no recurso `User` (email + senha), enquanto `Profile` mantém os dados de apresentação.

## Core Value

Garantir autenticação segura e previsível, com controle forte de sessão (rotação + revogação) e resposta defensiva a replay/reuse.

## Requirements

### Validated

- ✓ Cadastro e login com email/senha — v1.0
- ✓ Access token (15 min) + refresh token (7 dias) com segredos distintos — v1.0
- ✓ Refresh token rotativo one-time com proteção contra replay — v1.0
- ✓ Logout global com revogação por `jti` — v1.0
- ✓ Relação `User has_one Profile` com separação de credenciais e perfil — v1.0

### Active

- [ ] MFA/2FA para contas sensíveis (SECV2-01)
- [ ] Gestão seletiva de sessões por dispositivo (SECV2-02)
- [ ] Fechar dívida de Nyquist validation (`nyquist_compliant: true` por fase)

### Out of Scope

- Login social (OAuth) — continua fora do escopo imediato
- Password reset / email verification — ainda não priorizado para o próximo ciclo

## Context

- Stack atual: Rails API-only 8.0.4, Ruby 3.3.0, PostgreSQL, gem `jwt`.
- Endpoints entregues em v1.0:
  - `GET /up`
  - `POST /auth/signup`
  - `POST /auth/login`
  - `POST /auth/refresh`
  - `POST /auth/logout`
- Milestone v1.0 finalizada com cobertura de testes para casos de sucesso/falha, expiração, revogação e reuse incidente.

## Constraints

- Refresh token persistido apenas como hash.
- Segredos JWT de access e refresh obrigatoriamente distintos.
- Reuse de refresh revogado dispara revogação global.
- Manter contratos públicos de erro genéricos (sem vazamento de estado interno).

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Usar JWT com `jti` para sessões | Permite revogação explícita e rastreável de tokens | ✓ Good (v1.0) |
| Access/Refresh com segredos diferentes | Limita impacto se um segredo for comprometido | ✓ Good (v1.0) |
| Refresh token rotativo one-time | Mitiga replay e roubo de token | ✓ Good (v1.0) |
| Reuse de refresh revogado causa logout global | Resposta defensiva em evento suspeito | ✓ Good (v1.0) |
| Auth no `User`, dados pessoais no `Profile` | Separa credenciais de dados de apresentação | ✓ Good (v1.0) |

## Current State

- **Shipped version:** v1.0
- **Milestone health:** requisitos v1 satisfeitos (13/13) com integração e fluxos E2E validados.
- **Accepted debt:** validações Nyquist ainda em draft.

## Next Milestone Goals

1. Elevar baseline de validação (Nyquist compliance por fase).
2. Planejar e implementar MFA/2FA.
3. Evoluir gerenciamento de sessões por dispositivo.

---
*Last updated: 2026-03-06 after v1.0 completion*
