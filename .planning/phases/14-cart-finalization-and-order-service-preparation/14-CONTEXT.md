# Phase 14: Cart Finalization and Order Service Preparation - Context

**Gathered:** 2026-03-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Esta fase entrega a finalização do carrinho ativo do comprador com regra de pagamento exclusiva por carteira no site, sem criar pedido ainda.
Também prepara um service de integração para inicialização futura de criação de pedido a partir do carrinho finalizado.

</domain>

<decisions>
## Implementation Decisions

### Finalization Flow
- Finalização opera somente sobre o carrinho `active` do usuário autenticado.
- Ao finalizar com sucesso, carrinho muda de `active` para `finished`.
- Carrinho vazio não pode ser finalizado (retorna `422 payload invalido`).

### Payment Rule (This Milestone)
- Método de pagamento aceito nesta fase: apenas `wallet` (carteira no site).
- Método diferente de `wallet` retorna `422 payload invalido`.
- Contrato de erro permanece genérico, sem detalhar regra interna sensível.

### Order Preparation Service (No Order Creation)
- Fluxo de finalização deve chamar um service de preparação de pedido (ex.: `Orders::PrepareFromCart`).
- Service retorna dados de preparação/metadata para próximo milestone, sem persistir `Order`.
- Nenhuma tabela de pedido é criada nesta fase.

### Tenant and Cross-Cutting
- Usuário autenticado nunca finaliza carrinho de outro usuário.
- Carrinhos `finished`/`abandoned` não devem ser reabertos no fluxo de finalização.
- Controller permanece fino: strong params + delegação para services.

### Claude's Discretion
- Estrutura exata do payload de resposta para confirmação de finalização.
- Estrutura de saída do service de preparação de pedido (campos e objeto retorno).
- Detalhe do lock/transação para garantir transição de status segura em concorrência.

</decisions>

<specifics>
## Specific Ideas

- Criar endpoint dedicado de checkout (ex.: `POST /cart/checkout`) autenticado.
- Criar `Carts::Finalize` para validar estado/itens/pagamento e fazer transição atômica.
- Criar `Orders::PrepareFromCart` com contrato explícito de "prepare only".

</specifics>

<deferred>
## Deferred Ideas

- Criação persistida de pedido (`Order`) e snapshot financeiro definitivo.
- Débito real de carteira/ledger.
- Suporte a métodos de pagamento além de carteira.

</deferred>

---

*Phase: 14-cart-finalization-and-order-service-preparation*
*Context gathered: 2026-03-07*
