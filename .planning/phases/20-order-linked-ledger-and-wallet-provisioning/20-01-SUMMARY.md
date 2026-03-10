---
phase: 20-order-linked-ledger-and-wallet-provisioning
plan: 01
subsystem: finance
tags: [rails, checkout, wallet, ledger, traceability]
requires:
  - phase: 19-order-persistence-and-stock-integrity
    provides: orders persistidos por seller e checkout wallet-only
provides:
  - entidade `checkout_groups`
  - debito buyer referenciado por compra agregada persistida
  - drill-down seguro no extrato e no resumo do checkout
affects: [checkout, wallet-statement, ledger, seller-finance]
tech-stack:
  added: []
  patterns: [aggregated checkout reference, one debit per checkout with linked orders]
key-files:
  created:
    - marketplace_backend/db/migrate/20260309235000_create_checkout_groups.rb
    - marketplace_backend/app/models/checkout_group.rb
    - marketplace_backend/test/models/checkout_group_test.rb
  modified:
    - marketplace_backend/app/models/order.rb
    - marketplace_backend/app/models/user.rb
    - marketplace_backend/app/models/wallet_transaction.rb
    - marketplace_backend/app/services/carts/finalize.rb
    - marketplace_backend/app/serializers/wallets/statement_transaction_serializer.rb
    - marketplace_backend/test/services/carts/finalize_test.rb
    - marketplace_backend/test/integration/cart_checkout_orders_test.rb
    - marketplace_backend/test/integration/cart_checkout_test.rb
    - marketplace_backend/test/integration/wallet_authorization_test.rb
    - marketplace_backend/test/services/wallets/read/fetch_statement_test.rb
    - marketplace_backend/db/schema.rb
key-decisions:
  - "O debito buyer continua unico por checkout, mas passa a referenciar `checkout_group`."
  - "A UX recebe `checkout_group_id` tanto no resumo do checkout quanto no extrato serializado, sem expor metadata bruta."
  - "Orders ficam ligados ao agrupador para rastreabilidade ponta a ponta."
patterns-established:
  - "Compra agregada do buyer separada dos pedidos operacionais por seller."
requirements-completed:
  - PAY-03
duration: 44 min
completed: 2026-03-10
---

# Phase 20 Plan 01: Aggregated Checkout Ledger Summary

**A compra do buyer passou a ter referencia financeira persistida propria, desacoplada do `cart_id` e conectada aos pedidos gerados no split.**

## Performance

- **Duration:** 44 min
- **Tasks:** 3
- **Files modified:** 12

## Accomplishments
- Criado `checkout_group` como entidade agregadora do checkout, com buyer, cart de origem, total e moeda.
- `Finalize` agora cria o agrupador, gera os pedidos ligados a ele e registra o debito da wallet com `reference_type: checkout_group`.
- O extrato continua exibindo uma unica compra, mas com `checkout_group_id`, `order_ids` e `orders_count` serializados de forma segura para drill-down.

## Task Commits

1. **Task 1-3: checkout group + buyer debit migration + checkout contract** - pending commit

## Files Created/Modified
- `marketplace_backend/db/migrate/20260309235000_create_checkout_groups.rb` - cria o agrupador financeiro e backfill de orders preexistentes.
- `marketplace_backend/app/models/checkout_group.rb` - define invariantes da compra agregada.
- `marketplace_backend/app/services/carts/finalize.rb` - migra o debito buyer para `checkout_group`.
- `marketplace_backend/app/serializers/wallets/statement_transaction_serializer.rb` - expõe campos seguros para drill-down sem retornar metadata bruta.
- `marketplace_backend/db/schema.rb` - refletido junto com a nova relacao `orders.checkout_group_id`.

## Decisions Made
- Manter um unico debito no extrato do comprador e resolver rastreabilidade com entidade agregadora, nao com multiplo debito por order.
- Reordenar o checkout para criar orders antes do debit da wallet dentro da mesma transacao, permitindo anexar `order_ids` no ledger sem perder atomicidade.

## Deviations from Plan
None - plan executed with the intended model and contract changes.

## Issues Encountered
- Nenhum bloqueio de runtime nesta etapa; a checagem Rails voltou a funcionar durante a execucao.

## User Setup Required
None.

## Next Phase Readiness
- Base agregadora pronta para ligar recebiveis seller e refund parcial por `order_id`.

---
*Phase: 20-order-linked-ledger-and-wallet-provisioning*
*Completed: 2026-03-10*
