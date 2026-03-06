# Phase 2 Research: JWT and Session Security Core

**Phase:** 2 — JWT and Session Security Core
**Date:** 2026-03-06
**Source Inputs:** 02-CONTEXT.md, REQUIREMENTS.md, ROADMAP.md, STATE.md, codebase scan

## Objective
Definir arquitetura segura para emissão e validação de JWT (access + refresh), persistência revogável por `jti`, e base transacional para rotação one-time sem expor segredos ou token em texto puro.

## Existing Code Constraints
- Rails 8 API-only em `marketplace_backend/` com Minitest.
- `User` com `has_secure_password` já disponível.
- Não existe infraestrutura JWT nem tabela de sessão.
- Política de erro público já padronizada para respostas genéricas.

## Recommended Design for Phase 2

### Token model and claims
- Access token claims mínimos: `sub`, `jti`, `type`, `iat`, `exp`.
- Refresh token claims mínimos: `sub`, `jti`, `type`, `iat`, `exp`.
- `type` deve ser estrito (`access` ou `refresh`) para prevenir token confusion.

### Secret separation and boot hardening
- `JWT_ACCESS_SECRET` e `JWT_REFRESH_SECRET` obrigatórios e distintos.
- `JWT_REFRESH_PEPPER` obrigatório e distinto dos dois segredos JWT.
- Falha de boot (`raise`) se alguma variável obrigatória estiver ausente.

### Cryptography and verification
- Algoritmo único da fase: `HS256`.
- Decode sempre com verificação de `exp` e de `type` esperado.
- Nunca retornar erro detalhado de token para cliente; usar mensagem genérica.

### Refresh session persistence
- Nova tabela/modelo `refresh_sessions` com:
- `user_id` (FK, not null)
- `refresh_jti` (not null, index unique)
- `refresh_token_hash` (not null)
- `expires_at` (not null)
- `rotated_at`, `revoked_at` (nullable)
- timestamps
- Persistir apenas `SHA-256(refresh_token + JWT_REFRESH_PEPPER)`.

### Revocation and one-time safety foundation
- Regras base para fase 2:
- Token refresh revogado ou não encontrado é inválido.
- Reuso detectado deve acionar revogação global de sessões do usuário.
- Rotação deve ser preparada para operação atômica com lock (`with_lock`) em fase 3.

## Security Risks and Mitigations
- **Replay de refresh token**
- Mitigar com validação por hash + `jti` + estado revogado/expirado.
- **Comprometimento de banco**
- Mitigar sem plaintext token: hash + pepper externo.
- **Erro de configuração em produção**
- Mitigar com fail-fast no boot para secrets/pepper ausentes.
- **Token type confusion**
- Mitigar validando claim `type` contra finalidade esperada.

## Testing Strategy for this phase
- Unit/service tests para issuer/verifier de JWT com segredos distintos.
- Model tests para `RefreshSession` (validações e integridade relacional).
- Service tests para revogação global, invalidação por `revoked_at`/`expires_at`, e detecção de reuse.

## Validation Architecture

### Required verification points
- Access e refresh devem usar segredos diferentes na emissão/validação.
- Hash persistido de refresh deve depender de `JWT_REFRESH_PEPPER`.
- Sessão revogada/expirada deve ser rejeitada consistentemente.
- Reuse de refresh revogado deve disparar revogação global.

### Fast feedback commands
- `RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test test/services/auth/jwt`
- `RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test test/models/refresh_session_test.rb`
- `RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test test/services/auth/sessions`

### Full validation command
- `RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test`

## Deliverables aligned to roadmap plans
- Plan `02-01`: serviços JWT (issue/verify), configuração de secrets e testes.
- Plan `02-02`: migration/model de `refresh_sessions` com hash + jti.
- Plan `02-03`: serviços de estado/revogação e utilitários de checagem por `jti`.
