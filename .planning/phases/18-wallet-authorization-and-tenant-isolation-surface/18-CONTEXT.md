# Phase 18: Wallet Authorization and Tenant Isolation Surface - Context

**Gathered:** 2026-03-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Esta fase entrega o surface de consulta de wallet com autorizacao estrita por identidade do token.
Escopo: garantir que usuario autenticado so acesse a propria wallet (saldo e extrato), com contrato de erro seguro contra enumeracao de tenant.

</domain>

<decisions>
## Implementation Decisions

### Endpoints and Resource Shape
- Expor `GET /wallet` (saldo) e `GET /wallet/transactions` (extrato) nesta fase.
- Rotas sem `wallet_id`; wallet sempre derivada de `current_user`.
- Extrato ordenado por mais recente primeiro (`created_at desc, id desc`).
- Saldo retorna `current_balance_cents` inteiro (sem formatacao monetaria em string).

### Authorization and Error Masking
- Sem token: `401 token invalido` (padrao atual).
- Qualquer tentativa de acessar wallet de terceiro/ID forjado: `404 nao encontrado` (mascara anti-enumeracao).
- Se wallet ainda nao existir para usuario autenticado: auto-provisionar wallet vazia e responder sucesso.
- Payload invalido de consulta: `422 payload invalido`.

### Transaction Data Exposure Policy
- Campos do extrato por transacao: `id`, `transaction_type`, `amount_cents`, `balance_after_cents`, `created_at`, `reference_type`, `reference_id`.
- `operation_key` nunca sera exposta.
- `metadata` nao sera exposta nesta fase.

### Query Contract (Hardcoded Simplicity)
- `GET /wallet/transactions` retorna sempre as ultimas 30 transacoes.
- Sem cursor/paginacao nesta fase.
- Sem filtros por tipo ou periodo nesta fase.
- Limite fixo e hardcoded em 30 (sem parametro de entrada para alterar).

### Claude's Discretion
- Nome final dos serializers/DTOs de resposta de wallet e transacoes.
- Organizacao dos services de leitura (`wallets/read/*`) mantendo controllers finos.
- Estrategia de evitar N+1 e indices de leitura, preservando contrato fixo de 30 registros.

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ApplicationController#authenticate_user!` e `current_user`: base pronta para ownership derivado do token.
- Padrão de controllers privados (`ProductsController`, `CartItemsController`) com `render_not_found` para mask de tenant.
- `Wallet` e `WalletTransaction` ja consolidados para leitura de saldo e timeline.
- Scope `WalletTransaction.recent_first`: encaixa direto no extrato de ultimas transacoes.

### Established Patterns
- Endpoints privados exigem autenticacao e nunca confiam em IDs sensiveis enviados pelo cliente.
- Mascaramento de acesso indevido com `404` em recursos privados para reduzir enumeracao.
- Contrato de erro padronizado no projeto: `401 token invalido`, `422 payload invalido`, `404 nao encontrado`.
- Controllers finos com validacao de shape e delegacao para services de dominio.

### Integration Points
- Adicionar novas rotas privadas de wallet em `config/routes.rb`.
- Criar controller(s) de wallet em `app/controllers` seguindo padrao de autenticacao/erro.
- Criar service(s) de leitura de wallet e extrato em `app/services/wallets/` com derivacao por `current_user`.
- Adicionar testes de integracao para authz/tenant isolation dos novos endpoints.

</code_context>

<specifics>
## Specific Ideas

- Contrato explicitamente restrito para extrato: sempre ultimas 30 transacoes, sem opcoes.
- Preferencia por API simples, deterministica e segura na fase inicial de surface.

</specifics>

<deferred>
## Deferred Ideas

- Paginacao/cursor de extrato.
- Filtros de extrato (tipo, periodo, limite customizavel).
- Exposicao controlada de `metadata` no extrato.

</deferred>

---

*Phase: 18-wallet-authorization-and-tenant-isolation-surface*
*Context gathered: 2026-03-08*
