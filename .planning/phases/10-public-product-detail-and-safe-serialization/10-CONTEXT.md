# Phase 10: Public Product Detail and Safe Serialization - Context

**Gathered:** 2026-03-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Esta fase entrega o endpoint público de detalhe do produto em `/public/products/:id` com serializer dedicado e seguro.
Escopo funcional: retornar descrição, preço e estoque disponível sem exposição de dados sensíveis/internos, mantendo contrato estável para frontend.

</domain>

<decisions>
## Implementation Decisions

### Public Visibility and Not Found Masking
- Produto inexistente, inativo ou deletado deve ter a mesma resposta pública.
- Todos esses casos retornam `404 Not Found`.
- Resposta `404` sem body.
- Política de máscara total anti-enumeração: não diferenciar cenários no contrato público.

### Detail Response Contract
- Endpoint retorna envelope `{ "data": { ... } }`.
- Campos públicos permitidos no detalhe:
  - `id`
  - `title`
  - `description`
  - `price`
  - `stock_quantity`
- Não incluir campos extras nesta fase.
- `price` no detalhe deve ser número JSON (não string).

### Public Stock Exposure and Integrity
- Campo público de estoque permanece `stock_quantity`.
- Exposição de estoque será quantidade exata.
- Produto com `stock_quantity = 0` continua visível no detalhe público (`200` com estoque `0`).
- Defesa em camadas obrigatória:
  - serializer público faz clamp mínimo (`>= 0`) para não expor negativo,
  - model mantém validação contra negativos,
  - banco deve ter constraint para prevenir inconsistência/race condition.

### ID Validation and Unknown Params
- UUID malformado no path deve retornar `404 Not Found` (sem `422`).
- UUID válido porém inexistente também retorna `404` sem body.
- Tratamento público idêntico para todos os casos de não encontrado.
- Query params desconhecidos no detalhe devem ser ignorados silenciosamente.

### Claude's Discretion
- Forma exata da mensagem de log interno para casos 404 (sem afetar contrato público).
- Estratégia de implementação da busca pública por `id` com máscara de não encontrado mantendo legibilidade do código.

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `marketplace_backend/app/controllers/public/products_controller.rb`: já possui namespace público e contrato de listagem para reaproveitar padrão de controller.
- `marketplace_backend/app/serializers/products/public_product_serializer.rb`: serializer público já existente para listagem; pode ser evoluído ou separado para detalhe.
- `marketplace_backend/app/models/product.rb`: scope `public_visible` já resolve regra base de visibilidade (`active=true` e `deleted_at=nil`).
- `marketplace_backend/app/services/products/public_listing.rb`: padrão atual de serviço público e validações fail-closed para referência de consistência.

### Established Patterns
- Endpoints públicos sob `/public`.
- Contrato com envelope `data` nos endpoints de catálogo público.
- Respostas de erro públicas minimizam vazamento de informação.
- Multi-tenant e ownership são sempre server-derived nas rotas privadas.

### Integration Points
- `marketplace_backend/config/routes.rb`: adicionar `GET /public/products/:id` apontando para `public/products#show`.
- `marketplace_backend/app/controllers/public/products_controller.rb`: incluir ação `show` sem autenticação.
- `marketplace_backend/app/services/products/*`: adicionar serviço de detalhe público com máscara 404.
- `marketplace_backend/test/integration/*`: cobrir contrato de `show` (sucesso, 404 mascarado, UUID inválido).
- `marketplace_backend/db/migrate/*`: adicionar check constraint de estoque não negativo no banco.

</code_context>

<specifics>
## Specific Ideas

- Contrato público deve ser estável e seguro para consumo por IA/frontend sem revelar estado interno do catálogo.
- Política de `404` sem body foi escolhida para reduzir superfície de enumeração.
- Proteção de estoque negativo deve existir em aplicação e banco para robustez sob concorrência.

</specifics>

<deferred>
## Deferred Ideas

- Campos públicos adicionais no detalhe (ex.: timestamps, status derivado) ficam para fase futura.
- Estratégias de cache/CDN para catálogo público ficam fora desta fase.

</deferred>

---

*Phase: 10-public-product-detail-and-safe-serialization*
*Context gathered: 2026-03-06*
