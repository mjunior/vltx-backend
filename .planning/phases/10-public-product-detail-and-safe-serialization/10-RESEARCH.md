# Phase 10: Public Product Detail and Safe Serialization - Research

**Date:** 2026-03-06
**Status:** Complete

## Objective

Definir implementação do endpoint público de detalhe `/public/products/:id` com contrato seguro e estável, incluindo serialização pública dedicada e política anti-enumeração para não encontrado.

## Key Findings

### 1. Base pública da fase 9 já reduz esforço de integração

- O namespace público já existe em `Public::ProductsController#index`.
- O modelo `Product` já possui scope `public_visible` (`active=true` + `deleted_at=nil`).
- Conclusão: o detalhe pode reaproveitar o mesmo filtro de visibilidade e manter consistência entre listagem e show.

### 2. Contrato de erro foi travado para mascaramento total

- Contexto da fase 10 define resposta única para inexistente/inativo/deletado.
- UUID malformado também deve retornar `404` sem body.
- Conclusão: a busca do detalhe precisa ser fail-closed e evitar qualquer distinção pública de causa de ausência.

### 3. Serializer público de detalhe precisa contrato próprio

- A listagem atual serializa `price` como string (`to_s("F")`), mas fase 10 exige `price` numérico no detalhe.
- Campos permitidos no detalhe foram travados: `id`, `title`, `description`, `price`, `stock_quantity`.
- Conclusão: criar serializer público específico de detalhe evita regressão na listagem e estabiliza o contrato para frontend.

### 4. Integridade de estoque deve ser reforçada em três camadas

- Model já valida `stock_quantity >= 0`, mas decisão exige defesa adicional.
- Serializer do detalhe deve aplicar clamp mínimo `0` para não expor valor negativo.
- Banco deve receber check constraint para impedir dados inválidos sob concorrência/race.
- Conclusão: combinar validação de aplicação + constraint de banco + serialização defensiva.

### 5. Testes de contrato precisam cobrir segurança e não-vazamento

- Cenários mandatórios: sucesso público, `404` mascarado (inexistente/inativo/deletado/UUID inválido), envelope `data`, tipagem de `price` numérica.
- Query params desconhecidos devem ser ignorados silenciosamente.
- Conclusão: reforçar testes de integração do endpoint público e testes de serializer para blindar contrato.

## Recommended Implementation Direction

1. Adicionar `GET /public/products/:id` em `routes.rb` apontando para `public/products#show`.
2. Implementar `show` no `Public::ProductsController` delegando para serviço de detalhe com política 404 mascarada.
3. Criar `Products::PublicProductDetail` (serviço) responsável por validação de UUID e busca em `public_visible`.
4. Criar `Products::PublicProductDetailSerializer` com contrato fixo e `price` numérico + clamp defensivo de estoque.
5. Adicionar migration com check constraint (`stock_quantity >= 0`) e cobertura automatizada de contrato público.

## Validation Architecture

A fase deve ser validada por integração + serviço/serializer:

- `GET /public/products/:id` sem autenticação retorna `200` com `{ data: {...} }` para produto público válido;
- retorno contém apenas `id`, `title`, `description`, `price` (número), `stock_quantity`;
- inexistente/inativo/deletado/UUID inválido retornam `404` sem body;
- query params desconhecidos não quebram contrato;
- clamp defensivo garante `stock_quantity >= 0` no payload público;
- constraint de banco impede persistência futura de estoque negativo.

## Risks and Mitigations

- **Risco:** divergência de contrato entre listagem e detalhe sobre tipo de `price`.
  - **Mitigação:** serializer dedicado de detalhe e testes explícitos de tipo numérico.

- **Risco:** enumeração de catálogo por diferença de erro.
  - **Mitigação:** política uniforme de `404` sem body para todos os casos não encontrados.

- **Risco:** inconsistência de estoque por concorrência.
  - **Mitigação:** check constraint no banco + validação de model + serialização defensiva.

---

*Phase: 10-public-product-detail-and-safe-serialization*
*Research date: 2026-03-06*
