# Requirements: Marketplace Backend

**Defined:** 2026-03-11
**Milestone:** v1.6 Security and Abuse Hardening
**Core Value:** Isolamento multi-tenant estrito com contratos de autenticação e catálogo previsíveis.

## v1.6 Requirements

### Abuse Prevention

- [x] **ABUSE-01**: Fluxos de autenticação user/admin e emissão de token são limitados por IP e contexto de identidade para reduzir brute force e replay automatizado.
- [x] **ABUSE-02**: Endpoints de alto risco operacional, como mutações de carrinho, checkout e ações administrativas sensíveis, aplicam throttling previsível por ator autenticado ou fallback por IP.
- [x] **ABUSE-03**: Requisições bloqueadas por abuso retornam contrato HTTP 429 consistente, sem vazar informação sensível e com telemetria suficiente para investigação operacional.

### Security Posture

- [ ] **SEC-01**: Produção aplica política explícita para SSL, trusted proxy, host authorization e CORS sem depender de defaults inseguros ou configuração hardcoded de desenvolvimento.
- [ ] **SEC-02**: Healthcheck, domínio Railway e tráfego legítimo conhecido continuam operacionais após o hardening de middleware e configuração de produção.

### Static Security Validation

- [ ] **SEC-03**: Existe um fluxo único e obrigatório de validação estática que executa `bundler-audit` e `brakeman` em modo fail-closed para uso local e CI.
- [ ] **SEC-04**: O projeto possui cobertura de teste para throttling e guardrails críticos de segurança, evitando regressão silenciosa após futuras mudanças de rota ou middleware.

## v2 Requirements

### Security Operations

- **SEC-05**: API registra contadores e eventos de throttle em backend observável para alertas automáticos.
- **SEC-06**: Rate limiting distribuído usa storage compartilhado resiliente entre múltiplas instâncias.
- **SEC-07**: Admin pode gerenciar allowlists/blocklists operacionais sem deploy.

### Authentication

- **AUTH-05**: Admin pode usar MFA/2FA para endurecer login administrativo.

## Out of Scope

| Feature | Reason |
|---------|--------|
| CAPTCHA ou desafio anti-bot no frontend | Depende de UX e integração com cliente, fora do endurecimento backend-first |
| WAF/CDN rules gerenciadas fora do app | Pertence à camada de infraestrutura e não ao milestone de aplicação |
| MFA para admin | Importante, mas separado para não misturar identidade forte com rate limiting inicial |
| Motor avançado de reputação por device/IP | Exige telemetria e políticas adicionais além do hardening básico deste ciclo |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| ABUSE-01 | Phase 28 | Complete |
| ABUSE-02 | Phase 28 | Complete |
| ABUSE-03 | Phase 28 | Complete |
| SEC-01 | Phase 29 | Pending |
| SEC-02 | Phase 29 | Pending |
| SEC-03 | Phase 30 | Pending |
| SEC-04 | Phase 30 | Pending |

**Coverage:**
- v1.6 requirements: 7 total
- Mapped to phases: 7
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-11*
*Last updated: 2026-03-11 after completing phase 28 Rack Abuse Boundary*
