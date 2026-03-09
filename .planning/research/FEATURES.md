# Feature Research

**Domain:** Orders, status workflow, wallet settlement, and ratings
**Researched:** 2026-03-09
**Confidence:** HIGH

## Feature Landscape

### Table Stakes (Users Expect These)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Pedido persistido a partir do carrinho | Sem isso checkout fica incompleto | MEDIUM | Precisa snapshot e idempotência |
| Pagamento só com carteira interna | Regra explícita do milestone | LOW | Já existe base parcial |
| Cancelamento do pedido pago com refund | Essencial para confiança do comprador | MEDIUM | Deve ser idempotente |
| Seller avança pedido por etapas | Fluxo básico de fulfillment | MEDIUM | Não pode pular estado |
| Buyer marca entregue e pode contestar | Fecha o pós-compra | MEDIUM | Regras dependem do workflow |
| Avaliação 1-5 com comentário | Sinal de qualidade pós-entrega | LOW-MEDIUM | Elegibilidade é a parte crítica |

### Differentiators (Competitive Advantage)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Ledger inteiro por `order_id` | Rastreabilidade ponta a ponta | MEDIUM | Facilita reconciliação e auditoria |
| Recebível seller separado do saldo buyer | Clareza financeira | MEDIUM | Evita semântica errada de payout |
| Avaliação separada por produto e vendedor | Métricas futuras simples | LOW | Bom desenho de dados desde o começo |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| PATCH livre de status | “Mais simples” | Abre brecha de fraude e inconsistência | Ações de transição explícitas |
| Reembolso manual fora do fluxo do pedido | “Flexível” | Quebra rastreabilidade | Refund vinculado a `order_id` |
| Avaliação sem vínculo com item entregue | “Menos modelagem” | Gera fraude e duplicidade | Rating ligado a item/pedido elegível |

## MVP Definition

### Launch With (v1.4)

- [ ] `Order` e `OrderItem` persistidos com snapshot
- [ ] Baixa e restauração de estoque no fluxo correto
- [ ] Workflow seguro de status por ator
- [ ] Crédito inicial de R$ 10,00 na criação de conta
- [ ] Refund automático ao cancelar pedido pago
- [ ] Painel financeiro do seller
- [ ] Avaliações por produto e por vendedor após entrega

### Future Consideration (v2+)

- [ ] Saque/payout externo do seller
- [ ] Card/Pix
- [ ] Resposta pública do seller à avaliação

## Sources

- Padrões de marketplace fulfillment e fluxo financeiro
- Documentação das gems de workflow pesquisadas

---
*Feature research for: marketplace orders milestone*
*Researched: 2026-03-09*
