# Phase 13: Cart State Guards and Abuse Prevention - Context

**Gathered:** 2026-03-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Esta fase reforça guardas de estado para impedir mutações em carrinhos não ativos (`finished`, `abandoned`) e endurece proteção anti-abuso nos endpoints de item.
Escopo funcional: bloquear add/update/remove fora de `active`, manter contratos de erro consistentes e registrar eventos de segurança.

</domain>

<decisions>
## Implementation Decisions

### State Guard Error Policy
- Operações de item (`add`, `update`, `remove`) em carrinho `finished`/`abandoned` retornam `422 payload invalido`.
- Se `cart_item_id` pertence a carrinho não ativo do próprio usuário, resposta também é `422 payload invalido`.
- Para estado inválido, `create/update/delete` devem usar status e mensagem uniformes.
- Guardas de estado devem gerar log estruturado com `user_id`, `cart_id`, `status` e `action`.

### Behavior for No Active Cart
- `POST /cart/items` cria carrinho `active` automaticamente quando usuário não tem carrinho ativo (inclusive se só existirem carrinhos inativos).
- Nunca reabrir carrinhos `finished`/`abandoned` automaticamente.
- Para `PATCH/DELETE /cart/items/:id` sem carrinho ativo, retornar `404 nao encontrado`.

### Anti-Abuse Level
- Nesta fase: guardas de estado + logs estruturados por ação (`add_item`, `update_item`, `remove_item`).
- Tentativas repetidas em carrinho inativo devem acionar resposta de segurança de sessão/token após limiar (revogação/bloqueio da sessão).
- Não implementar rate limiting nesta fase.

### Error Message Contract
- Para estado inválido, mensagem permanece genérica: `payload invalido`.
- Mensagem deve ser uniforme entre create/update/delete quando o motivo é estado de carrinho inválido.
- Para cenários `404` sem carrinho ativo no update/delete, retornar body padrão `{ "error": "nao encontrado" }`.
- Não expor estado real (`finished`/`abandoned`) no body de erro.

### Claude's Discretion
- Estratégia técnica de contagem/limiar para tentativas repetidas em carrinho inativo.
- Local exato de integração com mecanismo de revogação de sessão/token já existente no domínio auth.
- Organização dos serviços/concerns para aplicar guardas sem duplicação de lógica.

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Cart` já possui enum de estados (`active`, `finished`, `abandoned`).
- `CartFinder` e `FindOrCreateActive` já centralizam resolução de carrinho ativo.
- `CartItemsController` e services (`AddItem`, `UpdateItem`, `RemoveItem`) já encapsulam regras atuais de item.
- Domínio auth já possui serviços para revogação de sessão (`Auth::Sessions::RevokeAll`).

### Established Patterns
- Controller fino, validação de domínio em services.
- Contrato de erro genérico (`payload invalido`, `nao encontrado`) para reduzir vazamento de estado interno.
- Máscara tenant em recursos privados com `404` quando fora do escopo do usuário.

### Integration Points
- Endurecer `AddItem`, `UpdateItem`, `RemoveItem` para validar explicitamente estado `active` antes de mutação.
- Adicionar camada de auditoria/segurança para tentativas repetidas em carrinho inativo.
- Cobrir com testes de integração e serviço: carrinho `finished`, `abandoned`, ausência de carrinho ativo, repetição de abuso.

</code_context>

<specifics>
## Specific Ideas

- `POST /cart/items` mantém conveniência de auto-criação de carrinho ativo, mas sem reabrir inativos.
- Bloqueios por estado inválido devem ser previsíveis para frontend via `422 payload invalido`.
- Em update/delete sem carrinho ativo, manter semântica de não encontrado (`404`) para evitar enumeração de itens.

</specifics>

<deferred>
## Deferred Ideas

- Rate limiting por endpoint/IP para cart items (fase futura de hardening de infraestrutura).
- Diferenciação de mensagens de erro por tipo de estado para UX (fora do escopo por política de não exposição).

</deferred>

---

*Phase: 13-cart-state-guards-and-abuse-prevention*
*Context gathered: 2026-03-07*
