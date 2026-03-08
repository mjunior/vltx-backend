# Phase 16: Transaction Safety and Non-Negative Balance Enforcement - Context

**Gathered:** 2026-03-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Esta fase garante segurança transacional das movimentações financeiras da carteira.
Escopo: lock obrigatório antes de movimentar saldo, bloqueio de operações que negativariam a wallet sem side effects, e validação/recálculo server-side de valores críticos sem confiar no frontend.

</domain>

<decisions>
## Implementation Decisions

### Locking Strategy for Critical Operations
- Toda operação crítica usa lock pessimista na linha de `wallet` (`SELECT ... FOR UPDATE` / `Wallet.lock.find`) como lock principal.
- Ordem de lock obrigatória para evitar deadlock: primeiro `wallet`, depois entidade de referência (`order`/`cart`/outra origem confiável).
- Janela de lock mínima: apenas cálculo de saldo, insert em ledger e update do saldo materializado.
- Em contenção de lock, operação aguarda lock normalmente (com timeout do banco), sem `NOWAIT` nesta fase.

### Insufficient Funds and Side-Effect Safety
- Quando a operação levaria saldo a negativo, retorna erro de domínio interno `insufficient_funds`.
- Em saldo insuficiente, garantia obrigatória: nenhum insert em `wallet_transactions` e nenhum update em `wallet.current_balance_cents`.
- Se houver mismatch ledger/materializado durante operação, erro prioritário é `balance_mismatch` (consistência primeiro).
- Retry após insuficiência deve ser determinístico e sem geração de registros adicionais indevidos.

### Trusted Source of Financial Amounts
- `debit`: valor sempre calculado server-side a partir de fonte de negócio persistida e confiável (snapshot/order/cart), ignorando valor do FE.
- `refund`: valor sempre derivado da referência persistida/transação original, nunca definido pelo cliente.
- `credit`: permitido apenas por origem confiável server-to-server com referência obrigatória.
- `metadata`: whitelist estrita com normalização server-side; chaves fora da whitelist são rejeitadas.

### Error Surface and Security Logging
- Contrato externo mantém erro genérico (`payload invalido`) para cenários de falha de domínio desta fase.
- Logs internos obrigatórios e estruturados por tentativa bloqueada: `user_id`, `wallet_id`, `operation_key`, `reference_type`, `reference_id`, `error_code`.
- Não registrar payload bruto sensível em logs; registrar apenas dados mínimos para auditoria.
- HTTP status mantém padrão do projeto nesta fase: `422 payload invalido`, `404 nao encontrado` (mascaramento tenant), `401 token invalido`.

### Claude's Discretion
- Nomenclatura final dos services de movimentação e organização de responsabilidades (`wallets/ledger` vs `wallets/operations`).
- Estratégia concreta para mapear `error_code` interno para contrato HTTP já existente sem quebrar padrões atuais.
- Formato exato de log estruturado e ponto de emissão (service principal vs camada de controller).

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Wallets::Ledger::AppendTransaction` já implementa lock em wallet e update atômico de saldo materializado + ledger.
- `Wallet` e `WalletTransaction` já possuem invariantes de centavos e append-only.
- `ApplicationController` já padroniza `render_invalid_payload`, `render_invalid_token` e contrato HTTP de erro.
- `Carts::Finalize` já segue padrão transacional com lock em fluxo financeiro crítico.

### Established Patterns
- Controllers finos com validação de shape + delegação para service de domínio.
- Fail-closed em divergência de consistência (`balance_mismatch`) sem continuar operação.
- Não confiar em payload sensível do frontend para valores críticos.
- Testes de service e integração como fonte de verdade de contrato comportamental.

### Integration Points
- Expandir `Wallets::Ledger::AppendTransaction` para cobrir validações completas de WAL-06/07/08 com contratos de erro internos.
- Integrar futuras entradas de débito/reembolso ao service único de movimentação para centralizar lock e checagem de saldo.
- Adicionar testes para concorrência básica, insuficiência de saldo e ausência de side effects em falhas.
- Preparar acoplamento seguro com fluxo de pedido/checkout sem expor detalhes sensíveis no contrato externo.

</code_context>

<specifics>
## Specific Ideas

- Prioridade explícita nesta fase: segurança financeira e consistência de ledger acima de conveniência de API.
- Fluxo de escrita financeira deve permanecer determinístico mesmo sob retry e contenção.
- Decisões de erro externo devem continuar alinhadas ao padrão já adotado no backend para evitar regressão de contrato.

</specifics>

<deferred>
## Deferred Ideas

- Exposição de erro de domínio específico no body HTTP para clientes externos.
- Surface pública/privada de consulta de wallet/extrato (fase 18 ou fase dedicada).
- Estratégias avançadas de lock-fail-fast (`NOWAIT`) e tuning de contenção para fase posterior de performance.

</deferred>

---

*Phase: 16-transaction-safety-and-non-negative-balance-enforcement*
*Context gathered: 2026-03-08*
