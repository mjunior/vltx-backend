# Architecture Research

**Domain:** Orders and post-purchase workflow in Rails API
**Researched:** 2026-03-09
**Confidence:** HIGH

## Standard Architecture

### System Overview

```text
Buyer
  -> CartCheckoutController
    -> Orders::CreateFromCart
      -> stock lock + order snapshot + buyer debit
        -> Order / OrderItem / Wallet ledger

Seller or Buyer
  -> Orders::TransitionsController
    -> Orders::Transition service
      -> workflow guard + audit transition + side effects
        -> refund / stock restore / delivered / contest
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| `Order` | Cabeçalho do pedido | buyer, totals, status espelhado, timestamps |
| `OrderItem` | Snapshot do item comprado | product, seller, quantity, unit price |
| `OrderTransition` or equivalent | Auditoria de workflow | origem, destino, actor, metadata |
| `Orders::CreateFromCart` | Criação atômica do pedido | locks, snapshot, estoque, ledger |
| `Orders::Transition` | Regras de avanço/cancelamento/entrega/contestação | authz + guards + side effects |
| Seller finance query services | Painel de recebíveis/histórico | apenas leitura, escopo por seller |
| `ProductRating` / `SellerRating` | Avaliações elegíveis pós-entrega | score, comment, buyer, target, order item |

## Recommended Project Structure

```text
marketplace_backend/
├── app/controllers/orders/
├── app/models/
│   ├── order.rb
│   ├── order_item.rb
│   ├── order_transition.rb
│   ├── product_rating.rb
│   └── seller_rating.rb
├── app/services/orders/
│   ├── create_from_cart.rb
│   ├── transition.rb
│   └── seller_finance_summary.rb
└── app/services/ratings/
    └── create_from_order_item.rb
```

## Data Flow

1. Checkout
- lock do carrinho e produtos
- cria pedido e itens snapshot
- debita buyer wallet por `order_id`
- registra recebível seller

2. Transition
- valida ator e estado atual
- aplica transição permitida
- executa side effects (`refund`, `restore_stock`, `delivered`, `contested`)

3. Rating
- valida que item foi entregue
- garante unicidade da avaliação elegível
- grava registros separados por produto e vendedor

## Anti-Patterns

- Recalcular total histórico lendo `products.price` depois da compra.
- Guardar apenas `status` no pedido sem trilha de transições.
- Misturar endpoint de atualização genérica com ações de workflow.

## Sources

- Arquitetura já adotada no projeto (services + constraints + authz por token)
- Documentação de `statesman` e `state_machines-activerecord`

---
*Architecture research for: Rails order workflow*
*Researched: 2026-03-09*
