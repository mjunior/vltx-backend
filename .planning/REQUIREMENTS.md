# Requirements: Marketplace Backend (v1.3)

**Defined:** 2026-03-07
**Milestone:** v1.3 Wallet Ledger Hardening
**Core Value:** Isolamento multi-tenant estrito com contratos de autenticação e catálogo previsíveis.

## v1.3 Requirements

### Wallet Ledger Core

- [x] **WAL-01**: Sistema mantém histórico financeiro da carteira em ledger append-only, com criação apenas por INSERT de transações.
- [x] **WAL-02**: Cada transação de carteira registra tipo `credit`, `debit` ou `refund` e `amount_cents` inteiro positivo.
- [x] **WAL-03**: Cada transação persiste `balance_after_cents` calculado no backend no mesmo fluxo atômico da movimentação.
- [x] **WAL-04**: Todos os valores monetários de carteira são armazenados e processados em centavos (inteiro), sem float.

### Wallet Operations Safety

- [ ] **WAL-05**: Sistema impede reembolso duplicado para a mesma referência de negócio/idempotency key.
- [ ] **WAL-06**: Operações de crédito, débito e reembolso adquirem lock da carteira antes de movimentar saldo.
- [ ] **WAL-07**: Nenhuma operação pode resultar em saldo negativo; débito/reembolso inválido falha sem inserir transação.
- [ ] **WAL-08**: Backend nunca confia em valores críticos enviados pelo frontend e sempre recalcula/valida no servidor e banco.

### Authorization and Tenant Isolation

- [ ] **AUTHZ-08**: Usuário autenticado só pode consultar saldo/extrato da própria carteira.
- [ ] **AUTHZ-09**: Usuário autenticado não pode acessar nem movimentar carteira de outro usuário, mesmo com IDs forjados.

### Idempotency and Race Safety

- [ ] **IDEMP-01**: Requisições repetidas de débito/crédito com a mesma chave idempotente produzem no máximo uma transação efetiva.
- [ ] **IDEMP-02**: Operações concorrentes sobre a mesma carteira permanecem consistentes e sem dupla movimentação indevida.

## Future Requirements

### Orders and Checkout Completion

- **ORD-01**: Finalização do carrinho cria pedido persistido com snapshot de itens e valores.
- **ORD-02**: Débito de pedido integra carteira ledger com rastreabilidade fim a fim.
- **ORD-03**: Pedido suporta estados `processing`, `failed` e `canceled` com idempotência de criação.

## Out of Scope (v1.3)

| Feature | Reason |
|---------|--------|
| Multi-moeda na carteira | Complexidade de conversão e reconciliação fora do objetivo atual |
| Saque/transferência para conta bancária | Exige trilhas regulatórias e antifraude não previstas neste milestone |
| Reversão manual por UPDATE/DELETE em transações | Fere requisito de imutabilidade do ledger |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| WAL-01 | Phase 15 | Complete |
| WAL-02 | Phase 15 | Complete |
| WAL-03 | Phase 15 | Complete |
| WAL-04 | Phase 15 | Complete |
| WAL-06 | Phase 16 | Pending |
| WAL-07 | Phase 16 | Pending |
| WAL-08 | Phase 16 | Pending |
| WAL-05 | Phase 17 | Pending |
| IDEMP-01 | Phase 17 | Pending |
| IDEMP-02 | Phase 17 | Pending |
| AUTHZ-08 | Phase 18 | Pending |
| AUTHZ-09 | Phase 18 | Pending |

**Coverage:**
- v1.3 requirements: 12 total
- Mapped to phases: 12
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-07 for milestone v1.3*
*Last updated: 2026-03-08 after phase 15 execution*
