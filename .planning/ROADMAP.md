# Roadmap: Marketplace Backend

## Milestones

- ✅ **v1.0 Milestone** — shipped 2026-03-06 (Phases 1-5). Archive: [.planning/milestones/v1.0-ROADMAP.md](./milestones/v1.0-ROADMAP.md)
- ✅ **v1.1 Profile and Catalog** — shipped 2026-03-06 (Phases 6-10). Archive: [.planning/milestones/v1.1-ROADMAP.md](./milestones/v1.1-ROADMAP.md)
- ✅ **v1.2 Cart and Checkout Foundation** — shipped 2026-03-07 (Phases 11-14). Archive: [.planning/milestones/v1.2-ROADMAP.md](./milestones/v1.2-ROADMAP.md)
- ✅ **v1.3 Wallet Ledger Hardening** — shipped 2026-03-08 (Phases 15-18). Archive: [.planning/milestones/v1.3-ROADMAP.md](./milestones/v1.3-ROADMAP.md)
- ✅ **v1.4 Orders, Status Flow, and Ratings** — shipped 2026-03-10 (Phases 19-22). Archive: [.planning/milestones/v1.4-ROADMAP.md](./milestones/v1.4-ROADMAP.md)

## Current Milestone

**v1.5 Admin Panel** — active (Phases 23-27)

Goal: criar uma superfície administrativa segregada para operação interna, mantendo a barreira de privilégio separada do domínio de usuário padrão.

### Proposed Roadmap

**5 phases** | **11 requirements mapped** | All covered ✓

| # | Phase | Goal | Requirements | Success Criteria |
|---|-------|------|--------------|------------------|
| 23 | Admin Identity Boundary and Verification Foundation | Criar a identidade `Admin`, auth `/admin`, JWT secret dedicado e status `unverified`/`verified` no usuário | ADM-01, ADM-02, ADM-03, USR-01 | 4 |
| 24 | Global Moderation Surface | Permitir moderação global de usuários, anúncios e pedidos via escopo admin | ADM-04, ADM-05, ADM-06 | 4 |
| 25 | Administrative User Operations | Expor atualização administrativa de dados sensíveis do usuário, incluindo saldo, e completar leitura admin de anúncios | ADM-07 | 4 |
| 26 | Admin Metrics Dashboard | Consolidar métricas operacionais e financeiras para leitura de backoffice | ADM-08 | 3 |
| 27 | Contestation Resolution Workflow | Permitir decisão administrativa sobre contestações com refund seguro quando aprovado | ADM-09, ADM-10 | 4 |

### Phase Details

**Phase 23: Admin Identity Boundary and Verification Foundation**
Goal: criar o domínio `Admin`, autenticação segregada em `/admin` e a fundação de verificação de usuário sem abrir caminho de escalada de privilégio.
Requirements: ADM-01, ADM-02, ADM-03, USR-01
Success criteria:
1. Existe uma entidade administrativa separada de `User`, com autenticação em namespace `/admin`.
2. Token admin é emitido e validado com secret dedicado, sem aceitar tokens do fluxo de usuário comum.
3. Rotas e services administrativos falham para usuários autenticados no fluxo padrão.
4. `User` passa a ter status de verificação `unverified`/`verified` exposto de forma segura para uso futuro.

**Phase 24: Global Moderation Surface**
Goal: permitir que admin execute moderação transversal sobre usuários, anúncios e pedidos sem reusar escopos tenant-only do buyer/seller.
Requirements: ADM-04, ADM-05, ADM-06
Success criteria:
1. Admin consegue desativar qualquer usuário por rota `/admin`.
2. Admin consegue remover ou desativar anúncios inapropriados globalmente.
3. Admin consegue listar e consultar pedidos de toda a plataforma.
4. Endpoints globais não ficam acessíveis para autenticação de usuário comum.

**Phase 25: Administrative User Operations**
Goal: permitir edição administrativa controlada de dados de usuário, incluindo campos sensíveis e saldo, e completar a listagem administrativa de anúncios para o painel.
Requirements: ADM-07
Success criteria:
1. Admin consegue atualizar e-mail, foto e demais campos permitidos de qualquer usuário.
2. Ajuste de saldo ocorre por fluxo controlado e auditável, sem violar invariantes do ledger.
3. Atualizações administrativas mantêm validações de domínio e retornos consistentes.
4. Painel admin consegue listar e abrir anúncios da plataforma, inclusive moderados.

**Phase 26: Admin Metrics Dashboard**
Goal: consolidar indicadores essenciais de operação para leitura rápida do backoffice.
Requirements: ADM-08
Success criteria:
1. Dashboard retorna total de usuários da plataforma.
2. Dashboard retorna pedidos agregados por status.
3. Dashboard retorna volume financeiro do período solicitado com filtros de intervalo claros.

**Phase 27: Contestation Resolution Workflow**
Goal: fechar a primeira mediação operacional de contestação sob controle admin com approve/deny explícitos.
Requirements: ADM-09, ADM-10
Success criteria:
1. Admin consegue listar contestações pendentes de decisão.
2. Admin consegue negar contestação sem alterar indevidamente estado financeiro.
3. Admin consegue aprovar contestação disparando refund buyer-side seguro e idempotente.
4. Decisão administrativa fica registrada de forma auditável para análise posterior.

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
| 26. Admin Metrics Dashboard | v1.5 | 1 | Pending | — |
| 27. Contestation Resolution Workflow | v1.5 | 2 | Pending | — |
