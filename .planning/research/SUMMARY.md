# Project Research Summary

**Project:** Marketplace Backend
**Domain:** Orders, fulfillment workflow, seller settlement, and ratings
**Researched:** 2026-03-09
**Confidence:** HIGH

## Executive Summary

Este milestone precisa fechar três lacunas do app atual: pedido persistido, workflow seguro de pós-compra e trilha financeira completa por `order_id`. O app já tem carrinho e ledger fortes; falta conectar isso a um domínio de pedido auditável.

Para o fluxo de status, a recomendação é usar uma camada explícita de workflow. Entre as referências atuais do ecossistema Rails/Ruby, `Statesman` é a opção mais alinhada ao risco descrito pelo usuário porque separa transições em tabela própria e favorece auditoria. `state_machines-activerecord` continua sendo a segunda melhor opção se a equipe quiser uma DSL mais direta.

As avaliações devem ficar em registros separados por produto e por vendedor, sempre vinculadas ao item comprado e entregue. Isso reduz fraude e simplifica médias futuras.

## Key Findings

### Recommended Stack

- Rails 8 + PostgreSQL + services transacionais continuam suficientes
- Workflow explícito para `Order`
- Ledger buyer/seller referenciado por `order_id`

### Table Stakes

- `Order`/`OrderItem` persistidos com snapshot
- Estoque decrementado no checkout e restaurado no cancelamento elegível
- Pagamento wallet-only
- Refund automático idempotente
- Seller avança etapas sem pular estado
- Buyer marca entregue, contesta depois e avalia pós-entrega

### Watch Out For

1. `status` controlado por payload do cliente
2. Ledger ainda preso a `cart_id`
3. Rating sem checagem de compra entregue
4. Recebível seller modelado como payout final cedo demais

## Implications for Roadmap

### Phase 19: Order Persistence and Stock Integrity
Criar base durável do pedido com snapshot e estoque.

### Phase 20: Order-Linked Ledger and Wallet Provisioning
Trocar referência financeira para `order_id` e provisionar crédito inicial.

### Phase 21: Secure Order Workflow and Cancellation Refunds
Aplicar transições autorizadas, cancelamento buyer e refund seguro.

### Phase 22: Seller Finance Surface, Contestation, and Ratings
Fechar experiência financeira seller e pós-entrega.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Compatível com Rails 8 e o estilo atual do app |
| Features | HIGH | Escopo fornecido com critérios claros |
| Architecture | HIGH | Reusa service layer existente |
| Pitfalls | HIGH | Principais brechas estão mapeadas |

**Overall confidence:** HIGH

---
*Research completed: 2026-03-09*
*Ready for roadmap: yes*
