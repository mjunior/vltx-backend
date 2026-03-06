# Pitfalls Research

**Domain:** JWT auth with rotating refresh tokens
**Researched:** 2026-03-05
**Confidence:** HIGH

## Critical Pitfalls

### Pitfall 1: Refresh token replay

**What goes wrong:** token roubado é reutilizado para manter sessão indevida.
**Why it happens:** rotação incompleta ou sem estado persistido.
**How to avoid:** refresh one-time, revogar anterior e persistir estado por `jti`.
**Warning signs:** múltiplos refreshes quase simultâneos para mesma sessão.
**Phase to address:** Phase 3-4.

---

### Pitfall 2: Secret reuse between token classes

**What goes wrong:** comprometimento único afeta access e refresh.
**Why it happens:** simplificação operacional insegura.
**How to avoid:** secrets separados, rotação independente.
**Warning signs:** mesmo env var para ambos os tokens.
**Phase to address:** Phase 2.

---

### Pitfall 3: Inability to revoke stateless JWT

**What goes wrong:** usuário faz logout e token continua válido até expirar.
**Why it happens:** ausência de `jti` e ledger de revogação.
**How to avoid:** incluir `jti` e checagem de revogação nas operações críticas.
**Warning signs:** logout não altera estado persistido.
**Phase to address:** Phase 2-4.

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Mensagem de login muito específica | Enumeração de conta | Mensagem genérica |
| Hash fraco/ausente de refresh token | Vazamento de sessão | Hash forte e comparação segura |
| Sem invalidação global em reuse suspeito | Persistência de invasão | Revogar todas as sessões do usuário |

## "Looks Done But Isn't" Checklist

- [ ] Login retorna tokens, mas sem `jti` auditável
- [ ] Refresh funciona, mas token antigo segue válido
- [ ] Logout retorna 200, mas não revoga sessões
- [ ] Secrets separados no código, porém iguais no ambiente

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Replay de refresh | 3-4 | Teste de reuse deve disparar logout global |
| Secret reuse | 2 | Config com duas chaves distintas obrigatórias |
| Revogação inefetiva | 4 | Logout invalida todas as sessões ativas |

## Sources

- OWASP JWT Cheat Sheet
- Boas práticas de incident response em auth

---
*Pitfalls research for: secure JWT lifecycle*
*Researched: 2026-03-05*
