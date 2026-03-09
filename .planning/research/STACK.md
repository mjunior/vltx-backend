# Stack Research

**Domain:** Marketplace orders, workflow state, settlement, and ratings (Rails)
**Researched:** 2026-03-09
**Confidence:** HIGH

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Ruby | 3.3.x target app runtime | Runtime | Alinha com o app Rails atual |
| Rails API | 8.0.x | API backend | Já sustenta services transacionais e authz token-driven |
| PostgreSQL | 14+ | Persistência transacional | Necessário para locks, constraints e trilha auditável |
| Existing wallet ledger | current app | Débito/refund/recebível | Já implementa append-only e idempotência |

### Workflow Libraries

| Library | Current Signal | Fit | Notes |
|---------|----------------|-----|-------|
| `statesman` | ativo no ecossistema Ruby | HIGH | Tabela de transições separada, forte para auditoria e regras explícitas |
| `state_machines-activerecord` | releases recentes em 2025 | MEDIUM-HIGH | DSL boa para model, mas auditoria precisa ser adicionada/disciplinada |
| `aasm` | amplamente usado | MEDIUM | Bom para simplicidade, menos atraente para histórico robusto de transições |

## Recommendation

Priorizar `Statesman` para `Order`, porque este milestone tem transições sensíveis por ator e precisa reduzir brechas de alteração indevida de status. Se a equipe preferir uma DSL mais direta no model, `state_machines-activerecord` é a alternativa mais aceitável, desde que combinado com trilha persistida e bloqueio de update direto no campo de status.

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Atualização direta de `orders.status` por controller | Permite salto de estado e bypass de authz | Services/commands de transição |
| `cart_id` como referência final do ledger | Perde rastreabilidade depois que o pedido existe | `order_id` |
| Saldo seller tratado como payout final desde o início | Complica cancelamento/contestação | Recebível separado |

## Sources

- https://github.com/gocardless/statesman
- https://rubygems.org/gems/statesman
- https://github.com/state-machines/state_machines-activerecord
- https://rubygems.org/gems/state_machines-activerecord
- https://github.com/aasm/aasm
- https://rubygems.org/gems/aasm

---
*Stack research for: Rails marketplace order workflow*
*Researched: 2026-03-09*
