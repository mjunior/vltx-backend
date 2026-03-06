# Phase 7: Seller Product Creation (Owner Derived from Token) - Context

**Gathered:** 2026-03-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Esta fase entrega a criação de anúncio do vendedor autenticado com ownership derivado exclusivamente do token.
Escopo funcional: criação de produto privado com `title`, `description`, `price`, `stock_quantity`, sem aceitar `owner_id/user_id` do frontend.

</domain>

<decisions>
## Implementation Decisions

### Endpoint Contract
- Endpoint de criação será `POST /products`.
- Payload deve usar root `product`.
  - Exemplo esperado: `{ "product": { ... } }`.

### Product Validation Rules
- Campos obrigatórios na criação:
  - `title`
  - `description`
  - `price`
  - `stock_quantity`
- Regras acordadas:
  - `title`: obrigatório, tamanho 3..120
  - `description`: obrigatório, tamanho 10..2000
  - `price`: obrigatório, maior que 0, no máximo 2 casas decimais, teto `9_999_999`
  - `stock_quantity`: obrigatório, inteiro >= 0, teto `999_999` (anti-abuso)

### Initial Product State
- Produto nasce **ativo** por padrão no momento da criação.

### AuthZ / Anti-Forgery Policy
- Backend deve derivar owner exclusivamente do usuário autenticado (`current_user`).
- Se payload incluir `owner_id`, `user_id` ou equivalentes, a API deve rejeitar com `422 payload invalido`.

### Content Safety
- `description` deve ser tratada como conteúdo sem HTML executável.
- Payload com tentativa de injeção/HTML perigoso deve ser tratado por validação/sanitização segura sem abrir brecha de execução.

### Claude's Discretion
- Estrutura interna de service/serializer/model/controller para criação.
- Técnica exata de sanitização e validação de conteúdo, mantendo o contrato de segurança definido acima.

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ApplicationController#authenticate_user!` e `current_user` já padronizam autenticação por bearer token.
- `ApplicationController#render_invalid_payload` já define contrato de erro público (`422 payload invalido`).
- Padrão de controllers + services + serializers já existe em `ProfilesController` e domínio `Auth::*`.

### Established Patterns
- Ownership e autorização sempre derivadas do token, nunca do payload do frontend.
- Contratos de erro genéricos/fail-closed já adotados nas fases anteriores.
- Testes de integração request-level são fonte primária de contrato HTTP.

### Integration Points
- Nova rota privada de criação entrará em `config/routes.rb`.
- Modelo de produto deve se conectar a `User` via owner derivado do token.
- Suite de testes deve cobrir: sucesso, validações, payload malicioso e owner forging.

</code_context>

<specifics>
## Specific Ideas

- Garantir que o contrato de criação seja previsível para frontend (`POST /products` com root `product`) e seguro para multi-tenant.
- Endurecer validações de `stock_quantity` e `price` para reduzir abuso de endpoint.

</specifics>

<deferred>
## Deferred Ideas

- Moderação avançada de conteúdo e classificação automática de texto.
- Upload e gestão de mídia de produto (imagens/arquivos).

</deferred>

---

*Phase: 07-seller-product-creation-owner-derived-from-token*
*Context gathered: 2026-03-06*
