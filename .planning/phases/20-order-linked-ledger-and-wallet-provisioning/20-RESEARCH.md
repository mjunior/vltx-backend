# Phase 20: Order-Linked Ledger and Wallet Provisioning - Research

**Date:** 2026-03-09
**Status:** Complete

## Objective

Definir como migrar a referencia financeira do checkout atual para uma entidade agregadora persistida, introduzir recebiveis pendentes do seller e preparar a rastreabilidade do fluxo financeiro sem creditar o vendedor antes de `delivered`.

## Key Findings

### 1. `order_id` sozinho nao representa bem o debito agregado do comprador

- A fase 19 consolidou a decisao de `1 debito` para N pedidos splitados por seller.
- Um unico `order_id` no debit agregaria de forma enganosa uma compra com varios pedidos.
- Conclusao: a fase precisa de uma entidade agregadora persistida (`checkout_group` ou equivalente) para representar a compra financeira do comprador.

### 2. Recebivel seller deve ser entidade propria, nao transacao antecipada de wallet

- Creditar a wallet do seller no checkout ou em `confirmed` aumentaria risco de refund/reversao posterior.
- O usuario decidiu que o dinheiro so entra na wallet do seller quando o comprador marcar `delivered`.
- Conclusao: `seller_receivables` pendentes precisam existir separados da wallet, com status explicitos e ligacao ao pedido.

### 3. Ledger buyer continua append-only, mas precisa de nova referencia e metadata mais rica

- Hoje `WalletTransaction` aceita `reference_type/reference_id` e metadata limitada.
- A nova UX do comprador exige uma movimentacao agregada com capacidade de drill-down para pedidos relacionados.
- Conclusao: `reference_type` deve migrar para um tipo agregado de checkout e metadata/serializer precisam acomodar `orders_count` e ligacoes com pedidos sem quebrar o contrato de seguranca.

### 4. Seller finance desta fase e leitura de recebiveis, nao payout

- O milestone ainda nao inclui saque/payout real.
- O usuario quer ver total pendente e lista por pedido, o que combina melhor com query/read models sobre `seller_receivables`.
- Conclusao: a fase deve criar a base de leitura do saldo a receber e adiar qualquer movimentacao real na wallet do seller para a fase 21.

### 5. `PAY-02` saiu do escopo atual por decisao de produto

- O bonus de R$ 10,00 foi movido para um futuro fluxo de confirmacao de e-mail.
- Isso altera o escopo originalmente descrito no roadmap/requisitos.
- Conclusao: a fase 20 deve planejar apenas `PAY-03` e deixar o bonus explicitamente como requisito descopado/futuro.

## Recommended Implementation Direction

1. Criar tabela agregadora de checkout (`checkout_groups`) ligada ao buyer, com total, moeda e relacao 1:N com `orders`.
2. Migrar o debito do comprador para referenciar essa entidade agregadora em vez de `cart_checkout/cart_id`.
3. Evoluir `WalletTransaction` metadata allowlist e serializers para expor informacoes seguras do agrupamento de pedidos.
4. Criar tabela `seller_receivables` com `order_id`, `seller_id`, `buyer_id`, `checkout_group_id`, `amount_cents` e status (`pending`, `reversed`, `credited`).
5. Registrar recebiveis pendentes no checkout, sem criar `credit` na wallet do seller nesta fase.
6. Preparar services/queries que retornem ao seller total pendente e lista por pedido, mantendo authz por token para fases futuras.

## Validation Architecture

A fase deve ser validada com testes de model/service/integration:

- `checkout_group` e `seller_receivable` validam vinculos, valores monetarios e estados permitidos;
- checkout passa a registrar o debito buyer com referencia agregadora e metadados consistentes;
- pedidos gerados no checkout ficam ligados ao agrupador financeiro correto;
- recebiveis seller nascem `pending` e nao geram credito na wallet do seller nesta fase;
- leitura de saldo a receber consegue derivar total pendente e lista por pedido sem expor dados cross-tenant.

## Risks and Mitigations

- **Risco:** manter `cart_id` como referencia principal e perder rastreabilidade da compra agregada.
  - **Mitigacao:** introduzir entidade agregadora persistida e migrar o ledger buyer para ela.

- **Risco:** confundir recebivel com saldo disponivel do seller.
  - **Mitigacao:** modelo separado com status explicitos e sem credit na wallet do seller.

- **Risco:** metadata de wallet crescer sem contrato claro e vazar detalhes indevidos.
  - **Mitigacao:** ampliar allowlist com campos estritamente necessarios e cobrir serializer/read contract por testes.

- **Risco:** `PAY-02` voltar implicitamente por inercia do roadmap antigo.
  - **Mitigacao:** remover o bonus do escopo da fase e documentar isso nos planos e resumos.

---

*Phase: 20-order-linked-ledger-and-wallet-provisioning*
*Research date: 2026-03-09*
