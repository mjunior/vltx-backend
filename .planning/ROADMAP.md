# Roadmap: Marketplace Backend

## Overview

Este roadmap entrega autenticação JWT segura em Rails API com foco em defesa contra replay, revogação confiável de sessão e separação entre credenciais (`User`) e dados de perfil (`Profile`). O fluxo evolui de fundação de dados para lifecycle de token, endpoints e hardening final.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

- [x] **Phase 1: User and Profile Foundation** - Criar base de identidade e perfil com persistência segura de credenciais. (completed 2026-03-06)
- [x] **Phase 2: JWT and Session Security Core** - Implementar infraestrutura de token, segredos separados e sessão revogável por `jti`. (completed 2026-03-06)
- [x] **Phase 3: Auth Endpoints and Rotation Flow** - Entregar signup/login/refresh com rotação de refresh token one-time. (completed 2026-03-06)
- [x] **Phase 4: Logout Global and Reuse Incident Handling** - Implementar revogação global e resposta a reutilização de refresh revogado. (completed 2026-03-06)
- [ ] **Phase 5: Security Hardening and Verification** - Consolidar testes de segurança, edge cases e critérios de aceitação.

## Phase Details

### Phase 1: User and Profile Foundation
**Goal**: Estabelecer modelo de autenticação e perfil com relação correta e senha segura.
**Depends on**: Nothing (first phase)
**Requirements**: AUTH-01, PROF-01, PROF-02
**Success Criteria** (what must be TRUE):
  1. Usuário pode ser cadastrado com email único e senha com hash seguro.
  2. Cada `User` possui exatamente um `Profile` associado.
  3. Dados de perfil ficam separados de credenciais de autenticação.
**Plans**: 2 plans

Plans:
- [ ] 01-01: Definir migrations/models/validações de `User` e `Profile`
- [ ] 01-02: Implementar serviços de criação segura de conta (base para signup)

### Phase 2: JWT and Session Security Core
**Goal**: Criar núcleo criptográfico e estado de sessão revogável.
**Depends on**: Phase 1
**Requirements**: AUTH-05, SESS-01, SESS-06
**Success Criteria** (what must be TRUE):
  1. Access e refresh usam segredos distintos e configuração obrigatória.
  2. Sessão de refresh persiste somente hash do token com `jti` auditável.
  3. Validação de token rejeita tokens revogados/inválidos de forma consistente.
**Plans**: 3 plans

Plans:
- [ ] 02-01: Implementar serviços JWT (issue/verify) com claims e segredos separados
- [ ] 02-02: Criar modelo/tabela de sessão para refresh com hash, `jti`, expiração e status
- [ ] 02-03: Implementar regras de revogação e utilitários de checagem por `jti`

### Phase 3: Auth Endpoints and Rotation Flow
**Goal**: Expor endpoints de signup/login/refresh com rotação one-time correta.
**Depends on**: Phase 2
**Requirements**: AUTH-02, AUTH-03, AUTH-04, SESS-02, SESS-03
**Success Criteria** (what must be TRUE):
  1. Signup e login retornam par access/refresh com TTLs definidos (15m/7d).
  2. Refresh válido invalida token anterior e emite novo par de tokens.
  3. Refresh token não pode ser aceito mais de uma vez.
**Plans**: 3 plans

Plans:
- [ ] 03-01: Implementar endpoint de signup com emissão inicial de token pair
- [ ] 03-02: Implementar endpoint de login com autenticação por email/senha
- [ ] 03-03: Implementar endpoint de refresh com rotação transacional one-time

### Phase 4: Logout Global and Reuse Incident Handling
**Goal**: Fechar ciclo de segurança com revogação global e resposta a incidente.
**Depends on**: Phase 3
**Requirements**: SESS-04, SESS-05
**Success Criteria** (what must be TRUE):
  1. Logout invalida todas as sessões ativas do usuário autenticado.
  2. Reuso de refresh revogado dispara revogação global imediata do usuário.
  3. Tentativas subsequentes com tokens revogados são recusadas corretamente.
**Plans**: 2 plans

Plans:
- [ ] 04-01: Implementar endpoint de logout global e revogação em lote
- [ ] 04-02: Implementar detecção de reuse + resposta de segurança (global revoke)

### Phase 5: Security Hardening and Verification
**Goal**: Garantir robustez do fluxo com testes e validações de segurança.
**Depends on**: Phase 4
**Requirements**: (cross-cutting verification for all v1 requirements)
**Success Criteria** (what must be TRUE):
  1. Testes cobrindo sucesso e falha para signup/login/refresh/logout global.
  2. Testes cobrindo replay/reuse, token expirado e token revogado.
  3. Critérios de segurança da milestone validados sem regressão.
**Plans**: 2 plans

Plans:
- [ ] 05-01: Escrever suíte de testes de integração para fluxos de auth e sessão
- [ ] 05-02: Hardening final (mensagens de erro, validações, auditoria básica)

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. User and Profile Foundation | 0/2 | Complete    | 2026-03-06 |
| 2. JWT and Session Security Core | 3/3 | Complete   | 2026-03-06 |
| 3. Auth Endpoints and Rotation Flow | 3/3 | Complete   | 2026-03-06 |
| 4. Logout Global and Reuse Incident Handling | 2/2 | Complete   | 2026-03-06 |
| 5. Security Hardening and Verification | 1/2 | In Progress|  |
