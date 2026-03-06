# Phase 4 Research: Logout Global and Reuse Incident Handling

**Phase:** 4 — Logout Global and Reuse Incident Handling
**Date:** 2026-03-06
**Source Inputs:** 04-CONTEXT.md, REQUIREMENTS.md, ROADMAP.md, STATE.md, phase 2/3 auth code

## Objective
Definir implementação do endpoint de logout global e fechar resposta de incidente de reuse, garantindo idempotência, não vazamento de estado e revogação global consistente.

## Existing Code Constraints
- `RevokeAll` já revoga sessões ativas em lote por usuário.
- `DetectReuse` já identifica reuse com base em refresh session revogada.
- `RefreshesController` usa `RotateSession` e retorna `401 token invalido` para falhas.
- Não há denylist de access token (decisão explícita).

## Recommended Design for Phase 4

### Logout endpoint design
- Novo endpoint: `POST /auth/logout`.
- Entrada via `Authorization: Bearer <access_token>` (token de acesso).
- Requer `Content-Type: application/json`.
- Sucesso: `204 No Content` (sem payload).

### Logout flow semantics
- Verificar access token (`expected_type=access`) para identificar usuário.
- Em token válido: executar `RevokeAll` para o usuário.
- Idempotência: sem sessões ativas também retorna `204`.
- Token inválido/expirado/revogado: `401 { error: "token invalido" }`.

### Reuse incident handling
- No refresh flow, quando reuse de refresh revogado for detectado:
- manter resposta pública `401 token invalido`
- garantir revogação global efetiva do usuário
- bloquear tentativas subsequentes de refresh até novo login

### Security consistency
- Não diferenciar publicamente expirado/revogado/reuse.
- Manter política de erro mínima para evitar enumeração de estado de sessão.
- Auditoria mínima: apenas `revoked_at` em lote nesta fase.

## Risks and Mitigations
- **False negatives em reuse**
  - Mitigar com testes de integração cobrindo reapresentação de token já rotacionado.
- **Regressão no contrato de erro**
  - Mitigar com testes explícitos para `401 token invalido` em logout/reuse.
- **Inconsistência de revogação global**
  - Mitigar validando quantidade de sessões revogadas e comportamento idempotente.

## Testing Strategy for this phase
- Integration tests para `POST /auth/logout` (sucesso, token inválido, idempotência).
- Integration tests para reuse em refresh com efeito global de revogação.
- Service tests para garantir `RevokeAll` e `DetectReuse` no fluxo esperado de controladores.

## Validation Architecture

### Required verification points
- Logout revoga globalmente e retorna `204` em sucesso.
- Logout com token inválido retorna `401 token invalido`.
- Reuse revogado dispara revogação global e retorna `401 token invalido`.
- Novas tentativas de refresh após incidente falham até novo login.

### Fast feedback commands
- `RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test test/integration/auth_logout_test.rb test/integration/auth_reuse_incident_test.rb`
- `RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test test/services/auth/sessions/revocation_test.rb`

### Full validation command
- `RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test`

## Deliverables aligned to roadmap plans
- Plan `04-01`: endpoint de logout global com contrato e testes.
- Plan `04-02`: integração da detecção de reuse com resposta de incidente e testes end-to-end.
