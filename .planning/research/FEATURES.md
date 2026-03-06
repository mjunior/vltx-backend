# Feature Research

**Domain:** Authentication and session lifecycle
**Researched:** 2026-03-05
**Confidence:** HIGH

## Feature Landscape

### Table Stakes (Users Expect These)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Cadastro com email/senha | Fluxo básico de entrada | LOW | Validar unicidade e força mínima de senha |
| Login com email/senha | Acesso ao sistema | LOW | Respostas uniformes para erro de credencial |
| Access token curto | Segurança padrão para API | LOW | 15 min definido pelo usuário |
| Refresh token | Renovação de sessão sem novo login | MEDIUM | Exige armazenamento e revogação correta |
| Logout | Encerrar acesso | MEDIUM | Aqui será logout global |

### Differentiators (Competitive Advantage)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Refresh rotativo one-time | Proteção forte contra replay | HIGH | Requer detecção de reutilização |
| Revogação global por reuse suspeito | Resposta ativa a comprometimento | HIGH | Revoga todas as sessões do usuário |
| Segredos separados por token | Blast radius reduzido | LOW | Operacionalmente simples e seguro |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| JWT sem persistência de sessão | “Mais simples” | Sem revogação efetiva e sem trilha de sessão | Guardar sessão/refresh hash no banco |
| Refresh eterno | Menos logins | Aumenta janela de abuso | TTL 7 dias com rotação |
| Mensagens detalhadas de erro no login | “Melhor UX” | Facilita enumeração de usuários | Mensagem genérica de credenciais inválidas |

## Feature Dependencies

Cadastro/Login
    └──requires──> User + senha segura
Refresh rotativo
    └──requires──> Sessão persistida + hash + jti
Detecção de reuse
    └──requires──> Estado de revogação + auditoria de sessão

## MVP Definition

### Launch With (v1)

- [ ] Cadastro (`sign up`) com criação de `User` e `Profile`
- [ ] Login com emissão de access+refresh
- [ ] Refresh token rotativo one-time
- [ ] Logout global (revogação de todas as sessões)
- [ ] Revogação global automática quando detectar refresh reutilizado/revogado

### Add After Validation (v1.x)

- [ ] Rate limit avançado por IP/dispositivo
- [ ] Tela/endpoints de gerenciamento de sessões por dispositivo

### Future Consideration (v2+)

- [ ] MFA/2FA
- [ ] OAuth/social login

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Cadastro/Login | HIGH | LOW | P1 |
| Access + Refresh | HIGH | MEDIUM | P1 |
| Refresh rotativo | HIGH | HIGH | P1 |
| Reuse detection com logout global | HIGH | HIGH | P1 |
| Sessões por dispositivo | MEDIUM | MEDIUM | P2 |

## Sources

- Padrões da indústria para auth API com JWT
- Práticas OWASP para sessão e token lifecycle

---
*Feature research for: auth lifecycle*
*Researched: 2026-03-05*
