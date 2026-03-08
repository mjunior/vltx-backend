# Phase 17: Idempotency and Refund Deduplication - Context

**Gathered:** 2026-03-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Esta fase entrega idempotencia financeira forte para operacoes de carteira e deduplicacao deterministica de refund sob retry e concorrencia.
Escopo: garantir no maximo uma movimentacao efetiva por operacao logica, bloquear refund duplicado por referencia de negocio e manter comportamento deterministico em corridas simultaneas.

</domain>

<decisions>
## Implementation Decisions

### Idempotency Key Policy (`operation_key`)
- `operation_key` sera gerada no backend de forma deterministica por operacao de negocio.
- Unicidade permanece com escopo por `wallet_id`.
- A mesma `operation_key` nao pode ser reutilizada em nenhum `transaction_type`.
- Repeticao da mesma chave deve retornar sucesso idempotente com a transacao ja existente (nao erro de duplicado).

### Refund Deduplication Rule
- Refund duplicado sera definido por combinacao de `wallet_id` + `reference_type` + `reference_id` com `transaction_type=refund`.
- Para a mesma referencia de negocio, e permitido no maximo um refund.
- Validacao de teto/dedup de refund usa ledger como fonte de verdade.
- Em refund duplicado concorrente, resposta deve ser sucesso idempotente retornando o refund ja existente.

### Retry and Concurrent Race Contract
- Retry com mesma `operation_key` e mesmo payload retorna sucesso idempotente com a mesma transacao.
- Retry com mesma `operation_key` e payload diferente falha com erro de conflito de idempotencia.
- Fingerprint de idempotencia sera persistido/validado no proprio ledger (sem tabela separada de idempotencia nesta fase).
- Em corrida simultanea, deve haver no maximo 1 insert efetivo; a request concorrente retorna a mesma transacao.

### Ledger vs Materialized Balance Consistency
- Em divergencia entre `wallet.current_balance_cents` e ledger, corrigir o materializado a partir do ledger e falhar a operacao atual (fail-closed).
- Retry idempotente apos divergencia corrigida deve funcionar com resultado deterministico.
- Fonte final de verdade em conflito permanece o ledger.
- Logs estruturados obrigatorios para divergencia/erro de idempotencia: `wallet_id`, `operation_key`, `reference_type`, `reference_id`, `error_code`.

### Claude's Discretion
- Shape exato do fingerprint salvo no ledger (campos diretos vs metadata normalizada), mantendo comparacao deterministica.
- Nome final dos codigos internos de erro para conflito idempotente e dedup de refund.
- Mapeamento final de erros internos para contrato HTTP existente sem regressao de seguranca.

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Wallets::Operations::ApplyMovement`: ponto unico atual para validacao de entrada e delegacao ao ledger.
- `Wallets::Ledger::AppendTransaction`: ja concentra lock de wallet, checagem de saldo, insert append-only e update materializado.
- `WalletTransaction` com indice unico (`wallet_id`, `operation_key`): base para controle de idempotencia por carteira.
- `Carts::Finalize` com `operation_key` deterministica (`checkout:<cart_id>`): origem real para integrar contrato idempotente no checkout.

### Established Patterns
- Fluxo financeiro fail-closed com rollback transacional em erro de dominio.
- Nao confiar em payload sensivel do frontend; valores e referencias criticas saem do backend.
- Ledger append-only com protecao em model + trigger de banco (sem update/delete).
- Testes de service/integration como contrato de comportamento em cenario de seguranca.

### Integration Points
- Evoluir `Wallets::Ledger::AppendTransaction` para resolver idempotencia de sucesso (retorno da transacao existente) e detectar conflito de fingerprint.
- Adicionar regra de unicidade/dedup de refund por referencia de negocio no banco + service.
- Ajustar `Wallets::Operations::ApplyMovement` para propagar estados idempotentes/conflito de forma deterministica.
- Expandir testes de concorrencia/retry (services e checkout) para provar no-maximo-um-insert efetivo.

</code_context>

<specifics>
## Specific Ideas

- Preferencia explicita por seguranca sobre simplicidade/velocidade.
- Sem job de reconciliacao nesta etapa; consistencia corrigida em runtime com fail-closed.
- Em caso de divergencia, sempre acreditar no ledger.

</specifics>

<deferred>
## Deferred Ideas

- Tabela separada de idempotencia dedicada (avaliar em fase futura se necessario por escala/observabilidade).
- Job periodico de reconciliacao ledger x saldo materializado (nao entra na versao inicial).

</deferred>

---

*Phase: 17-idempotency-and-refund-deduplication*
*Context gathered: 2026-03-08*
