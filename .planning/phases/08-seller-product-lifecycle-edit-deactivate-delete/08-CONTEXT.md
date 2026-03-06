# Phase 8: Seller Product Lifecycle (Edit/Deactivate/Delete) - Context

**Gathered:** 2026-03-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Esta fase entrega lifecycle privado de produto do vendedor autenticado: editar, desativar e deletar logicamente apenas anúncios próprios.
Escopo funcional: update de produto com checagem de ownership, rota dedicada de deactivate e soft delete com `deleted_at`.

</domain>

<decisions>
## Implementation Decisions

### Endpoint Contract
- Rotas da fase:
  - `PATCH /products/:id` para edição
  - `PATCH /products/:id/deactivate` para desativação dedicada
  - `DELETE /products/:id` para remoção lógica

### Ownership / AuthZ Policy
- Todas as ações privadas exigem usuário autenticado válido.
- Acesso a produto de outro vendedor deve retornar `404` (não vazar existência).
- Backend continua sem confiar em ownership vindo do frontend.

### Update Behavior
- `PATCH /products/:id` permite editar:
  - `title`, `description`, `price`, `stock_quantity`, `active`
- Campo `active` no update:
  - aceita apenas `active: true`
  - `active: false` deve ser recusado no update (desativação só pela rota dedicada)

### Deactivate Behavior
- `PATCH /products/:id/deactivate` é idempotente.
- Se produto já estiver inativo, endpoint ainda retorna sucesso (`200`) mantendo contrato estável.

### Delete Behavior (Soft Delete)
- Delete será lógico com `deleted_at`.
- Não alterar `active` automaticamente no delete (somente `deleted_at`).
- Resposta de delete: `204 No Content`.

### Claude's Discretion
- Forma exata de model scope para ocultar deletados em consultas privadas/públicas futuras.
- Estrutura interna de service/controller para update/deactivate/delete mantendo os contratos acima.

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ProductsController#create` já usa autenticação via `current_user` e fail-closed de payload.
- `Products::Create` já aplica validações/sanitização reutilizáveis para campos editáveis.
- `Product` model já possui validações de domínio e atributo `active`.

### Established Patterns
- Contrato de erro público genérico (`token invalido`, `payload invalido`).
- Policy multi-tenant baseada em owner do token.
- Testes de integração request-level como contrato principal.

### Integration Points
- Expandir `ProductsController` com ações `update`, `deactivate`, `destroy`.
- Adicionar serviços dedicados de lifecycle para separar regras por ação.
- Evoluir schema de produto para incluir `deleted_at` e scopes associados.

</code_context>

<specifics>
## Specific Ideas

- Garantir que `404` seja consistente para produto inexistente e produto de outro seller, evitando enumeração de recursos.
- Manter rota de deactivate explícita para preservar semântica de negócio e auditoria de ações.

</specifics>

<deferred>
## Deferred Ideas

- Auditoria detalhada de quem/quando alterou cada campo do produto.
- Restauração de produto deletado logicamente (undelete).

</deferred>

---

*Phase: 08-seller-product-lifecycle-edit-deactivate-delete*
*Context gathered: 2026-03-06*
