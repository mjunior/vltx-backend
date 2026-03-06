# Phase 3: Auth Endpoints and Rotation Flow - Context

**Gathered:** 2026-03-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Expor endpoints de autenticação (`signup`, `login`, `refresh`) com emissão de par access/refresh e rotação one-time de refresh token. Esta fase cobre contrato HTTP, validação de entrada e semântica de rotação para fluxo normal; resposta a incidente de reuse e logout endpoint seguem fases dedicadas.

</domain>

<decisions>
## Implementation Decisions

### Auth Success Response Contract
- Todas as respostas de sucesso de `signup`, `login` e `refresh` usam envelope: `{ data: { ... } }`.
- Dados de usuário retornados no payload: `id`, `email`, `profile_id`.
- Expiração retornada em segundos: `access_expires_in`, `refresh_expires_in`.
- Campos de token no payload: `access_token`, `refresh_token`, `token_type` com valor `Bearer`.

### Refresh Endpoint Input
- Endpoint de refresh aceita refresh token apenas no body JSON: `{ refresh_token }`.
- `Content-Type: application/json` obrigatório.
- Payload com campos desconhecidos deve ser rejeitado.
- Regra de prioridade body/header foi descartada nesta fase porque entrada ficou restrita a body.

### Public Error Policy (HTTP)
- Login com credenciais inválidas: `401` + `{ error: "credenciais invalidas" }`.
- Refresh com token inválido/expirado/revogado: `401` + `{ error: "token invalido" }`.
- Payload inválido: `422` com erro genérico por endpoint.
- Signup inválido mantém `422` + `{ error: "cadastro invalido" }`.

### Refresh Rotation Semantics
- Refresh válido sempre invalida o token atual e emite novo par de tokens.
- Em concorrência com mesmo refresh token, apenas a primeira chamada deve vencer; a segunda retorna `401 token invalido`.
- Detectar reuse de refresh revogado/usado exige revogação global imediata das sessões do usuário (política de segurança já definida).
- Resposta de sucesso de refresh segue exatamente o mesmo contrato de `signup/login`.

### Claude's Discretion
- Organização interna dos serviços/controllers para manter o contrato e as políticas acima.
- Estrutura de serialização de resposta (desde que preserve o shape definido).

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `marketplace_backend/app/controllers/auth/signups_controller.rb`: endpoint de signup já existente para evoluir para contrato de token pair.
- `marketplace_backend/app/services/auth/jwt/issuer.rb` e `verifier.rb`: base pronta para emissão/validação de access/refresh.
- `marketplace_backend/app/services/auth/sessions/*`: digest, busca ativa, revogação e detecção de reuse já implementados.
- `marketplace_backend/app/services/users/create.rb`: criação transacional de usuário/perfil reutilizável no signup.

### Established Patterns
- Mensagens públicas genéricas para evitar enumeração de credenciais.
- Claims JWT mínimos com `jti` e `type`.
- Sessão de refresh com hash + pepper e estado revogável.

### Integration Points
- `marketplace_backend/config/routes.rb`: adicionar `POST /auth/login` e `POST /auth/refresh` mantendo `POST /auth/signup`.
- `marketplace_backend/app/controllers/application_controller.rb`: centralizar renderização de erros públicos.
- `marketplace_backend/test/integration/*`: ampliar cobertura de contrato HTTP e rotação one-time.

</code_context>

<specifics>
## Specific Ideas

- Consistência total do contrato de sucesso entre `signup`, `login` e `refresh`.
- Refresh estritamente por body JSON (sem ambiguidade de canal).
- Preferência explícita por `401` para falhas de autenticação/token e `422` para payload inválido.

</specifics>

<deferred>
## Deferred Ideas

- Endpoint de logout global fica na fase 4.
- Fluxo completo de resposta operacional para incidente de reuse (além da base de revogação) fica na fase 4.

</deferred>

---

*Phase: 03-auth-endpoints-and-rotation-flow*
*Context gathered: 2026-03-06*
