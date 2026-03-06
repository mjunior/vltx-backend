# Project Research Summary

**Project:** Marketplace Backend
**Domain:** API authentication and secure session lifecycle
**Researched:** 2026-03-05
**Confidence:** HIGH

## Executive Summary

A milestone deve implementar autenticação JWT segura com sessão controlada por estado persistido para permitir revogação efetiva. O fluxo mínimo inclui cadastro, login, refresh rotativo e logout global.

A arquitetura recomendada é Rails API com `User` para credenciais, `Profile` para dados pessoais e uma entidade de sessão para rastrear refresh token por `jti`. A segurança depende de três pilares: secrets separados por tipo de token, refresh token hash no banco e invalidação global em caso de reuse suspeito.

Os maiores riscos são replay de refresh, revogação incompleta e vazamento de segredo/token. O roadmap deve isolar primeiro a base criptográfica e de sessão, depois endpoints, e por fim hardening e cobertura de teste.

## Key Findings

### Recommended Stack

Use `jwt` gem em Rails 8 com PostgreSQL, mantendo `has_secure_password` para senha e sessão persistida para refresh token rotativo. Evitar soluções totalmente stateless para refresh em cenários com revogação obrigatória.

**Core technologies:**
- `jwt`: assinatura e validação de access/refresh
- PostgreSQL: estado transacional de sessão e revogação
- Rails services: separação de emissão/validação/rotação

### Expected Features

**Must have (table stakes):**
- Signup e login com email/senha
- Access token (15 min) e refresh token (7 dias)
- Refresh rotativo one-time
- Logout global

**Should have (competitive):**
- Reuse detection com resposta defensiva (deslogar geral)

**Defer (v2+):**
- MFA e social login

### Architecture Approach

Estruturar em camadas: controller de auth, serviços de token, modelos de usuário/perfil/sessão. Toda operação de refresh deve ser transacional para impedir dupla aceitação de token.

### Critical Pitfalls

1. **Replay de refresh** — rotação estrita com revogação imediata
2. **Mesmo secret para todos os tokens** — secrets distintos obrigatórios
3. **Logout sem revogação real** — revogação global baseada em sessão e `jti`

## Implications for Roadmap

### Phase 1: User and Profile Foundation
**Rationale:** base de dados e credenciais antes de token lifecycle.

### Phase 2: JWT and Session Security Core
**Rationale:** garantir emissão/validação segura antes de expor endpoints.

### Phase 3: Auth Endpoints (Signup/Login/Refresh)
**Rationale:** plugar fluxo completo com rotação segura.

### Phase 4: Logout Global and Reuse Incident Handling
**Rationale:** fechar lacunas de sessão e incident response.

### Phase 5: Hardening and Security Test Coverage
**Rationale:** validar comportamentos de segurança e regressão.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Alinhado com app Rails atual |
| Features | HIGH | Escopo definido pelo usuário |
| Architecture | HIGH | Padrão consolidado para JWT rotativo |
| Pitfalls | HIGH | Riscos clássicos conhecidos e mitigáveis |

**Overall confidence:** HIGH

---
*Research completed: 2026-03-05*
*Ready for roadmap: yes*
