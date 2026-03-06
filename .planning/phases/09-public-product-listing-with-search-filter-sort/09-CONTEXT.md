# Phase 9: Public Product Listing with Search/Filter/Sort - Context

**Gathered:** 2026-03-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Esta fase entrega listagem pública de produtos em `/public/products` com busca textual, faixa de preço e ordenação.
Escopo funcional: endpoint sem autenticação, retorno seguro para catálogo público e contrato determinístico de filtros/ordenação.

</domain>

<decisions>
## Implementation Decisions

### Public Visibility Rules
- A listagem pública deve retornar **apenas** produtos publicáveis:
  - `active = true`
  - `deleted_at = nil`

### Search Behavior
- Busca textual via parâmetro `q` deve considerar:
  - `title`
  - `description`
- Matching textual será aplicado no conjunto público (nunca em produtos inativos/deletados).

### Sort Behavior
- Ordenações permitidas:
  - `newest`
  - `price_asc`
  - `price_desc`
- Ordenação default (sem parâmetro): `newest`.

### Price Range Filters
- Filtros aceitos:
  - `min_price`
  - `max_price`
- Se `min_price`/`max_price` forem inválidos, retornar `422 payload invalido`.

### Pagination / Response Shape
- Fase 9 será **sem paginação** (simplificação explícita).
- Em ausência de resultados: retornar `200` com `data: []`.
- Resposta deve incluir `meta` com `total` na fase 9.

### Claude's Discretion
- Forma exata da estrutura `meta` além de `total` (desde que não adicione paginação real nesta fase).
- Estratégia de implementação da query (scopes/serviço) mantendo contrato público e determinismo.

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Product` já possui campos necessários para filtragem pública (`title`, `description`, `price`, `active`, `deleted_at`, `created_at`).
- Soft delete já foi estabelecido via `deleted_at` e scope `not_deleted`.
- Padrão de serializer dedicado por contexto já existe no domínio (`Products::PrivateProductSerializer`).

### Established Patterns
- Contratos fail-closed para payload inválido em endpoints da API.
- Organização em `controller + service + serializer + testes de integração`.
- Multi-tenant privado já resolvido; endpoints públicos devem manter exposição mínima de dados.

### Integration Points
- Nova rota pública deve entrar sob namespace `/public/products`.
- Necessário serializer público específico para listagem, separado do serializer privado.
- Testes devem cobrir combinação de filtros, ordenação e vazio com contrato estável.

</code_context>

<specifics>
## Specific Ideas

- Garantir comportamento determinístico quando múltiplos filtros são combinados (`q` + faixa de preço + sort).
- Contrato público deve permanecer estável para integração do frontend e futuras fases (detalhe público na fase 10).

</specifics>

<deferred>
## Deferred Ideas

- Paginação (`page/per_page`) e metadados avançados de navegação.
- Facetas/agregações de catálogo (contagem por faixa/categoria).

</deferred>

---

*Phase: 09-public-product-listing-with-search-filter-sort*
*Context gathered: 2026-03-06*
