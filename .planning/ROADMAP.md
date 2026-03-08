# Roadmap: Marketplace Backend

## Milestones

- ✅ **v1.0 Milestone** — shipped 2026-03-06 (Phases 1-5). Archive: [.planning/milestones/v1.0-ROADMAP.md](./milestones/v1.0-ROADMAP.md)
- ✅ **v1.1 Profile and Catalog** — shipped 2026-03-06 (Phases 6-10). Archive: [.planning/milestones/v1.1-ROADMAP.md](./milestones/v1.1-ROADMAP.md)
- ✅ **v1.2 Cart and Checkout Foundation** — shipped 2026-03-07 (Phases 11-14). Archive: [.planning/milestones/v1.2-ROADMAP.md](./milestones/v1.2-ROADMAP.md)
- ◆ **v1.3 Wallet Ledger Hardening** — active (Phases 15-18)

## Phases (v1.3)

- [x] **Phase 15: Wallet Ledger Data Model and Invariants** (completed 2026-03-08)
  - Goal: estabelecer base imutável de carteira com transações append-only e trilha de saldo em centavos.
  - Requirements: `WAL-01`, `WAL-02`, `WAL-03`, `WAL-04`
  - Success criteria:
    1. Tabela de transações aceita apenas tipo `credit`, `debit`, `refund` com `amount_cents > 0`.
    2. Cada transação persiste `balance_after_cents` calculado no backend.
    3. Fluxos de movimentação operam exclusivamente em centavos inteiros.

- [x] **Phase 16: Transaction Safety and Non-Negative Balance Enforcement** (completed 2026-03-08)
  - Goal: implementar engine de movimentação com lock e validações anti-fraude server-side.
  - Requirements: `WAL-06`, `WAL-07`, `WAL-08`
  - Success criteria:
    1. Crédito/débito/reembolso fazem lock da carteira antes de calcular novo saldo.
    2. Saldo nunca fica negativo; tentativa inválida retorna erro sem persistir transação.
    3. Valores críticos vindos do frontend são ignorados/recalculados a partir de dados confiáveis.

- [ ] **Phase 17: Idempotency and Refund Deduplication**
  - Goal: garantir idempotência forte em retries e concorrência, incluindo bloqueio de reembolso duplicado.
  - Requirements: `WAL-05`, `IDEMP-01`, `IDEMP-02`
  - Success criteria:
    1. Reembolso com mesma referência/idempotency key não gera segunda transação.
    2. Retry de mesma operação retorna resultado consistente sem duplicar débito/crédito.
    3. Corridas concorrentes na mesma carteira preservam consistência do ledger.

- [ ] **Phase 18: Wallet Authorization and Tenant Isolation Surface**
  - Goal: reforçar fronteira de autorização para consulta e operação apenas da carteira própria.
  - Requirements: `AUTHZ-08`, `AUTHZ-09`
  - Success criteria:
    1. Usuário autenticado consulta apenas saldo/extrato da própria carteira.
    2. Tentativas com IDs forjados para carteira de terceiros são negadas sem vazamento.
    3. Endpoints e services de carteira derivam identidade exclusivamente do token autenticado.

## Phase Details

### Phase 15: Wallet Ledger Data Model and Invariants
**Goal**: Criar domínio de carteira com ledger imutável e trilha de saldo pós-transação.
**Depends on**: Phase 14
**Requirements**: WAL-01, WAL-02, WAL-03, WAL-04
**Success Criteria** (what must be TRUE):
  1. Estrutura de dados suporta somente transações append-only.
  2. `amount_cents` e `balance_after_cents` são inteiros validados server-side.
  3. Tipos de transação permitidos ficam restritos a `credit`, `debit`, `refund`.
**Plans**: 2 plans

Plans:
- [ ] 15-01: Implementar schema/models de carteira e transações ledger com constraints de domínio
- [ ] 15-02: Implementar cálculo de `balance_after_cents` em fluxo atômico de insert

### Phase 16: Transaction Safety and Non-Negative Balance Enforcement
**Goal**: Garantir segurança financeira por lock, validação forte e proibição de saldo negativo.
**Depends on**: Phase 15
**Requirements**: WAL-06, WAL-07, WAL-08
**Success Criteria** (what must be TRUE):
  1. Toda movimentação crítica usa lock por carteira antes de alterar saldo.
  2. Tentativas que levariam saldo negativo falham sem side effect no ledger.
  3. Backend valida e recalcula dados críticos independentemente do payload do frontend.
**Plans**: 2 plans

Plans:
- [ ] 16-01: Implementar service transacional de movimentação com lock e checagem de saldo
- [ ] 16-02: Cobrir cenários de fraude, saldo insuficiente e inconsistência em testes

### Phase 17: Idempotency and Refund Deduplication
**Goal**: Evitar duplicidade financeira sob retry e concorrência.
**Depends on**: Phase 16
**Requirements**: WAL-05, IDEMP-01, IDEMP-02
**Success Criteria** (what must be TRUE):
  1. Chave idempotente garante no máximo uma transação efetiva por operação lógica.
  2. Reembolso duplicado para mesma referência é bloqueado deterministicamente.
  3. Corridas simultâneas não produzem movimentações duplicadas.
**Plans**: 2 plans

Plans:
- [ ] 17-01: Implementar persistência de chave idempotente e deduplicação de reembolso
- [ ] 17-02: Adicionar testes de concorrência/retry garantindo comportamento determinístico

### Phase 18: Wallet Authorization and Tenant Isolation Surface
**Goal**: Garantir que usuário só veja e opere a própria carteira.
**Depends on**: Phase 17
**Requirements**: AUTHZ-08, AUTHZ-09
**Success Criteria** (what must be TRUE):
  1. Endpoints de carteira operam com identidade derivada do token.
  2. Carteiras de terceiros permanecem inacessíveis em todos os fluxos.
  3. Cenários negativos retornam erros consistentes sem exposição de dados sensíveis.
**Plans**: 2 plans

Plans:
- [ ] 18-01: Implementar escopos/autorização de carteira para ownership estrito
- [ ] 18-02: Cobrir testes de acesso indevido e enumeração de recursos

## Progress

| Phase | Milestone | Requirements | Status | Completed |
|-------|-----------|--------------|--------|-----------|
| 11. Cart Foundation and Active-Cart Invariant | v1.2 | 4 | Complete | 2026-03-07 |
| 12. Cart Item Operations with Server-Side Validation | v1.2 | 7 | Complete | 2026-03-07 |
| 13. Cart State Guards and Abuse Prevention | v1.2 | 1 | Complete | 2026-03-07 |
| 14. Cart Finalization and Order Service Preparation | v1.2 | 3 | Complete | 2026-03-07 |
| 15. Wallet Ledger Data Model and Invariants | v1.3 | 4 | Complete | 2026-03-08 |
| 16. Transaction Safety and Non-Negative Balance Enforcement | v1.3 | 3 | Complete | 2026-03-08 |
| 17. Idempotency and Refund Deduplication | v1.3 | 3 | Pending | — |
| 18. Wallet Authorization and Tenant Isolation Surface | v1.3 | 2 | Pending | — |
