# Roadmap: Marketplace Backend

## Milestones

- ✅ **v1.0 Milestone** — shipped 2026-03-06 (Phases 1-5). Archive: [.planning/milestones/v1.0-ROADMAP.md](./milestones/v1.0-ROADMAP.md)
- ✅ **v1.1 Profile and Catalog** — shipped 2026-03-06 (Phases 6-10). Archive: [.planning/milestones/v1.1-ROADMAP.md](./milestones/v1.1-ROADMAP.md)
- ✅ **v1.2 Cart and Checkout Foundation** — shipped 2026-03-07 (Phases 11-14). Archive: [.planning/milestones/v1.2-ROADMAP.md](./milestones/v1.2-ROADMAP.md)
- ✅ **v1.3 Wallet Ledger Hardening** — shipped 2026-03-08 (Phases 15-18). Archive: [.planning/milestones/v1.3-ROADMAP.md](./milestones/v1.3-ROADMAP.md)
- ✅ **v1.4 Orders, Status Flow, and Ratings** — shipped 2026-03-10 (Phases 19-22). Archive: [.planning/milestones/v1.4-ROADMAP.md](./milestones/v1.4-ROADMAP.md)
- ✅ **v1.5 Admin Panel** — shipped 2026-03-11 (Phases 23-27). Archive: [.planning/milestones/v1.5-ROADMAP.md](./milestones/v1.5-ROADMAP.md)

## Current Milestone

**v1.6 Security and Abuse Hardening** — active (Phases 28-30)

Goal: endurecer a API contra abuso automatizado e regressões de segurança com throttling em Rack, configuração segura de produção e validações estáticas obrigatórias.

### Proposed Roadmap

**3 phases** | **7 requirements mapped** | All covered ✓

| # | Phase | Goal | Requirements | Success Criteria |
|---|-------|------|--------------|------------------|
| 28 | Rack Abuse Boundary | Introduzir throttling em Rack para auth, tokens e endpoints de alto risco com contrato 429 consistente | ABUSE-01, ABUSE-02, ABUSE-03 | 4 |
| 29 | Production Security Posture | Endurecer configuração de produção para SSL, hosts, proxy e CORS sem quebrar Railway ou healthchecks | SEC-01, SEC-02 | 4 |
| 30 | Static Security Gates and Regression Net | Consolidar validações estáticas de segurança e testes de regressão para throttling/guardrails | SEC-03, SEC-04 | 4 |

### Phase Details

**Phase 28: Rack Abuse Boundary**
Goal: bloquear bursts e brute force cedo no stack Rack, antes da camada de controller, com regras previsíveis para auth e endpoints sensíveis.
Requirements: ABUSE-01, ABUSE-02, ABUSE-03
Success criteria:
1. Login/signup/refresh user e admin recebem throttles distintos e adequados ao risco.
2. Endpoints write/high-cost críticos recebem throttles por ator autenticado com fallback por IP.
3. Resposta de bloqueio é 429 estável e não revela se credencial ou recurso existe.
4. Eventos de throttle ficam rastreáveis em logs/telemetria mínima para suporte operacional.

**Phase 29: Production Security Posture**
Goal: explicitar o baseline de segurança de produção no app, removendo defaults frágeis e alinhando a configuração ao deploy Railway.
Requirements: SEC-01, SEC-02
Success criteria:
1. Produção define política clara para SSL, proxy confiável e headers/hosts aceitos.
2. CORS deixa de depender de origem localhost hardcoded e passa a seguir configuração por ambiente.
3. Healthcheck `/up` e domínio Railway seguem funcionais após o hardening.
4. Configuração falha de forma explícita quando variáveis críticas de segurança estiverem ausentes.

**Phase 30: Static Security Gates and Regression Net**
Goal: transformar segurança estática e comportamento anti-abuso em gate recorrente, não em checagem ad hoc.
Requirements: SEC-03, SEC-04
Success criteria:
1. Existe um comando/fluxo único para rodar `bundler-audit` e `brakeman` em modo obrigatório.
2. O gate de segurança é integrado ao fluxo padrão de CI do projeto.
3. Testes cobrem ao menos o caminho feliz e o bloqueio dos throttles principais.
4. Alterações futuras em rotas/configuração de segurança quebram testes ou checks quando regressivas.

## Progress

| Phase | Milestone | Requirements | Status | Completed |
|-------|-----------|--------------|--------|-----------|
| 19. Order Persistence and Stock Integrity | v1.4 | 4 | Completed | 2026-03-09 |
| 20. Order-Linked Ledger and Wallet Provisioning | v1.4 | 1 | Completed | 2026-03-10 |
| 21. Secure Order Workflow and Cancellation Refunds | v1.4 | 6 | Completed | 2026-03-10 |
| 22. Seller Finance Surface, Contestation, and Ratings | v1.4 | 4 | Completed | 2026-03-10 |
| 23. Admin Identity Boundary and Verification Foundation | v1.5 | 4 | Completed | 2026-03-10 |
| 24. Global Moderation Surface | v1.5 | 3 | Completed | 2026-03-10 |
| 25. Administrative User Operations | v1.5 | 1 | Completed | 2026-03-10 |
| 26. Admin Metrics Dashboard | v1.5 | 1 | Completed | 2026-03-11 |
| 27. Contestation Resolution Workflow | v1.5 | 2 | Completed | 2026-03-11 |
| 28. Rack Abuse Boundary | v1.6 | 3 | Completed | 2026-03-11 |
| 29. Production Security Posture | v1.6 | 2 | Planned | — |
| 30. Static Security Gates and Regression Net | v1.6 | 2 | Planned | — |
