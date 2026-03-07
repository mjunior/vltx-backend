# Requirements: Marketplace Backend (v1.2)

**Defined:** 2026-03-07
**Milestone:** v1.2 Cart and Checkout Foundation
**Core Value:** Isolamento multi-tenant estrito com contratos de autenticação e catálogo previsíveis.

## v1.2 Requirements

### Cart Management

- [x] **CART-01**: Usuário autenticado pode criar/obter seu carrinho ativo sem informar `user_id` no payload.
- [x] **CART-02**: Sistema garante no máximo um carrinho com status `active` por usuário.
- [x] **CART-03**: Usuário autenticado pode adicionar item no carrinho enviando apenas `product_id` e `quantity`.
- [x] **CART-04**: Usuário autenticado pode remover item existente do próprio carrinho ativo.
- [x] **CART-05**: Usuário autenticado pode atualizar quantidade de item do próprio carrinho ativo.
- [x] **CART-06**: Backend valida quantidade no servidor antes de adicionar/atualizar item (sem confiar no frontend).

### Pricing and Integrity

- [x] **CART-07**: Backend calcula/valida preço do item a partir do produto no banco e nunca aceita preço enviado pelo frontend.
- [x] **CART-08**: Operações de adicionar/atualizar item no carrinho ocorrem em transação atômica com validações de integridade.
- [x] **CART-09**: Usuário não pode adicionar ao carrinho produtos do próprio usuário vendedor.

### Authorization and Tenant Safety

- [x] **AUTHZ-05**: Apenas usuários autenticados podem criar, visualizar e alterar carrinho.
- [x] **AUTHZ-06**: Usuário não pode acessar carrinho de outro usuário (isolamento tenant estrito).
- [ ] **AUTHZ-07**: Usuário não pode operar em carrinhos `finished` ou `abandoned`.

### Checkout Preparation

- [ ] **CHK-01**: Usuário autenticado pode finalizar carrinho ativo alterando status para `finished`.
- [ ] **CHK-02**: Finalização registra que o método de pagamento suportado neste milestone é somente carteira no site.
- [ ] **CHK-03**: Sistema disponibiliza service preparado para futura criação de pedido a partir do carrinho finalizado (sem criar pedido neste milestone).

## Future Requirements

### Orders and Payments

- **ORD-01**: Finalização do carrinho cria pedido persistido com itens congelados.
- **ORD-02**: Pedido executa débito real na carteira e trilha de saldo/ledger.
- **ORD-03**: Pedido suporta estados de processamento, falha e cancelamento.

## Out of Scope (v1.2)

| Feature | Reason |
|---------|--------|
| Criação completa de pedido na finalização | Explicitamente fora do escopo desta etapa; apenas preparação de service |
| Métodos de pagamento além de carteira no site | Regra de negócio atual restringe pagamento à carteira |
| Checkout de múltiplos carrinhos ativos por usuário | Bloqueado por regra de um carrinho ativo por usuário |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| CART-01 | Phase 11 | Complete |
| CART-02 | Phase 11 | Complete |
| AUTHZ-05 | Phase 11 | Complete |
| AUTHZ-06 | Phase 11 | Complete |
| CART-03 | Phase 12 | Complete |
| CART-04 | Phase 12 | Complete |
| CART-05 | Phase 12 | Complete |
| CART-06 | Phase 12 | Complete |
| CART-07 | Phase 12 | Complete |
| CART-08 | Phase 12 | Complete |
| CART-09 | Phase 12 | Complete |
| AUTHZ-07 | Phase 13 | Pending |
| CHK-01 | Phase 14 | Pending |
| CHK-02 | Phase 14 | Pending |
| CHK-03 | Phase 14 | Pending |

**Coverage:**
- v1.2 requirements: 15 total
- Mapped to phases: 15
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-07 for milestone v1.2*
*Last updated: 2026-03-07 after initial milestone definition*
