# Phase 19: Order Persistence and Stock Integrity - Research

**Date:** 2026-03-09
**Status:** Complete

## Objective

Definir como evoluir o checkout atual para criar pedidos persistidos com snapshot imutavel, split automatico por seller, um unico debito wallet-only no comprador e estoque consistente sob retry/concorrencia.

## Key Findings

### 1. `Order` e `OrderItem` precisam ser a fonte historica, nao o carrinho

- O checkout atual termina em `cart.finished` e devolve apenas `order_preparation`.
- Como os itens do carrinho serao limpos apos sucesso, o historico da compra precisa migrar integralmente para `Order` e `OrderItem`.
- Conclusao: `OrderItem` deve persistir snapshot completo de produto/seller/quantidade/preco unitario/subtotal no momento da compra.

### 2. Split por seller e melhor feito dentro da transacao de checkout

- O carrinho atual ja suporta itens de sellers diferentes e o usuario decidiu nao dividir o carrinho fisicamente.
- O agrupamento por `seller_id` no checkout permite gerar um `Order` por seller sem alterar o modelo de carrinho.
- Conclusao: a orquestracao do checkout deve agrupar `cart_items` por seller e criar multiplos pedidos dentro do mesmo fluxo atomico.

### 3. Um unico debito do comprador continua compativel com multiplos pedidos

- O ledger atual ja suporta operacoes idempotentes e nao-negativas.
- A decisao de produto e manter um unico debito na wallet do comprador, mesmo que o checkout gere varios pedidos.
- Conclusao: a fase 19 deve manter o debito agregado e usar os totais individuais de cada pedido como base para refunds futuros, sem ainda migrar a referencia principal do ledger para `order_id` nesta fase de schema/checkout.

### 4. Estoque precisa ser validado e decrementado sob lock antes do commit final

- `products.stock_quantity` ja possui constraint de nao-negatividade, mas isso sozinho nao protege contra oversell sob concorrencia.
- O checkout precisa lockar produtos participantes, validar disponibilidade integral e falhar fechado se qualquer item nao puder ser atendido.
- Conclusao: lock por produto + validacao integral do carrinho + decremento server-side sao obrigatorios para `INV-01`.

### 5. Contrato HTTP deve mudar de "preparation" para "orders created"

- O endpoint atual retorna `cart` + `order_preparation`.
- O usuario definiu que a resposta futura deve ser enxuta: IDs dos pedidos e um resumo da operacao.
- Conclusao: `CartCheckoutController` precisa manter o boundary wallet-only e trocar o shape de sucesso para algo como `order_ids`, `orders_count`, `subtotal/total`, preservando respostas negativas existentes.

## Recommended Implementation Direction

1. Criar tabelas `orders` e `order_items` com UUID, ownership do comprador em `orders.user_id`, ownership operacional do seller em cada item e status inicial `paid`.
2. Persistir no `Order` apenas cabecalho e agregados por seller; persistir em `OrderItem` o snapshot necessario para historico e futuras fases.
3. Extrair a criacao do pedido para um service transacional novo, reaproveitando `Carts::Finalize` como orquestrador ou substituindo-o por um fluxo mais explicito.
4. Lockar carrinho, itens e produtos envolvidos; se qualquer item falhar em estoque/disponibilidade, dar rollback total no checkout.
5. Manter um unico debito wallet-only no comprador nesta fase e adiar a migracao definitiva do ledger para `order_id` para a fase 20.
6. Ajustar testes de integracao e service para provar split automatico por seller, limpeza do carrinho apos sucesso e ausencia de duplicidade sob retry.

## Validation Architecture

A fase deve ser validada com testes de migration/model/service/integration:

- models `Order` e `OrderItem` validam ownership, snapshot e agregados obrigatorios;
- checkout cria multiplos pedidos por seller com um unico fluxo de sucesso;
- qualquer falta de estoque falha o checkout inteiro sem debito parcial, sem pedido parcial e sem decremento parcial;
- carrinho fica `finished` e com itens limpos apos sucesso;
- retries/concorrencia nao duplicam pedido logico nem decrementam estoque duas vezes.

## Risks and Mitigations

- **Risco:** pedido parcial criado antes da falha de estoque ou debito.
  - **Mitigacao:** transacao unica envolvendo validacao de estoque, persistencia dos pedidos e side effects locais da fase.

- **Risco:** oversell sob duas finalizacoes concorrentes.
  - **Mitigacao:** lock de produtos envolvidos e validacao de disponibilidade depois do lock.

- **Risco:** source of truth historica continuar acoplada ao carrinho.
  - **Mitigacao:** snapshot completo em `OrderItem` e limpeza dos itens do carrinho apos sucesso.

- **Risco:** contrato de resposta do checkout quebrar consumidores de forma ambigua.
  - **Mitigacao:** trocar explicitamente para payload com `order_ids` e resumo, mantendo erros existentes.

---

*Phase: 19-order-persistence-and-stock-integrity*
*Research date: 2026-03-09*
