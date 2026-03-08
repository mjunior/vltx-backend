# Phase 15: Wallet Ledger Data Model and Invariants - Research

**Date:** 2026-03-07
**Status:** Complete

## Objective

Definir a implementação da base de carteira em modelo ledger append-only com trilha de saldo em centavos, preservando invariantes financeiros e consistência transacional.

## Key Findings

### 1. Modelo híbrido atende segurança + performance sem quebrar rastreabilidade

- Decisão de contexto fixa `wallet.current_balance_cents` materializado para leitura operacional.
- Ledger permanece fonte de verdade auditável por histórico append-only.
- Em divergência runtime, fluxo deve recalcular via ledger, corrigir materializado e falhar a operação atual (fail-closed).
- Conclusão: modelar `wallets` + `wallet_transactions` é necessário já na fase 15 para suportar fases 16/17 sem refactor estrutural.

### 2. Integridade de append-only deve ser reforçada em múltiplas camadas

- Aplicação sozinha não garante imutabilidade contra uso direto de DB.
- É necessário combinar: API/service sem paths de update/delete + gatilho/bloqueio em banco para impedir `UPDATE`/`DELETE` em `wallet_transactions`.
- Conclusão: append-only deve ser garantido por contrato de código e por constraint operacional no PostgreSQL.

### 3. Invariantes monetários exigem centavos inteiros e tipagem explícita

- `amount_cents` e `balance_after_cents` precisam ser `bigint`/`integer` sem float/decimal monetário no ledger.
- Tipo da transação deve ser restrito a `credit`, `debit`, `refund` por constraint de banco + validação de model.
- Conclusão: schema precisa check constraints explícitas para impedir drift de domínio.

### 4. Cálculo de `balance_after_cents` deve ser atômico e server-side

- `balance_after_cents` não pode vir do frontend/requester.
- Fluxo correto: lock da wallet, obter saldo atual, aplicar signed amount, validar não-negativo (quando aplicável), inserir transação com `balance_after_cents`, atualizar materializado na mesma transação.
- Conclusão: service dedicado de lançamento ledger é requisito estrutural da fase 15 para cumprir WAL-03.

### 5. Estrutura de referência precisa antecipar idempotência futura sem antecipar escopo

- Contexto fixa `reference_type`, `reference_id`, `operation_key` e `metadata jsonb` com whitelist.
- Unicidade de `operation_key` por `wallet_id` já prepara fase 17 sem redefinir schema.
- Conclusão: criar colunas e índice único agora reduz risco de migração disruptiva depois.

## Recommended Implementation Direction

1. Criar tabela `wallets` com `user_id` (unique FK) e `current_balance_cents` inteiro não-negativo com default zero.
2. Criar tabela `wallet_transactions` com FKs, tipo enumado por string restrita (`credit|debit|refund`), `amount_cents > 0`, `balance_after_cents >= 0`, referências de operação e `metadata jsonb`.
3. Adicionar proteção de imutabilidade da ledger (bloqueio de update/delete) no banco.
4. Implementar models `Wallet` e `WalletTransaction` com validações de domínio alinhadas às constraints.
5. Implementar service transacional de append ledger calculando `balance_after_cents` server-side com correção fail-closed em divergência.
6. Cobrir com testes de model/service para invariantes WAL-01..04.

## Validation Architecture

A fase deve ser validada com testes de model + service:

- `WalletTransaction` recusa tipo fora de `credit|debit|refund`;
- `amount_cents` aceita apenas inteiro positivo;
- update/delete de ledger falham por política append-only;
- service calcula `balance_after_cents` no backend e persiste junto da transação;
- valores monetários são sempre tratados em centavos;
- em divergência entre ledger e materializado, service corrige materializado e falha a operação atual.

## Risks and Mitigations

- **Risco:** bypass de append-only por acesso SQL direto.
  - **Mitigação:** trigger/restrição no PostgreSQL para bloquear `UPDATE`/`DELETE` em `wallet_transactions`.

- **Risco:** inconsistência entre saldo materializado e ledger sob concorrência/falhas parciais.
  - **Mitigação:** lock + transação única na escrita e política fail-closed em mismatch.

- **Risco:** regressão de contrato monetário por uso de decimal/float em novos pontos de código.
  - **Mitigação:** centralizar API de saldo em `_cents`, validações explícitas e testes de unidade focados em inteiros.

---

*Phase: 15-wallet-ledger-data-model-and-invariants*
*Research date: 2026-03-07*
