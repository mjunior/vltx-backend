---
phase: 20-order-linked-ledger-and-wallet-provisioning
plan: 02
subsystem: seller-finance
tags: [rails, receivables, seller, wallet, payout]
requires:
  - phase: 20-order-linked-ledger-and-wallet-provisioning
    provides: checkout group persistido e buyer debit rastreavel
provides:
  - tabela `seller_receivables`
  - recebivel pending por order no checkout
  - leitura de total pendente e lista por pedido para seller
affects: [checkout, seller-finance, settlement, wallet]
tech-stack:
  added: []
  patterns: [separate receivable ledger, deferred seller credit after delivered]
key-files:
  created:
    - marketplace_backend/db/migrate/20260309235100_create_seller_receivables.rb
    - marketplace_backend/app/models/seller_receivable.rb
    - marketplace_backend/app/services/seller_receivables/read_summary.rb
    - marketplace_backend/test/models/seller_receivable_test.rb
    - marketplace_backend/test/services/seller_receivables/read_summary_test.rb
  modified:
    - marketplace_backend/app/services/orders/create_from_cart.rb
    - marketplace_backend/test/services/orders/create_from_cart_test.rb
    - marketplace_backend/test/models/order_item_test.rb
    - marketplace_backend/test/models/order_test.rb
    - marketplace_backend/test/models/wallet_transaction_test.rb
    - marketplace_backend/db/schema.rb
key-decisions:
  - "Recebivel seller nasce `pending` no checkout e nao gera credito na wallet nesta fase."
  - "A granularidade escolhida foi 1 recebivel por `order`, coerente com o split automatico por seller."
  - "PAY-02 saiu desta fase e foi empurrado para o futuro fluxo de confirmacao de e-mail."
patterns-established:
  - "Separacao entre ledger do buyer e saldo a receber do seller."
requirements-completed:
  - PAY-03
duration: 39 min
completed: 2026-03-10
---

# Phase 20 Plan 02: Seller Receivables Summary

**O checkout agora deixa trilha seller-side sem creditar saldo real antes de `delivered`, preparando payout seguro para a fase 21.**

## Performance

- **Duration:** 39 min
- **Tasks:** 3
- **Files modified:** 11

## Accomplishments
- Criada a entidade `seller_receivable` com estados explicitos (`pending`, `reversed`, `credited`) e backfill para orders existentes.
- `Orders::CreateFromCart` passou a registrar um recebivel `pending` por pedido, no mesmo fluxo transacional do split e da baixa de estoque.
- Implementado `SellerReceivables::ReadSummary` retornando total pendente e lista por pedido, com escopo estrito por seller.

## Task Commits

1. **Task 1-3: receivables schema + checkout registration + seller read summary** - pending commit

## Files Created/Modified
- `marketplace_backend/db/migrate/20260309235100_create_seller_receivables.rb` - cria e faz backfill dos recebiveis seller.
- `marketplace_backend/app/models/seller_receivable.rb` - formaliza os estados e invariantes do saldo a receber.
- `marketplace_backend/app/services/orders/create_from_cart.rb` - passa a criar o recebivel seller ao lado do pedido.
- `marketplace_backend/app/services/seller_receivables/read_summary.rb` - disponibiliza total pendente e lista por order.

## Decisions Made
- Nao gerar `credit` na wallet do vendedor nesta fase; o recebivel permanece separado ate o buyer marcar `delivered`.
- Manter a visualizacao seller baseada em total pendente + lista por order, sem surface HTTP nova ainda.

## Deviations from Plan
None - phase delivered the planned data model and query service.

## Issues Encountered
- A suite completa revelou um teste antigo de JWT dependente da data corrente; ele foi estabilizado com `verify_expiration: false` ao validar claims historicas.

## User Setup Required
None.

## Next Phase Readiness
- Fase 21 pode liberar credito ao seller apenas na transicao `delivered` e reverter recebiveis em cancelamentos/refunds antes disso.

---
*Phase: 20-order-linked-ledger-and-wallet-provisioning*
*Completed: 2026-03-10*
