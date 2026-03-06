# Phase 3 Research: Auth Endpoints and Rotation Flow

**Phase:** 3 — Auth Endpoints and Rotation Flow
**Date:** 2026-03-06
**Source Inputs:** 03-CONTEXT.md, REQUIREMENTS.md, ROADMAP.md, STATE.md, phase 1/2 codebase

## Objective
Definir implementação segura dos endpoints `signup`, `login` e `refresh`, garantindo contrato HTTP consistente, rotação one-time de refresh token e comportamento determinístico sob concorrência.

## Existing Code Constraints
- `POST /auth/signup` já existe e cria `User + Profile` com erro público `cadastro invalido`.
- Infra JWT pronta: `Auth::Jwt::Issuer` e `Auth::Jwt::Verifier`.
- Infra de sessão pronta: `RefreshSession`, digest com pepper, busca ativa, revogação global e detecção de reuse.
- Mensagens públicas já seguem política anti-enumeração.

## Recommended Design for Phase 3

### Endpoint contracts (aligned with context)
- Sucesso em `signup`, `login` e `refresh`: envelope `{ data: { ... } }`.
- Campos de sucesso: `id`, `email`, `profile_id`, `access_token`, `refresh_token`, `token_type`, `access_expires_in`, `refresh_expires_in`.
- `token_type` fixo como `Bearer`.

### Signup with initial token pair
- Reusar `Users::Create` para criação transacional.
- Após sucesso, emitir access+refresh e persistir sessão de refresh com `refresh_jti` e `refresh_token_hash`.
- Falhas de cadastro retornam `422 cadastro invalido`.

### Login with credential auth
- Autenticar por `email + password` em `User.authenticate`.
- Em sucesso: emitir par de tokens + criar sessão refresh.
- Em falha: `401 credenciais invalidas` sem distinção entre usuário inexistente/senha incorreta.

### Refresh one-time with transactional rotation
- Entrada: somente body JSON com `refresh_token`, sem campos extras.
- Pipeline seguro:
1. Verificar JWT de refresh (`type=refresh`, assinatura e expiração)
2. Buscar sessão ativa por `jti + hash`
3. Rotacionar transacionalmente a mesma linha (lock row), marcando `rotated_at` no token usado e atualizando para novo `jti/hash/exp`
4. Emitir novo par access+refresh
- Concorrência: primeira request vence; segunda recebe `401 token invalido`.

### Replay/reuse handling in refresh
- Se refresh token já revogado/usado for reapresentado, disparar revogação global e retornar `401 token invalido`.
- Não expor causa detalhada ao cliente.

## Security Risks and Mitigations
- **Race condition em refresh**
  - Mitigar com transação + lock de linha da sessão.
- **Replay de refresh token roubado**
  - Mitigar com one-time rotation + invalidação imediata do token anterior.
- **Enumeração de contas no login**
  - Mitigar com mensagem única `credenciais invalidas`.
- **Payload malformado no refresh**
  - Mitigar com validação estrita de JSON/body e rejeição de campos desconhecidos.

## Test Strategy for this phase
- Integration tests para `signup/login/refresh` cobrindo contrato de sucesso e erros HTTP.
- Service tests para rotação one-time com concorrência simulada e rejeição do token antigo.
- Regression tests de segurança: reuse detectado, token expirado, payload inválido.

## Validation Architecture

### Required verification points
- `signup` e `login` retornam token pair com TTLs 15m/7d.
- `refresh` válido rotaciona token e invalida anterior.
- Segundo uso do mesmo refresh falha com `401 token invalido`.
- Contrato de resposta é consistente nos três endpoints.

### Fast feedback commands
- `RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test test/integration/auth_signup_test.rb test/integration/auth_login_test.rb test/integration/auth_refresh_test.rb`
- `RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test test/services/auth/sessions/rotation_test.rb`

### Full validation command
- `RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test`

## Deliverables aligned to roadmap plans
- Plan `03-01`: evoluir signup para emitir token pair e persistir sessão.
- Plan `03-02`: implementar login endpoint com autenticação e contrato unificado.
- Plan `03-03`: implementar refresh endpoint com rotação transacional one-time.
