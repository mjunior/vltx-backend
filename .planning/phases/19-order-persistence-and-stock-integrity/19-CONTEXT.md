# Phase 19: Order Persistence and Stock Integrity - Context

**Gathered:** 2026-03-09
**Status:** Ready for planning

<domain>
## Phase Boundary

Transformar o checkout atual em criacao real de pedido com snapshot imutavel e consistencia de estoque. Esta fase cobre persistencia de `Order` e `OrderItem`, split automatico por seller no checkout, pagamento wallet-only e falha fechada quando estoque nao puder ser garantido.

</domain>

<decisions>
## Implementation Decisions

### Order grouping at checkout
- O carrinho continua sendo unico no dominio atual.
- No checkout, o backend faz split automatico por `seller_id`.
- Um checkout pode gerar multiplos `Order`s, um por seller.
- Cada `Order` tera apenas `OrderItem`s do seller correspondente.

### Buyer wallet charging model
- O comprador sofre um unico debito total na wallet por operacao de checkout.
- Mesmo com multiplos pedidos gerados, o extrato do comprador nao deve mostrar multiplos debitos para a mesma compra.
- Refunds futuros acontecerao parcialmente por `order_id`, sem exigir um debito separado por pedido.

### Stock failure behavior
- Se qualquer item estiver sem estoque suficiente no momento do checkout, o checkout inteiro falha.
- Nao deve haver ajuste automatico de quantidade.
- Nao deve haver sucesso parcial de apenas alguns sellers ou itens.

### Checkout response contract
- `POST /cart/checkout` deve responder com os IDs dos pedidos criados e um resumo da operacao.
- O endpoint nao precisa retornar o payload completo dos pedidos nesta fase.

### Cart state after successful checkout
- O carrinho continua no estado `finished`.
- Os itens do carrinho devem ser limpos apos a geracao bem-sucedida dos pedidos.
- O pedido passa a ser a fonte principal de verdade para itens comprados.

### Claude's Discretion
- Formato exato do resumo retornado pelo checkout, desde que inclua identificadores suficientes para o frontend seguir o fluxo.
- Nome das chaves do payload de resposta, desde que mantenham contrato consistente e sem dados redundantes.
- Detalhes de timestamps e campos auxiliares do pedido, desde que o snapshot seja suficiente para historico e auditoria.

</decisions>

<specifics>
## Specific Ideas

- O usuario quer split automatico por seller no checkout, e nao dividir o carrinho fisicamente neste momento.
- O usuario quer evitar varios debitos no extrato do comprador para uma unica finalizacao.
- O usuario preferiu resposta enxuta do checkout: IDs dos pedidos e resumo, sem pedido completo.

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `CartCheckoutController`: ja valida payload `wallet` only e ownership derivado do token; deve continuar sendo o ponto de entrada do checkout.
- `Carts::Finalize`: hoje orquestra lock do carrinho, transicao para `finished` e debito da wallet; e o principal ponto de integracao para virar criacao real de pedido.
- `Orders::PrepareFromCart`: ja serializa snapshot preliminar de itens e totais; pode ser evoluido para alimentar `Order` e `OrderItem`.
- `Wallets::Operations::ApplyMovement`: ja oferece debito seguro e idempotente; deve continuar sendo reutilizado para a cobranca do comprador.
- `Product` + constraint `stock_quantity >= 0`: base para aplicar decremento de estoque com validacao e lock.

### Established Patterns
- Ownership de recursos privados sempre vem do token, nunca de IDs enviados pelo cliente.
- Operacoes financeiras e mutacoes criticas usam services transacionais e fail-closed.
- Testes principais do dominio sao em Minitest, com combinacao de integration tests e service tests.

### Integration Points
- Checkout atual retorna `cart` + `order_preparation`; isso precisara mudar para IDs de pedidos + resumo.
- Schema atual nao possui `orders` ou `order_items`; a fase precisara introduzir essas tabelas e conectar ao carrinho/produto/usuario.
- O carrinho hoje termina como `finished`; a nova implementacao deve preservar essa semantica enquanto limpa os itens apos sucesso.

</code_context>

<deferred>
## Deferred Ideas

- Expor agrupamento visual/logico por seller na API do carrinho antes do checkout. Isso pode ser util, mas nao faz parte da fase 19.

</deferred>

---

*Phase: 19-order-persistence-and-stock-integrity*
*Context gathered: 2026-03-09*
