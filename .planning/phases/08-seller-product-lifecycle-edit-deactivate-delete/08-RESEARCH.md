# Phase 8: Seller Product Lifecycle (Edit/Deactivate/Delete) - Research

**Date:** 2026-03-06
**Status:** Complete

## Objective

Definir implementação segura do lifecycle privado de produtos (update, deactivate e soft delete), mantendo isolamento multi-tenant estrito e contratos HTTP consistentes.

## Key Findings

### 1. Fundação de produto e authz já habilita lifecycle privado

- `Product` já existe com owner em `user_id`, `active` e validações de domínio.
- `ProductsController#create` já usa autenticação com `current_user` e política fail-closed de payload.
- Conclusão: fase 8 deve reaproveitar o padrão atual (controller leve + service dedicado por ação).

### 2. Regra de ownership exige lookup sempre escopado ao usuário autenticado

- Decisão de contexto da fase: produto de outro vendedor deve retornar `404` (não revelar existência).
- Estratégia consistente: buscar sempre em relação escopada por owner (`current_user.products`) e, para soft delete, ignorar itens já deletados.
- Conclusão: usar um resolvedor de produto próprio por ação reduz risco de vazamento e duplicação de regra.

### 3. Soft delete precisa preparar base para catálogo público futuro

- Delete da fase 8 é lógico com `deleted_at` apenas (sem alterar `active`).
- Isso impacta queries privadas e futuras queries públicas de fase 9/10.
- Conclusão: model deve ter scope para ativos não deletados e serviços devem respeitar esse filtro.

### 4. Contrato de update possui regra específica para `active`

- `PATCH /products/:id` aceita `active` apenas quando `true`.
- `active:false` deve ser recusado no update; desativação é apenas pela rota dedicada.
- Conclusão: service de update precisa regra explícita para evitar bypass da rota de negócio `deactivate`.

### 5. Deactivate idempotente e delete 204

- `PATCH /products/:id/deactivate` deve retornar `200` mesmo já inativo.
- `DELETE /products/:id` deve retornar `204 No Content`.
- Conclusão: contratos de resposta precisam testes específicos para garantir estabilidade para frontend.

## Recommended Implementation Direction

1. Evoluir schema de produtos com `deleted_at` (indexado).
2. Introduzir scope utilitário para produtos não deletados.
3. Implementar `Products::Update`, `Products::Deactivate`, `Products::SoftDelete` com lookup de ownership embutido.
4. Expandir `ProductsController` com `update`, `deactivate`, `destroy` respeitando contratos da fase.
5. Cobrir matriz completa de lifecycle (sucesso, not found/forbidden, idempotência, invalid payload, delete 204).

## Validation Architecture

A fase deve ser validada por integração + serviço:

- update apenas em produto próprio;
- deactivate idempotente em produto próprio;
- soft delete com `deleted_at` e status `204`;
- `404` para produto inexistente ou de outro seller;
- bloqueio de `active:false` no update tradicional;
- regressão completa da suíte para não quebrar fase 7.

## Risks and Mitigations

- **Risco:** vazamento de existência de produto de terceiros.
  - **Mitigação:** lookup escopado por owner e retorno único `404`.

- **Risco:** inconsistência de estado entre `active` e `deleted_at`.
  - **Mitigação:** contratos separados (deactivate vs delete) + testes de invariantes.

- **Risco:** bypass da rota de deactivate via update com `active:false`.
  - **Mitigação:** validação explícita no serviço de update e cobertura de teste negativa.

---

*Phase: 08-seller-product-lifecycle-edit-deactivate-delete*
*Research date: 2026-03-06*
