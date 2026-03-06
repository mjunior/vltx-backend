# Stack Research

**Domain:** API authentication and session security (Rails)
**Researched:** 2026-03-05
**Confidence:** HIGH

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Ruby | 3.3.x | Runtime | Compatível com app atual e ecossistema Rails moderno |
| Rails API | 8.0.x | API backend | Convenções sólidas para auth, validação e testes |
| PostgreSQL | 14+ | Persistência transacional | Forte consistência para sessões e revogações |
| jwt gem | 2.x | Assinatura/verificação de JWT | Biblioteca consolidada e simples para tokens customizados |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| bcrypt (`has_secure_password`) | padrão Rails | Hash de senha | Cadastro/login com senha segura |
| ActiveSupport::MessageVerifier (opcional) | Rails | Tokens internos não-JWT | Fluxos internos sem interoperabilidade externa |
| rack-attack (opcional) | 6.x | Rate-limit anti brute-force | Hardening de login/refresh em produção |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| Minitest | Testes unit/integration | Já presente no projeto |
| Brakeman | Scanner de segurança Rails | Rodar no CI |
| RuboCop | Padrão de código | Reduz drift de implementação |

## Installation

```bash
# Core auth dependency
bundle add jwt
```

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| `jwt` gem | `devise-jwt` | Quando quiser autenticação mais acoplada ao Devise |
| Implementação própria de sessão + opaque token | JWT + refresh | Quando não precisa token stateless |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Mesmo secret para access e refresh | Aumenta impacto de vazamento | Secrets separados por tipo de token |
| Persistir refresh token em claro | Alto risco em vazamento de DB | Persistir hash do refresh |
| Refresh não-rotativo | Facilita replay | Rotação one-time com revogação |

## Sources

- `jwt` gem docs
- Rails Guides (API mode, Active Record, Security)
- OWASP JWT Cheat Sheet (boas práticas de expiração, rotação e revogação)

---
*Stack research for: Rails JWT auth*
*Researched: 2026-03-05*
