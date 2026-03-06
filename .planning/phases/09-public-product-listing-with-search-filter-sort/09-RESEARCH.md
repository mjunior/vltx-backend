# Phase 9: Public Product Listing with Search/Filter/Sort - Research

**Date:** 2026-03-06
**Status:** Complete

## Objective

Definir implementação do endpoint público de listagem `/public/products` com busca textual, faixa de preço e ordenação determinística, sem autenticação e sem vazamento de dados sensíveis.

## Key Findings

### 1. Domínio de produto já possui campos e estados necessários

- `Product` já contém `title`, `description`, `price`, `active`, `deleted_at`, `created_at`.
- Fase 8 estabeleceu lifecycle privado com soft delete (`deleted_at`) e estado `active`.
- Conclusão: listagem pública pode derivar visibilidade de `active=true` + `deleted_at=nil` sem nova estrutura de dados.

### 2. Endpoints públicos precisam serializer dedicado

- Existe serializer privado (`Products::PrivateProductSerializer`) com campos internos de operação.
- Fase 9 e 10 exigem exposição pública mínima e estável.
- Conclusão: criar serializer público específico para listagem e manter contrato separado do domínio privado.

### 3. Filtros/sort devem ser fail-closed para parâmetros inválidos

- Decisão de contexto: `min_price`/`max_price` inválidos => `422 payload invalido`.
- Ordenação deve aceitar apenas `newest`, `price_asc`, `price_desc`.
- Conclusão: serviço de busca/listagem deve validar query params antes da execução para evitar comportamento implícito.

### 4. Sem paginação nesta fase, mas com `meta.total`

- Contexto trava simplificação sem paginação para fase 9.
- Resposta ainda deve incluir metadado `total` para frontend.
- Conclusão: contrato de resposta será `data` + `meta.total`, com `200` e `data: []` quando vazio.

### 5. Busca textual em title+description

- Busca deve cobrir `title` e `description` no conjunto público.
- Necessário garantir combinação determinística com filtro de preço e sort.
- Conclusão: query builder único (serviço) com ordem de aplicação consistente evita divergências.

## Recommended Implementation Direction

1. Adicionar namespace público no controller (`Public::ProductsController#index`).
2. Criar serviço de listagem pública com validação de params, filtros de visibilidade, busca textual e sort.
3. Criar serializer público de listagem com campos seguros e `meta.total`.
4. Cobrir integração da listagem para: vazio, filtros válidos, filtros inválidos, busca e ordenação.
5. Garantir regressão da suíte completa antes de fechar fase.

## Validation Architecture

A fase deve ser validada por integração + serviço:

- `GET /public/products` sem auth retorna catálogo público filtrado;
- busca por `q` em `title` e `description`;
- faixa `min_price/max_price` válida aplica filtro; inválida retorna `422`;
- ordenação `newest`, `price_asc`, `price_desc` funciona deterministicamente;
- vazio retorna `200` com `data: []` e `meta.total = 0`.

## Risks and Mitigations

- **Risco:** vazamento de produtos não publicáveis (inativos/deletados).
  - **Mitigação:** filtro público centralizado no serviço e testes de exclusão explícita.

- **Risco:** contrato público instável por reutilização de serializer privado.
  - **Mitigação:** serializer dedicado para listagem pública.

- **Risco:** inconsistência quando filtros são combinados.
  - **Mitigação:** testes de integração com múltiplos parâmetros na mesma requisição.

---

*Phase: 09-public-product-listing-with-search-filter-sort*
*Research date: 2026-03-06*
