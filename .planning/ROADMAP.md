# Roadmap: Marketplace Backend

## Milestones

- ✅ **v1.0 Milestone** — shipped 2026-03-06 (Phases 1-5). Archive: [.planning/milestones/v1.0-ROADMAP.md](./milestones/v1.0-ROADMAP.md)
- ✅ **v1.1 Profile and Catalog** — shipped 2026-03-06 (Phases 6-10). Archive: [.planning/milestones/v1.1-ROADMAP.md](./milestones/v1.1-ROADMAP.md)
- 🚧 **v1.2 Cart and Checkout Foundation** — in progress (Phases 11-14)

## Phases (v1.2)

- [x] **Phase 11: Cart Foundation and Active-Cart Invariant** (completed 2026-03-07)
  - Goal: criar base de carrinho autenticado com regra de um carrinho `active` por usuário e isolamento tenant.
  - Requirements: `CART-01`, `CART-02`, `AUTHZ-05`, `AUTHZ-06`
  - Success criteria:
    1. Apenas usuário autenticado pode criar/obter carrinho.
    2. Sistema garante somente um carrinho `active` por usuário.
    3. Usuário nunca acessa carrinho de outro usuário.

- [ ] **Phase 12: Cart Item Operations with Server-Side Validation**
  - Goal: implementar adicionar/remover/atualizar item sem confiar em payload crítico do frontend.
  - Requirements: `CART-03`, `CART-04`, `CART-05`, `CART-06`, `CART-07`, `CART-08`, `CART-09`
  - Success criteria:
    1. Adição de item aceita apenas `product_id` e `quantity`, com validação server-side.
    2. Atualização de quantidade valida limites e consistência antes de persistir.
    3. Preço é derivado do produto no banco e operações ocorrem em transação.
    4. Produto próprio do usuário autenticado é bloqueado no carrinho.

- [ ] **Phase 13: Cart State Guards and Abuse Prevention**
  - Goal: reforçar travas de estado do carrinho para impedir operações indevidas e abuso.
  - Requirements: `AUTHZ-07`
  - Success criteria:
    1. Carrinhos `finished` ou `abandoned` não aceitam mutações de item.
    2. Endpoints não expõem carrinhos de outros usuários nem em cenários negativos.
    3. Fluxo de erro mantém contrato consistente sem vazar informação sensível.

- [ ] **Phase 14: Cart Finalization and Order Service Preparation**
  - Goal: finalizar carrinho com pagamento por carteira e preparar service para criação futura de pedido.
  - Requirements: `CHK-01`, `CHK-02`, `CHK-03`
  - Success criteria:
    1. Finalização altera carrinho ativo para `finished` com validações de domínio.
    2. Regra de pagamento suportado (carteira no site) fica registrada no fluxo de finalização.
    3. Service de preparação para criação de pedido existe e é consumido pela finalização, sem persistir pedido ainda.

## Phase Details

### Phase 11: Cart Foundation and Active-Cart Invariant
**Goal**: Criar domínio inicial de carrinho com ownership derivado do token e unicidade de carrinho ativo por usuário.
**Depends on**: Phase 10
**Requirements**: CART-01, CART-02, AUTHZ-05, AUTHZ-06
**Success Criteria** (what must be TRUE):
  1. Usuário autenticado cria/obtém carrinho ativo sem enviar `user_id`.
  2. Sistema impede segundo carrinho ativo para o mesmo usuário.
  3. Consultas e mutações de carrinho respeitam isolamento tenant.
**Plans**: 2 plans

Plans:
- [x] 11-01: Implementar modelagem de carrinho/status e criação idempotente do carrinho ativo por usuário
- [x] 11-02: Implementar autorização/escopo para acesso apenas ao carrinho do usuário autenticado

### Phase 12: Cart Item Operations with Server-Side Validation
**Goal**: Entregar operações de item com validações de quantidade/preço no backend e transação atômica.
**Depends on**: Phase 11
**Requirements**: CART-03, CART-04, CART-05, CART-06, CART-07, CART-08, CART-09
**Success Criteria** (what must be TRUE):
  1. Adição e update de item validam `product_id` e `quantity` no backend antes de persistir.
  2. Preço de item é obtido do produto persistido; preço do frontend é ignorado/rejeitado.
  3. Operações críticas rodam em transação e bloqueiam compra de produto próprio.
**Plans**: 3 plans

Plans:
- [ ] 12-01: Implementar service transacional para adicionar item no carrinho com validações de domínio
- [ ] 12-02: Implementar update de quantidade e remoção de item com validações server-side
- [ ] 12-03: Cobrir cenários negativos de fraude/abuso e consistência transacional em testes

### Phase 13: Cart State Guards and Abuse Prevention
**Goal**: Impedir mutações indevidas em carrinhos não ativos e reforçar proteção cross-cutting.
**Depends on**: Phase 12
**Requirements**: AUTHZ-07
**Success Criteria** (what must be TRUE):
  1. Carrinho `finished`/`abandoned` não permite adicionar/remover/atualizar item.
  2. Usuário recebe resposta de erro consistente para operações fora de estado permitido.
  3. Controles evitam abuso de endpoints por tentativa de acesso a carrinhos inativos.
**Plans**: 2 plans

Plans:
- [ ] 13-01: Aplicar guardas de estado ativo em todos os fluxos de mutação de carrinho
- [ ] 13-02: Adicionar testes de autorização/estado para carrinhos `finished` e `abandoned`

### Phase 14: Cart Finalization and Order Service Preparation
**Goal**: Finalizar carrinho ativo e deixar pronto o service que iniciará criação de pedido no próximo milestone.
**Depends on**: Phase 13
**Requirements**: CHK-01, CHK-02, CHK-03
**Success Criteria** (what must be TRUE):
  1. Endpoint/service de finalização marca carrinho ativo como `finished` de forma segura.
  2. Fluxo valida regra de pagamento exclusiva por carteira no site nesta etapa.
  3. Service de preparação para criação de pedido é chamado, mas não cria pedido ainda.
**Plans**: 2 plans

Plans:
- [ ] 14-01: Implementar finalização de carrinho ativo com transição de status e validações
- [ ] 14-02: Implementar service de preparação para criação de pedido e integração no fluxo de checkout

## Progress

| Phase | Milestone | Requirements | Status | Completed |
|-------|-----------|--------------|--------|-----------|
| 11. Cart Foundation and Active-Cart Invariant | v1.2 | 4 | Complete | 2026-03-07 |
| 12. Cart Item Operations with Server-Side Validation | v1.2 | 7 | Planned | — |
| 13. Cart State Guards and Abuse Prevention | v1.2 | 1 | Planned | — |
| 14. Cart Finalization and Order Service Preparation | v1.2 | 3 | Planned | — |
