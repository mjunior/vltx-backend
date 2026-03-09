# Roadmap: Marketplace Backend

## Milestones

- ✅ **v1.0 Milestone** — shipped 2026-03-06 (Phases 1-5). Archive: [.planning/milestones/v1.0-ROADMAP.md](./milestones/v1.0-ROADMAP.md)
- ✅ **v1.1 Profile and Catalog** — shipped 2026-03-06 (Phases 6-10). Archive: [.planning/milestones/v1.1-ROADMAP.md](./milestones/v1.1-ROADMAP.md)
- ✅ **v1.2 Cart and Checkout Foundation** — shipped 2026-03-07 (Phases 11-14). Archive: [.planning/milestones/v1.2-ROADMAP.md](./milestones/v1.2-ROADMAP.md)
- ✅ **v1.3 Wallet Ledger Hardening** — shipped 2026-03-08 (Phases 15-18). Archive: [.planning/milestones/v1.3-ROADMAP.md](./milestones/v1.3-ROADMAP.md)

## Current Milestone

**v1.4 Orders, Status Flow, and Ratings**

- **Status:** Planned
- **Phases:** 19-22
- **Requirements:** 16 mapped / 16 total

## Phases (v1.4)

- [ ] **Phase 19: Order Persistence and Stock Integrity**
  - Goal: persistir `Order`/`OrderItem` no checkout com snapshot imutável, pagamento wallet-only e baixa atômica de estoque.
  - Requirements: `INV-01`, `ORD-01`, `ORD-02`, `PAY-01`
  - Success criteria:
    1. Checkout cria pedido persistido com snapshot de itens, seller e totais.
    2. Estoque é reduzido somente no fluxo confirmado de criação do pedido.
    3. Repetição/retry não duplica pedido lógico nem deixa estoque inconsistente.

- [ ] **Phase 20: Order-Linked Ledger and Wallet Provisioning**
  - Goal: migrar a trilha financeira para `order_id`, provisionar crédito inicial de signup e estruturar recebíveis do seller.
  - Requirements: `PAY-02`, `PAY-03`
  - Success criteria:
    1. Novos usuários passam a ter R$ 10,00 de crédito inicial de forma idempotente.
    2. Débito do comprador no checkout passa a referenciar `order_id` como chave principal do ledger.
    3. Lançamentos financeiros necessários para recebíveis seller podem ser consultados sem quebrar invariantes append-only.

- [ ] **Phase 21: Secure Order Workflow and Cancellation Refunds**
  - Goal: implementar fluxo seguro de status com ações por ator, cancelamento comprador e refund automático com restauração de estoque.
  - Requirements: `INV-02`, `ORD-03`, `ORD-04`, `ORD-05`, `ORD-07`, `PAY-04`
  - Success criteria:
    1. Seller só consegue avançar `paid -> in_separation -> confirmed` sem pulo de estado.
    2. Buyer só cancela enquanto `paid`, com refund idempotente e estoque restaurado.
    3. Buyer só marca `delivered` quando o pedido já estiver em estado elegível.
    4. Toda transição inválida por ator ou sequência é rejeitada e auditada.

- [ ] **Phase 22: Seller Finance Surface, Contestation, and Ratings**
  - Goal: expor painel financeiro seller e fechar o pós-entrega com contestação e avaliações por produto/vendedor.
  - Requirements: `ORD-06`, `PAY-05`, `RATE-01`, `RATE-02`
  - Success criteria:
    1. Seller enxerga saldo a receber e histórico financeiro apenas dos próprios pedidos.
    2. Buyer pode contestar somente após `delivered`.
    3. Buyer pode avaliar item entregue com nota 1-5 e comentário uma única vez por elegibilidade definida.
    4. Avaliações ficam registradas separadamente por produto e por vendedor para cálculo posterior de médias.

## Phase Details

### Phase 19: Order Persistence and Stock Integrity
**Goal**: Transformar o checkout atual em criação real de pedido com snapshot imutável e consistência de estoque.
**Depends on**: Phase 18
**Requirements**: INV-01, ORD-01, ORD-02, PAY-01
**Success Criteria** (what must be TRUE):
  1. `POST /cart/checkout` cria `Order` e `OrderItem` persistidos sem aceitar status ou valores críticos do frontend.
  2. O débito buyer continua wallet-only e a transação falha fechada se estoque ou snapshot não puderem ser garantidos.
  3. Produtos do pedido têm estoque decrementado exatamente uma vez por checkout lógico.
**Plans**: 3 plans

Plans:
- [x] 19-01: Implementar schema/models de `Order` e `OrderItem` com snapshot e constraints de domínio
- [x] 19-02: Integrar checkout transacional para criar pedido persistido e reduzir estoque
- [x] 19-03: Cobrir retries/concorrência para evitar duplicidade de pedido e inconsistência de estoque

### Phase 20: Order-Linked Ledger and Wallet Provisioning
**Goal**: Fechar a rastreabilidade financeira ponta a ponta por `order_id` e provisionar crédito inicial da carteira.
**Depends on**: Phase 19
**Requirements**: PAY-02, PAY-03
**Success Criteria** (what must be TRUE):
  1. Usuário recém-criado recebe crédito inicial exatamente uma vez.
  2. Ledger buyer/seller usa `order_id` como referência primária em vez de `cart_id`.
  3. Recebíveis seller ficam deriváveis do ledger sem expor dados cross-tenant.
**Plans**: 2 plans

Plans:
- [ ] 20-01: Implementar provisionamento idempotente de crédito inicial na criação do usuário
- [ ] 20-02: Refatorar lançamentos do checkout/refund para `order_id` e registrar recebíveis seller

### Phase 21: Secure Order Workflow and Cancellation Refunds
**Goal**: Garantir workflow seguro de pedido com transições autorizadas, cancelamento buyer e refund automático.
**Depends on**: Phase 20
**Requirements**: INV-02, ORD-03, ORD-04, ORD-05, ORD-07, PAY-04
**Success Criteria** (what must be TRUE):
  1. Workflow impede mudança arbitrária de `status` e aceita apenas ações permitidas para buyer/seller.
  2. Cancelamento em `paid` dispara refund idempotente e restauração do estoque.
  3. Marcação de entrega pelo buyer respeita a sequência do workflow.
**Plans**: 3 plans

Plans:
- [ ] 21-01: Implementar camada de workflow/transições auditáveis para pedidos
- [ ] 21-02: Expor ações seguras de seller e buyer para avanço, cancelamento e entrega
- [ ] 21-03: Cobrir cenários negativos de transição forjada, refund duplicado e restauração de estoque

### Phase 22: Seller Finance Surface, Contestation, and Ratings
**Goal**: Entregar visibilidade financeira seller e o ciclo pós-entrega de contestação/avaliação.
**Depends on**: Phase 21
**Requirements**: ORD-06, PAY-05, RATE-01, RATE-02
**Success Criteria** (what must be TRUE):
  1. Seller possui painel com saldo a receber e histórico dos próprios pedidos.
  2. Buyer consegue contestar somente após `delivered`.
  3. Sistema persiste avaliações separadas por produto e vendedor com elegibilidade derivada do pedido entregue.
**Plans**: 3 plans

Plans:
- [ ] 22-01: Implementar surface de consulta financeira do seller com authz estrita
- [ ] 22-02: Implementar contestação pós-entrega com guardas de elegibilidade
- [ ] 22-03: Implementar avaliações por produto e por vendedor com testes de unicidade/elegibilidade

## Progress

| Phase | Milestone | Requirements | Status | Completed |
|-------|-----------|--------------|--------|-----------|
| 19. Order Persistence and Stock Integrity | v1.4 | 4 | In Progress | 2026-03-09 |
| 20. Order-Linked Ledger and Wallet Provisioning | v1.4 | 2 | Pending | — |
| 21. Secure Order Workflow and Cancellation Refunds | v1.4 | 6 | Pending | — |
| 22. Seller Finance Surface, Contestation, and Ratings | v1.4 | 4 | Pending | — |
