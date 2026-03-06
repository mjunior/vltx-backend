# Phase 6: Profile Self-Service and AuthZ Guardrails - Context

**Gathered:** 2026-03-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Esta fase entrega edição de perfil próprio com autenticação obrigatória e enforcement multi-tenant estrito.
Escopo funcional: atualização de `name` e `address` do perfil do usuário autenticado, sem permitir targeting por `id` de outro usuário.

</domain>

<decisions>
## Implementation Decisions

### Endpoint Contract
- Rota de atualização do perfil próprio será `PATCH /profile`.
- Endpoint não aceita identificador de usuário no path (`:id`) para evitar vetores cross-tenant.

### Payload Shape
- Campo `address` será `string` simples nesta fase.
- Campos editáveis na fase: `name` e `address`.

### AuthZ and Error Policy
- Manter contrato de erro genérico atual para falhas de autenticação/autorização (`401 token invalido`).
- Não expor detalhes de ownership ou diferenças entre "não existe" e "não autorizado" no contrato público desta fase.

### Update Semantics
- Semântica PATCH parcial:
  - campos enviados são atualizados,
  - ausência de campo mantém valor atual,
  - `null` limpa o campo correspondente.

### UUID Strategy (Locked)
- Adotar UUID global para entidades do sistema (incluindo legadas e novas).
- Não há exigência de retrocompatibilidade de IDs numéricos.
- É permitido reset de banco (drop + recreate + seed) para viabilizar migração.

### Claude's Discretion
- Nome interno dos serviços/serializers/controllers e organização de arquivos.
- Estratégia exata de migration UUID (desde que cumpra decisão de reset sem retrocompat).

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Auth::Jwt::AccessSubject` já resolve usuário autenticado a partir do bearer token.
- `ApplicationController` já possui renderização padronizada de erros (`token invalido`, `payload invalido`).
- Model `Profile` já existe e pertence a `User` (1:1).

### Established Patterns
- Contrato público de erro genérico e sem vazamento de detalhe interno.
- Fluxos autenticados usam usuário derivado do token, não de parâmetros do frontend.

### Integration Points
- Novo endpoint privado de perfil deve integrar com middleware/controller auth já existente.
- Testes de integração devem seguir padrão atual da suíte auth para cenários positivos e negativos.

</code_context>

<specifics>
## Specific Ideas

- Endpoint deve ser simples para o frontend (`PATCH /profile`) e semanticamente alinhado a "perfil do usuário logado".
- Reforçar via testes que payload com `user_id`/`owner_id` (ou equivalentes) não controla alvo da atualização.

</specifics>

<deferred>
## Deferred Ideas

- Estruturação avançada de endereço (JSON com rua/cidade/CEP) fica para fase futura.
- Diferenciação semântica entre `401` e `403` não entra nesta fase.

</deferred>

---

*Phase: 06-profile-self-service-and-authz-guardrails*
*Context gathered: 2026-03-06*
