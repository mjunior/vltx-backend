# Phase 1: User and Profile Foundation - Context

**Gathered:** 2026-03-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Estabelecer base de identidade e perfil: modelar `User` com credenciais seguras para cadastro e modelar `Profile` associado 1:1 ao usuário. Esta fase prepara a fundação de dados e regras de entrada, sem incluir lifecycle de JWT/refresh (fases seguintes).

</domain>

<decisions>
## Implementation Decisions

### Signup Payload Scope
- Signup inicial aceita apenas `email` e `password`.
- `password_confirmation` é obrigatório no payload de cadastro.
- Campos de perfil não entram no payload de signup nesta fase.

### Email and Password Rules
- Email deve ser normalizado com `trim` + `lowercase` antes de persistir/consultar.
- Unicidade de email é global e case-insensitive.
- Senha exige mínimo de 8 caracteres nesta fase.

### Error Response Policy (Security-first)
- Login deve retornar erro genérico (sem indicar se usuário existe).
- Signup também deve retornar erro genérico de falha (`cadastro inválido`) em cenários sensíveis como email já existente.
- Evitar mensagens que facilitem enumeração de contas.

### Profile Initialization
- `Profile` é criado automaticamente no signup.
- `Profile` nasce com campos opcionais nulos (sem defaults em string vazia).
- Para esta fase, `Profile` inclui `full_name` e `photo_url`.

### Claude's Discretion
- Estratégia exata de model validation messages internas (desde que resposta externa siga política genérica).
- Estrutura de service objects para criação transacional de `User` + `Profile`.

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `marketplace_backend/app/models/application_record.rb`: base padrão para `User` e `Profile`.
- `marketplace_backend/app/controllers/application_controller.rb`: base API para futuro `AuthController`.
- `marketplace_backend/config/initializers/filter_parameter_logging.rb`: já filtra `email`, `passw`, `token`, `secret`.

### Established Patterns
- App Rails API-only (`config.api_only = true`) com convenções padrão.
- Estrutura ainda minimalista, sem modelos de domínio implementados.
- Testes em Minitest integração (`test/integration/*`).

### Integration Points
- Novos modelos e migrations em `marketplace_backend/app/models` e `marketplace_backend/db/migrate`.
- Rotas futuras de auth serão adicionadas em `marketplace_backend/config/routes.rb` (fora desta fase de fundação JWT).
- Regras de erro e parâmetros passam por `ApplicationController`.

</code_context>

<specifics>
## Specific Ideas

- Política de segurança explícita do usuário: não vazar existência de email em respostas de autenticação/cadastro.
- Fundação de perfil desacoplada de credencial: auth no `User`, dados pessoais no `Profile`.

</specifics>

<deferred>
## Deferred Ideas

- Campo `address` no `Profile` foi explicitamente deferido para fase futura.

</deferred>

---

*Phase: 01-user-and-profile-foundation*
*Context gathered: 2026-03-05*
