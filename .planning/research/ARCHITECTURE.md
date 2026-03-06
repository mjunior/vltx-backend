# Architecture Research

**Domain:** Secure JWT auth in Rails API
**Researched:** 2026-03-05
**Confidence:** HIGH

## Standard Architecture

### System Overview

```
Client
  -> AuthController (signup/login/refresh/logout)
    -> Auth services (issue/verify/revoke tokens)
      -> Session store (refresh hash + jti + status)
        -> PostgreSQL
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| `User` | Credencial e identidade de autenticação | `has_secure_password`, validações de email |
| `Profile` | Dados pessoais não sensíveis de login | `has_one :profile` |
| `UserSession` (ou equivalente) | Estado de refresh token e revogação | tabela com `jti`, hash, expiração, revogado |
| `JwtIssuer/JwtDecoder` | Emitir/validar access e refresh | serviço com secret e claims separados |
| `AuthController` | Orquestrar endpoints de auth | actions `signup`, `login`, `refresh`, `logout` |

## Recommended Project Structure

```
marketplace_backend/
├── app/controllers/auth/
├── app/models/
│   ├── user.rb
│   ├── profile.rb
│   └── user_session.rb
├── app/services/auth/
│   ├── token_issuer.rb
│   ├── token_verifier.rb
│   └── refresh_rotator.rb
└── config/initializers/
    └── jwt.rb
```

## Architectural Patterns

### Pattern 1: Token pair with separate trust domains
- Access token e refresh token usam secrets distintos e claims distintas.

### Pattern 2: Rotation with revocation ledger
- Cada refresh válido é usado uma vez; ao consumir, revoga o antigo e cria novo registro.

### Pattern 3: Reuse detection => incident response
- Se refresh já revogado reaparece, tratar como possível comprometimento e invalidar todas as sessões do usuário.

## Data Flow

1. Login
- valida credenciais
- cria sessão
- emite access(15m) + refresh(7d)

2. Refresh
- valida assinatura/exp/token type
- compara hash com sessão ativa
- revoga token atual
- cria nova sessão/token rotativo

3. Logout global
- marca todas as sessões do usuário como revogadas (por `jti`/status)

## Anti-Patterns

- Guardar refresh token plaintext no banco.
- Reemitir refresh sem invalidar anterior.
- Não separar secret de access e refresh.

## Sources

- Rails security practices
- OWASP session/JWT recommendations

---
*Architecture research for: Rails JWT auth*
*Researched: 2026-03-05*
