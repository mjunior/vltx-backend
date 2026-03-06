# Phase 2: JWT and Session Security Core - Context

**Gathered:** 2026-03-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Implementar o núcleo criptográfico e o estado de sessão revogável para JWT: emissão/validação de access e refresh com segredos separados, `jti` obrigatório e persistência segura da sessão de refresh. Esta fase prepara a infraestrutura de segurança; fluxos completos de login/refresh/logout ficam para fases seguintes.

</domain>

<decisions>
## Implementation Decisions

### Access Token Claims (minimal surface)
- Access token terá apenas claims mínimos: `sub`, `jti`, `type`, `iat`, `exp`.
- Não incluir `email` nem `profile_id` no access token nesta fase.

### Refresh Session Persistence Model
- Uma sessão ativa por refresh token, com rotação atualizando o mesmo registro.
- Auditoria básica no mesmo registro com `rotated_at` e `revoked_at`.
- Não usar trilha histórica completa por rotação nesta fase.

### Revocation Policy
- Logout/reuse revoga todas as refresh sessions do usuário.
- Access tokens emitidos anteriormente expiram naturalmente (sem denylist de access `jti` nesta fase).

### Public Token Error Policy
- Resposta pública genérica para falhas de token: `token invalido`.
- Diferenciação detalhada (expirado/revogado/malformado) apenas em logs internos.

### JWT Crypto and Secrets
- Algoritmo JWT: `HS256` para access e refresh.
- Segredos de access e refresh obrigatórios e distintos.
- App deve falhar no boot se qualquer secret necessário não estiver definido.

### Refresh Hashing Strategy
- Hash do refresh token com `SHA-256` + `pepper` global da aplicação.
- `pepper` deve vir de variável de ambiente (não persistido no banco).

### Refresh Session Schema (minimum required)
- Campos mínimos aprovados para sessão:
- `user_id`
- `refresh_jti`
- `refresh_token_hash`
- `expires_at`
- `revoked_at`
- `rotated_at`
- `created_at` / `updated_at`

### Claude's Discretion
- Nomes exatos de classes/módulos de serviço JWT no código.
- Organização fina de inicializers/config helpers mantendo as decisões acima.

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `marketplace_backend/app/models/user.rb`: já pronto para auth por credencial.
- `marketplace_backend/app/services/users/create.rb`: padrão de service object com resultado explícito.
- `marketplace_backend/app/controllers/application_controller.rb`: ponto comum para erro público padronizado.
- `marketplace_backend/config/initializers/filter_parameter_logging.rb`: já cobre token/secret.

### Established Patterns
- App em Rails API-only com estrutura limpa e mínima.
- Política de mensagem pública genérica já adotada no signup (`cadastro invalido`).
- Testes em Minitest (modelo, serviço, integração).

### Integration Points
- Inicialização de JWT via `config/initializers/*`.
- Modelo de sessão em `app/models` + migration em `db/migrate`.
- Serviços de emissão/validação de token em `app/services`.
- Políticas de erro reutilizadas em `ApplicationController` para endpoints futuros.

</code_context>

<specifics>
## Specific Ideas

- Reduzir superfície de claims no access token para minimizar exposição de dados.
- Endurecer operação com fail-fast no boot quando segredo obrigatório estiver ausente.
- Priorizar mitigação de vazamento de banco com hash + pepper no refresh token.

</specifics>

<deferred>
## Deferred Ideas

- Denylist de access `jti` (revogação imediata de access token) fica para fase futura se necessário.

</deferred>

---

*Phase: 02-jwt-and-session-security-core*
*Context gathered: 2026-03-05*
