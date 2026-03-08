# Phase 15: Wallet Ledger Data Model and Invariants - Context

**Gathered:** 2026-03-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Esta fase entrega a base de dados e invariantes do domínio de carteira com ledger append-only.
Escopo: modelagem de `wallet` + `wallet_transactions` com tipos `credit/debit/refund`, armazenamento em centavos e cálculo de `balance_after_cents` consistente.
Fora do escopo da fase 15: surface API completa de leitura (saldo/extrato) e regras de lock/idempotência operacional detalhadas (fases 16-18).

</domain>

<decisions>
## Implementation Decisions

### Saldo da Wallet (Híbrido Seguro)
- Modelo híbrido: ledger append-only como trilha financeira + `wallet.current_balance_cents` materializado para leitura operacional.
- Não haverá job de reconciliação nesta fase inicial.
- Em divergência detectada em runtime entre estado materializado e ledger: recalcular via ledger, corrigir materializado e falhar a operação atual (fail-closed).
- Leitura operacional padrão usa saldo materializado; cálculo por `SUM` no ledger entra no fluxo de divergência.
- Fonte de verdade final em caso de conflito: ledger.

### Estrutura Mínima da Transaction Ledger
- Transaction terá referência de negócio com `reference_type`, `reference_id` e `operation_key`.
- `operation_key` com unicidade por `wallet_id` (não global do sistema).
- `metadata` em `jsonb` opcional, com validação por whitelist de chaves aceitas.
- Timestamp da transação usa apenas `created_at` nesta fase.

### Política de `balance_after_cents`
- Cálculo sempre server-side no backend: `previous_balance + signed_amount`, dentro da mesma transação.
- Encadeamento validado contra estado atual da wallet lockada antes de inserir a transação.
- `amount_cents` sempre positivo; sinal é derivado do tipo (`credit` soma, `debit/refund` subtrai).
- Operação que resultaria saldo negativo é bloqueada antes do insert.

### Claude's Discretion
- Nomenclatura final de models/migrations (`Wallet`, `WalletTransaction`) e nomes de constraints/indexes.
- Estratégia exata de validação de whitelist de `metadata` (camada model vs service), mantendo contrato estrito.
- Granularidade dos códigos internos de erro de domínio, preservando contrato HTTP já estabilizado.

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ApplicationController#authenticate_user!` e `current_user`: base para ownership derivado do token.
- Padrão de controllers finos + service objects (`Carts::*`, `Products::*`) já consolidado.
- `Carts::Finalize` já usa transação + lock (`Cart.lock`) em fluxo crítico, padrão reaproveitável para wallet.
- `Carts::CartSerializer` e domínio atual já trabalham com contratos estáveis de resposta/erro.

### Established Patterns
- Segurança fail-closed para payload e ownership (não confiar em campos sensíveis do frontend).
- Isolamento tenant estrito com máscara de recursos (`404 nao encontrado`) quando aplicável.
- Regras de domínio concentradas em services; controllers só validam shape e delegam.
- Testes de integração e de service como contrato principal.

### Integration Points
- Novas migrations em `marketplace_backend/db/migrate` para `wallets` e `wallet_transactions` com constraints de integridade.
- Novos models em `marketplace_backend/app/models` com associações e validações de centavos/tipos.
- Novo namespace de services (`marketplace_backend/app/services/wallets/`) para cálculo de saldo e inserção append-only.
- Cobertura de testes em `marketplace_backend/test/models`, `test/services` e integração conforme boundary da fase.

</code_context>

<specifics>
## Specific Ideas

- Priorizar integridade financeira e segurança transacional sobre velocidade/simplicidade.
- Ledger nunca sofre `UPDATE`/`DELETE`; toda mutação financeira é novo `INSERT`.
- Manter todos os valores monetários em centavos para evitar problemas de precisão.

</specifics>

<deferred>
## Deferred Ideas

- Expor `GET /wallet` já nesta etapa.
- Expor extrato de transações (`GET /wallet/transactions`) já nesta etapa.

Observação: essas capacidades foram solicitadas na discussão, mas extrapolam o boundary fixo da fase 15 no roadmap; devem entrar em fase dedicada de surface/autorização (fase 18) ou nova fase intermediária.

</deferred>

---

*Phase: 15-wallet-ledger-data-model-and-invariants*
*Context gathered: 2026-03-07*
