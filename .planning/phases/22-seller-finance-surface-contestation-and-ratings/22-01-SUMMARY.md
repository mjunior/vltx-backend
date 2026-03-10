---
phase: 22-seller-finance-surface-contestation-and-ratings
plan: 01
subsystem: seller-finance
tags: [rails, seller-finance, receivables, wallet, authz]
requires:
  - phase: 20-order-linked-ledger-and-wallet-provisioning
    provides: `seller_receivables` pendentes e debito buyer agregado por `checkout_group`
  - phase: 21-secure-order-workflow-and-cancellation-refunds
    provides: credito seller em `delivered`
provides:
  - endpoint `GET /seller/finance`
  - resumo de pendencias seller
  - historico de creditos order-linked do seller
affects: [seller-finance, wallet, api]
tech-stack:
  added: []
  patterns: [read-only seller surface, authz fail-closed, per-order seller summary]
key-files:
  created:
    - marketplace_backend/app/controllers/seller_finance_controller.rb
    - marketplace_backend/app/services/seller_finance/read_summary.rb
    - marketplace_backend/test/services/seller_finance/read_summary_test.rb
    - marketplace_backend/test/integration/seller_finance_test.rb
  modified:
    - marketplace_backend/config/routes.rb
    - marketplace_backend/test/integration/healthcheck_test.rb
key-decisions:
  - "A leitura do painel seller nao cria wallet nova; ausencia de wallet retorna historico vazio."
  - "O resumo mostra pendencias por pedido e historico de creditos reais da wallet seller."
  - "Qualquer tentativa de informar `seller_id` forjado na query retorna `not_found`."
patterns-established:
  - "Surface financeira seller separa recebivel pendente de saldo ja creditado."
requirements-completed:
  - PAY-05
duration: 31 min
completed: 2026-03-10
---

# Phase 22 Plan 01: Seller Finance Summary

**O seller ganhou um painel financeiro enxuto e seguro, com total pendente por pedido e historico dos creditos ja liberados.**

## Performance

- **Duration:** 31 min
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments
- Criado `GET /seller/finance` com authz estrita baseada no `current_user`.
- O resumo passou a combinar `seller_receivables` pendentes com creditos reais da wallet do seller ligados a `order`.
- A leitura nao gera side effects de persistencia quando o seller ainda nao possui wallet.

## Task Commits

1. **Task 1-3: seller finance surface + pending summary + credited history** - pending commit

## Verification

- `RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test test/services/seller_finance/read_summary_test.rb test/integration/seller_finance_test.rb`

## Next Phase Readiness

- Base pronta para expor contestacao e ratings sem misturar leitura financeira com efeitos operacionais.

---
*Phase: 22-seller-finance-surface-contestation-and-ratings*
*Completed: 2026-03-10*
