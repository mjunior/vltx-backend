# Requirements: Marketplace Backend

**Defined:** 2026-03-09
**Milestone:** v1.4 Orders, Status Flow, and Ratings
**Core Value:** Isolamento multi-tenant estrito com contratos de autenticação e catálogo previsíveis.

## v1.4 Requirements

### Inventory and Checkout

- [ ] **INV-01**: Comprador pode finalizar o carrinho gerando pedido persistido, e o sistema reduz o estoque dos produtos no mesmo fluxo de confirmação.
- [ ] **INV-02**: Quando um pedido pago é cancelado, o sistema restaura o estoque correspondente sem depender de input do cliente.

### Orders

- [ ] **ORD-01**: Comprador pode finalizar o carrinho e gerar um `Order` com snapshot de itens, preços, seller e totais no momento da compra.
- [ ] **ORD-02**: Sistema registra pedido em estado inicial `paid` após checkout aprovado e impede criação parcial ou duplicada para o mesmo checkout lógico.
- [ ] **ORD-03**: Seller pode avançar o pedido apenas pelas etapas permitidas do fluxo (`paid -> in_separation -> confirmed`) sem pular estados.
- [ ] **ORD-04**: Comprador pode cancelar o pedido somente enquanto o estado atual for `paid`.
- [ ] **ORD-05**: Comprador pode marcar um pedido comprado como `delivered` somente após o fluxo ter alcançado o estado elegível de confirmação.
- [x] **ORD-06**: Comprador pode contestar uma compra somente depois que ela tiver sido marcada como `delivered`.
- [ ] **ORD-07**: Sistema mantém trilha auditável de transições de pedido e rejeita mudanças de status fora das ações autorizadas para buyer ou seller.

### Payments and Settlement

- [ ] **PAY-01**: Checkout do pedido aceita apenas pagamento pela carteira interna do sistema.
- [ ] **PAY-03**: Débito do comprador usa uma referência agregada persistida do checkout e mantém vínculo rastreável com os `order_ids`; refunds e liquidação seller continuam ligados ao pedido.
- [ ] **PAY-04**: Sistema processa reembolso automático e idempotente ao cancelar um pedido já pago.
- [x] **PAY-05**: Seller pode consultar painel com saldo a receber e histórico financeiro dos próprios pedidos sem acessar dados de outros sellers.

### Ratings

- [x] **RATE-01**: Comprador pode avaliar um produto comprado com nota de 1 a 5 e comentário somente após o pedido ter sido marcado como `delivered`.
- [x] **RATE-02**: Sistema registra avaliações em estruturas separadas por produto e por vendedor, vinculadas ao item comprado, para permitir cálculo futuro de média.

## v2 Requirements

### Payments

- **PAY-02**: Usuário ganha crédito promocional de R$ 10,00 somente após confirmação de e-mail.
- **PAY-06**: Seller pode solicitar saque ou liquidação externa do saldo a receber.
- **PAY-07**: Sistema suporta meios de pagamento externos como cartão e Pix.

### Orders

- **ORD-08**: Workflow suporta mediação operacional completa da contestação com novos estados internos.

### Ratings

- **RATE-03**: Seller pode responder publicamente a avaliações recebidas.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Cartão de crédito e Pix | Usuário definiu carteira interna como único meio de pagamento neste milestone |
| Payout bancário real para seller | Requer fluxo financeiro externo e compliance ainda não modelados |
| Edição livre de status por payload | Contraria requisito de workflow seguro com transições autorizadas |
| Avaliação antes de entrega | Contraria regra de elegibilidade pós-entrega |
| Crédito promocional no signup sem confirmação de e-mail | Usuário moveu o bônus para um futuro fluxo de confirmação de e-mail |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| INV-01 | Phase 19 | Completed |
| INV-02 | Phase 21 | Completed |
| ORD-01 | Phase 19 | Completed |
| ORD-02 | Phase 19 | Completed |
| ORD-03 | Phase 21 | Completed |
| ORD-04 | Phase 21 | Completed |
| ORD-05 | Phase 21 | Completed |
| ORD-06 | Phase 22 | Completed |
| ORD-07 | Phase 21 | Completed |
| PAY-01 | Phase 19 | Completed |
| PAY-02 | Future email confirmation milestone | Deferred |
| PAY-03 | Phase 20 | Completed |
| PAY-04 | Phase 21 | Completed |
| PAY-05 | Phase 22 | Completed |
| RATE-01 | Phase 22 | Completed |
| RATE-02 | Phase 22 | Completed |

**Coverage:**
- v1.4 requirements: 15 total
- Mapped to phases: 15
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-09*
*Last updated: 2026-03-10 after phase 22 execution*
