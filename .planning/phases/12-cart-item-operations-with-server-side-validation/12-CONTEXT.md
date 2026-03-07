# Phase 12: Cart Item Operations with Server-Side Validation - Context

**Gathered:** 2026-03-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Esta fase entrega operações de item do carrinho ativo (`add`, `update quantity`, `remove`) com validação server-side de `product_id`, `quantity` e preço derivado do banco.
Escopo funcional: não confiar em payload sensível do frontend, operar de forma transacional e bloquear compra de produto próprio.

</domain>

<decisions>
## Implementation Decisions

### Item Endpoint Contract
- Adição de item: `POST /cart/items` com payload `{ "cart_item": { "product_id", "quantity" } }`.
- Atualização de quantidade: `PATCH /cart/items/:id` com payload `{ "cart_item": { "quantity" } }`.
- Remoção de item: `DELETE /cart/items/:id`.
- Identificação de item por `cart_item.id` (UUID próprio), não por `product_id` no path.

### Quantity Rules
- Quantidade aceita: inteiro JSON no intervalo `1..999_999`.
- `quantity = 0` no update deve ser rejeitado com `422 payload invalido` (não remove implicitamente).
- Se quantidade solicitada exceder estoque disponível, backend ajusta automaticamente para o máximo disponível (clamp para estoque atual).

### Price and Subtotal Policy
- Carrinho **não** salva snapshot de preço no `cart_item` nesta fase; preço é sempre derivado do `Product` atual.
- Se vendedor alterar preço, carrinho reflete o preço atualizado.
- Se frontend enviar `price` no payload, campo é ignorado silenciosamente.
- Subtotal do carrinho é sempre recalculado server-side a partir dos itens do carrinho.

### Error and Anti-Fraud Policy
- Produto próprio no `add item` retorna `422 payload invalido`.
- Produto inativo/deletado no `add item` retorna `422 payload invalido`.
- `product_id` malformado ou inexistente retorna `422 payload invalido`.
- `update/delete` de item fora do carrinho ativo do usuário retorna `404 nao encontrado` (máscara tenant).

### Claude's Discretion
- Nomenclatura final de `CartItem` e services (add/update/remove) seguindo convenções do projeto.
- Estratégia transacional exata para aplicar clamp de quantidade mantendo consistência.
- Forma do serializer de carrinho com subtotal recalculado sem expor campos sensíveis.

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `CartsController` já implementa autenticação obrigatória e validação fail-closed de payload.
- `Carts::FindOrCreateActive` já centraliza obtenção do carrinho ativo com `current_user`.
- `Products::Create` e `Products::Update` já têm padrões reutilizáveis de normalização de quantidade/preço e bloqueio de campos proibidos.
- `ApplicationController` padroniza contratos de erro (`token invalido`, `payload invalido`).

### Established Patterns
- Controller fino, regra de domínio em service.
- Ownership sempre derivado do token; frontend não escolhe alvo de recurso privado.
- Recursos de outro tenant mascarados com `404` em endpoints privados.
- Testes de integração request-level como contrato principal da API.

### Integration Points
- Criar domínio `CartItem` com associação a `Cart` e `Product`.
- Expandir `CartsController` com ações de item ou criar `CartItemsController` mantendo namespace privado.
- Integrar validações de item com `Product.not_deleted` e estado `active`.
- Atualizar serializer de carrinho para refletir subtotal server-side dinâmico.
- Cobrir casos negativos em testes de integração: payload forjado, produto próprio, item de outro tenant, estoque insuficiente.

</code_context>

<specifics>
## Specific Ideas

- Frontend deve enviar no add/update apenas `product_id` e `quantity` (ou só `quantity` no update).
- Preço no carrinho deve acompanhar alteração do produto enquanto pedido não é criado.
- Snapshot de preço fica para fase de criação de pedido, não para a fase 12.

</specifics>

<deferred>
## Deferred Ideas

- Snapshot de preço no momento da criação do pedido (fase de pedido/checkout), em vez de snapshot no carrinho.
- Estratégias de confirmação explícita de mudança de preço para UX (fora do escopo técnico da fase 12).

</deferred>

---

*Phase: 12-cart-item-operations-with-server-side-validation*
*Context gathered: 2026-03-07*
