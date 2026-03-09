# Phase 20: Order-Linked Ledger and Wallet Provisioning - Context

**Gathered:** 2026-03-09
**Status:** Ready for planning

<domain>
## Phase Boundary

Fechar a rastreabilidade financeira do checkout por referencia agregadora ligada aos pedidos, estruturar recebiveis do seller sem payout real imediato e preparar a liberacao futura de credito ao vendedor apenas quando a entrega for marcada pelo comprador. Esta fase nao cobre workflow completo de status nem implementa bonus de cadastro.

</domain>

<decisions>
## Implementation Decisions

### Buyer debit reference model
- O comprador continua com um unico debito na wallet por checkout.
- Esse debito agregado deve usar uma referencia nova de `checkout_group`.
- O ledger/extrato do comprador deve mostrar uma unica compra, nao varios debitos por `order`.
- `checkout_group` liga internamente o debito agregado aos `order_ids` gerados naquele checkout.

### Checkout group shape
- `checkout_group` deve ser uma entidade persistida propria, e nao apenas metadata solta.
- Cada `Order` gerado no split automatico por seller deve apontar para esse `checkout_group`.
- O debito agregado da wallet do comprador deve referenciar o `checkout_group`, nao um `order_id` individual.

### Seller receivable model
- O seller nao recebe credito real na wallet no checkout.
- O sistema deve criar uma estrutura separada de recebivel do seller, desacoplada da wallet dele.
- O recebivel nasce como `pending` no checkout.
- A visualizacao do seller nesta fase deve mostrar total pendente e lista por pedido.

### Credit release timing
- O recebivel do seller continua `pending` durante `paid`, `in_separation` e `confirmed`.
- O credito real na wallet do vendedor so deve acontecer quando o comprador marcar o pedido como `delivered`.
- Antes disso, cancelamentos/refunds devem reverter o recebivel sem gerar credito na wallet do seller.
- Depois que virar credito real na wallet do seller, nao existe refund automatico neste ciclo; isso entra no fluxo de contestacao posterior.

### Buyer statement UX
- O extrato do comprador deve continuar limpo com uma unica movimentacao por compra agregada.
- A movimentacao agregada deve permitir drill-down de UX para os pedidos relacionados.
- O serializer/contrato de leitura deve expor informacao suficiente para a UI mostrar que aquela compra gerou N pedidos.

### Signup bonus scope
- O bonus de R$ 10,00 nao sera implementado nesta fase.
- Esse credito promocional sera tratado futuramente junto com confirmacao de e-mail.
- O planejamento da fase 20 deve considerar `PAY-02` fora do escopo atual e apontar isso explicitamente.

### Claude's Discretion
- Nome exato da entidade agregadora (`checkout_group`, `order_batch` ou equivalente), desde que seu papel fique claro no dominio.
- Campos auxiliares do extrato do comprador e da lista de recebiveis do seller, desde que preservem rastreabilidade e UX.
- Granularidade interna do recebivel (por `order` ou por `order_item`) se isso nao alterar as decisoes de produto acima.

</decisions>

<specifics>
## Specific Ideas

- O usuario quer que a UX do comprador deixe claro a qual compra/pedidos cada debito agregado pertence.
- O usuario preferiu recebivel separado da wallet do seller ate a entrega ser marcada.
- O usuario decidiu mover o bonus de R$ 10,00 para o futuro fluxo de confirmacao de e-mail.
- O seller deve ver saldo pendente total e lista por pedido, sem necessidade de payout real nesta fase.

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Wallets::Ledger::AppendTransaction` e `Wallets::Operations::ApplyMovement`: ja implementam append-only, idempotencia e validacao de referencias; sao a base para mudar a referencia do buyer de `cart_checkout` para agregador de checkout.
- `WalletTransaction::ALLOWED_METADATA_KEYS`: hoje ja aceita `order_id`, `cart_id` e `checkout_id`; provavelmente precisara evoluir para acomodar a nova referencia agregadora e ligacoes seller/order.
- `Users::Create`: ponto natural para o bonus futuro, mas nesta fase deve permanecer sem credito promocional.
- `Order` e `OrderItem`: criados na fase 19 e prontos para receber referencia ao agregador financeiro do checkout.

### Established Patterns
- Wallet buyer usa ledger append-only e um unico debito por checkout.
- Side effects criticos continuam server-side, com ownership derivado do token e fail-closed.
- O app prefere services dedicados para regras de dominio e controllers finos.

### Integration Points
- O checkout atual ainda registra debito buyer com `reference_type: cart_checkout` e `reference_id: cart.id`; isso deve migrar para a nova referencia agregadora.
- A fase 19 ja criou `Order`s por seller; a fase 20 precisa conectar esses pedidos a uma entidade financeira agregadora.
- Ainda nao existe superficie seller para recebiveis, mas o modelo escolhido aqui deve preparar a fase 22.

</code_context>

<deferred>
## Deferred Ideas

- Bonus de R$ 10,00 no cadastro, condicionado a confirmacao de e-mail.
- Refund automatico depois que o vendedor ja recebeu credito real na wallet.

</deferred>

---

*Phase: 20-order-linked-ledger-and-wallet-provisioning*
*Context gathered: 2026-03-09*
