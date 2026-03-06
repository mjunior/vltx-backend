# Phase 6: Profile Self-Service and AuthZ Guardrails - Research

**Date:** 2026-03-06
**Status:** Complete

## Objective

Definir abordagem segura para atualização de perfil próprio com autenticação obrigatória, enforcement multi-tenant e preparação para transição global para UUID.

## Key Findings

### 1. Auth guard reutilizável já existe

- O projeto já possui `Auth::Jwt::AccessSubject` para resolver usuário pelo bearer token.
- Controllers atuais (`auth/logout`) seguem padrão de retorno genérico `401 token invalido` quando auth falha.
- Conclusão: criar helper de autenticação no `ApplicationController` para evitar duplicação em endpoints privados.

### 2. Contrato de erro e payload deve seguir padrão existente

- Mensagens públicas já consolidadas:
  - `token invalido` (401)
  - `payload invalido` (422)
- Para fase 6, isso deve ser mantido inclusive em tentativas cross-tenant para não vazar estado de ownership.

### 3. Endpoint correto para escopo próprio

- Decisão de contexto: `PATCH /profile` (sem `:id`).
- Isso reduz superfície de ataque e impede targeting explícito de outro usuário por rota.

### 4. PATCH parcial com limpeza explícita

- Decisão de contexto:
  - campos ausentes => mantêm valor atual,
  - `null` => limpa campo,
  - campos permitidos: `name`, `address`.
- Como model atual usa `full_name`, será necessário mapear contrato público (`name`) para persistência interna.

### 5. UUID global sem retrocompatibilidade

- Contexto da fase define migração global para UUID com reset de banco permitido.
- Estratégia mais segura para v1.1: recriar estrutura de DB para UUID e ajustar FKs de `profiles` e `refresh_sessions` desde a base da migration.

## Recommended Implementation Direction

1. Criar endpoint privado `PATCH /profile` com autenticação via bearer token.
2. Implementar update profile service/controller sem aceitar `user_id`/`owner_id` do payload.
3. Expor resposta com serializer próprio de perfil (somente campos públicos necessários).
4. Cobrir authz e payload negativo com request/integration tests.
5. Preparar migrações UUID-first para evitar dívidas de identidade no restante da milestone.

## Validation Architecture

A fase deve ser validada por combinação de testes de integração + serviço, garantindo:

- sucesso em update do próprio perfil,
- recusa sem token,
- recusa com token inválido,
- recusa/ignorância de campos de owner forjado,
- semântica PATCH parcial + limpeza por `null`.

## Risks and Mitigations

- **Risco:** regressão no contrato atual de erros.
  - **Mitigação:** testes explícitos para `401 token invalido` e `422 payload invalido`.

- **Risco:** inconsistência entre `name` do contrato e `full_name` no model.
  - **Mitigação:** mapear no serializer/service e travar com testes de contrato.

- **Risco:** impacto da mudança UUID em entidades existentes.
  - **Mitigação:** executar reset de banco e garantir que migrations reflitam UUID desde criação das tabelas.

---

*Phase: 06-profile-self-service-and-authz-guardrails*
*Research date: 2026-03-06*
