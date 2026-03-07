# Phase 11: Cart Foundation and Active-Cart Invariant - Context

**Gathered:** 2026-03-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Esta fase entrega a fundação do carrinho com autenticação obrigatória, unicidade de carrinho ativo por usuário e isolamento tenant estrito.
Escopo funcional: obter/criar carrinho ativo do usuário logado sem confiar em `user_id` do frontend, com proteção contra acesso cross-tenant.

</domain>

<decisions>
## Implementation Decisions

### Endpoint Contract (Active Cart)
- Endpoint principal será `POST /cart` com comportamento idempotente para obter/criar carrinho ativo.
- Quando o usuário já possui carrinho `active`, o endpoint retorna `200` com o mesmo carrinho.
- Shape de sucesso: `{ "data": { "cart": ... } }`.
- Resposta incluirá campos base do carrinho e resumo estrutural (`total_items`, `subtotal`) já na fase 11.
- O resumo financeiro nesta fase é apenas estrutural (inicialmente zero, sem regras completas de item/preço).

### Authorization and Error Policy
- Tentativa de acesso a carrinho de outro usuário deve retornar `404` (máscara de recurso).
- `cart_id` inválido/malformado também retorna `404` para manter contrato uniforme e anti-enumeração.
- Body de erro para não encontrado: `{ "error": "nao encontrado" }`.
- Tentativas cross-tenant devem gerar log interno com `user_id` autenticado e `cart_id` alvo.

### Active-Cart Uniqueness and Concurrency
- Garantia de um único carrinho `active` por usuário via restrição no banco (índice único parcial) + transação.
- Em corrida de criação simultânea, fluxo deve reler e devolver o carrinho ativo já existente (não falhar para o cliente).
- Carrinhos `finished`/`abandoned` não devem ser reabertos automaticamente.
- Anti-abuso na fase 11: aplicar unicidade + logs de tentativa duplicada.

### Cart Status Model
- Modelo já nasce com estados de domínio `active`, `finished`, `abandoned`.
- Status inicial de criação é sempre `active`.
- Fase 11 não expõe transições públicas de status; transições ficam para fases posteriores.
- Status não deve ser exposto no payload de resposta desta fase (interno por enquanto).

### Claude's Discretion
- Nome final de models/services/controllers/serializers do domínio de carrinho.
- Estratégia exata de lock/retry na colisão de criação, desde que preserve idempotência e unicidade.
- Definição técnica do resumo estrutural (`total_items`/`subtotal`) mantendo compatibilidade para fase 12.

</decisions>

<specifics>
## Specific Ideas

- Backend continua com controller fino e regra de negócio concentrada em services.
- Frontend não envia `user_id` em nenhum fluxo de criação/obtenção de carrinho.
- Contrato de erro deve permanecer consistente com padrão já usado em produtos privados (`nao encontrado` para mascaramento).

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ApplicationController#authenticate_user!` e `current_user`: base pronta para garantir que apenas usuário autenticado opere carrinho.
- Padrão de payload e fail-closed em controllers privados (ex.: `ProductsController#valid_payload_shape?`).
- Padrão de services por domínio (`Products::*`, `Profiles::*`) para concentrar validação e regras de negócio.
- Contratos de erro já estabilizados: `token invalido`, `payload invalido`, `nao encontrado`.

### Established Patterns
- Ownership sempre derivado do token (nunca do frontend).
- Recursos de outro tenant mascarados com `404` em endpoints privados.
- Controllers sem lógica de domínio; service executa validação e mutação.
- Testes de integração request-level como contrato principal da API.

### Integration Points
- `config/routes.rb`: nova rota privada de carrinho ativo (`POST /cart`).
- Novo domínio em `app/models` e `app/services` para `Cart` e possível serializer privado.
- Migração para tabela de carrinhos com `user_id` (FK), `status` e timestamps.
- Migração para índice único parcial por `user_id` quando `status = active`.
- Testes em `test/integration` cobrindo autenticação obrigatória, idempotência e isolamento cross-tenant.

</code_context>

<deferred>
## Deferred Ideas

- Revogação/invalidação de sessão/token ao detectar tentativa cross-tenant: tratar em fase própria de security incident handling (escopo adicional ao Phase 11).
- Rate limiting de endpoints de carrinho: fase futura de hardening.

</deferred>

---

*Phase: 11-cart-foundation-and-active-cart-invariant*
*Context gathered: 2026-03-07*
