# Phase 7: Seller Product Creation (Owner Derived from Token) - Research

**Date:** 2026-03-06
**Status:** Complete

## Objective

Definir abordagem segura para criação de produtos por vendedor autenticado, com owner derivado do token e bloqueio explícito de `owner_id/user_id` no payload.

## Key Findings

### 1. Base de autenticação já está pronta para endpoints privados

- `ApplicationController#authenticate_user!` já resolve `current_user` via JWT.
- Contratos de erro público estão padronizados (`token invalido`, `payload invalido`).
- Conclusão: endpoint de criação pode seguir o mesmo padrão de profile/auth sem inventar novo fluxo.

### 2. Arquitetura atual favorece controller leve + service de domínio

- Fases anteriores consolidaram padrão `Controller -> Service -> Serializer`.
- `Users::Create` e `Profiles::UpdateProfile` já usam `Result` object simples para sucesso/falha.
- Conclusão: criação de produto deve concentrar regras de validação/sanitização em serviço dedicado.

### 3. Requisitos de segurança da fase exigem fail-closed no payload

- Contexto da fase travou que `owner_id/user_id` enviados pelo frontend devem causar `422 payload invalido`.
- Isso exige allowlist estrita de chaves aceitas no JSON de entrada.
- Conclusão: controller deve validar chaves antes de chamar serviço para reduzir superfície de ambiguidade.

### 4. Validação de campos precisa combinar regra de negócio e anti-abuso

- Limites decididos: `stock_quantity <= 999_999`, `price <= 9_999_999`.
- `price` precisa ser decimal estrito (até 2 casas) e maior que zero.
- Conclusão: validação deve ser explícita (tipo + faixa + formato), sem coerções silenciosas perigosas.

### 5. Segurança de conteúdo para descrição

- `description` precisa ser tratada como texto seguro sem HTML executável.
- Estratégia recomendada para fase: sanitizar/remover tags HTML e validar resultado final para cumprir limites.
- Conclusão: serviço deve normalizar e sanitizar texto antes de persistir.

## Recommended Implementation Direction

1. Adicionar entidade `Product` ligada a `User` (owner) por UUID.
2. Criar `POST /products` com root `product`, autenticado, usando owner do token.
3. Rejeitar payloads com chaves proibidas (incluindo `owner_id/user_id`) com `422 payload invalido`.
4. Implementar `Products::Create` com validações de domínio e sanitização da descrição.
5. Responder com serializer privado que não exponha `owner_id`.
6. Cobrir sucesso + matriz negativa (auth, payload malicioso, owner forging, limites de campos).

## Validation Architecture

A fase deve ser validada por integração + serviço:

- sucesso de criação com contrato HTTP `201`;
- recusa sem token / token inválido;
- recusa para payload com `owner_id/user_id`;
- recusa para violações de limites (`price`, `stock_quantity`, tamanhos);
- sanitização de descrição contra HTML/injection;
- garantia de que owner persistido é sempre `current_user`.

## Risks and Mitigations

- **Risco:** coerção indevida de tipos (`price`/`stock_quantity`) gerar comportamento inesperado.
  - **Mitigação:** validação estrita de tipo/escala/faixa com testes negativos.

- **Risco:** vazamento de campo sensível (`owner_id`) no retorno.
  - **Mitigação:** serializer dedicado de criação sem owner no payload público.

- **Risco:** bypass de multi-tenant via parâmetros extras.
  - **Mitigação:** allowlist estrita no controller + teste explícito de owner forging.

---

*Phase: 07-seller-product-creation-owner-derived-from-token*
*Research date: 2026-03-06*
