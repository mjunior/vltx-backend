# Phase 26: Admin Metrics Dashboard - Context

**Gathered:** 2026-03-10
**Status:** Ready for planning

<domain>
## Phase Boundary

Esta fase entrega o primeiro dashboard administrativo do backoffice em `/admin/dashboard`, consolidando leitura rápida de métricas operacionais e financeiras.
O foco é oferecer um snapshot fixo e simples dos últimos 30 dias, sem abrir filtros parametrizáveis no frontend neste ciclo. Contestação, analytics avançado e drill-down ficam para fases futuras.

</domain>

<decisions>
## Implementation Decisions

### Dashboard endpoint contract
- O dashboard será exposto em um único endpoint: `GET /admin/dashboard`.
- O endpoint fica atrás de `authenticate_admin!`.
- Não haverá parâmetros de período ou filtros nesta fase.
- A resposta pode ser direta e agregada em um único payload.

### Time window
- O dashboard sempre considera os últimos 30 dias.
- Esse recorte fica hardcoded no backend nesta fase.
- O frontend não precisa enviar `start_date` nem `end_date`.
- O contrato não precisa aceitar datas arbitrárias neste ciclo.

### User metrics
- O dashboard deve retornar `total_users`.
- O dashboard também deve retornar `active_users`.
- `total_users` inclui todos os usuários da plataforma, inclusive desativados.
- `active_users` permite leitura operacional da base atualmente habilitada.

### Order metrics
- O dashboard deve retornar `total_orders` no período.
- O dashboard deve retornar `orders_by_status`.
- `orders_by_status` deve incluir todos os status possíveis do domínio `Order`, mesmo quando a contagem for zero.
- A contagem considera pedidos criados nos últimos 30 dias e agrupados pelo status atual.

### Financial volume
- O dashboard deve retornar um único número financeiro nesta fase.
- Esse número será o somatório bruto de `subtotal_cents` dos pedidos criados nos últimos 30 dias.
- Não haverá cálculo líquido descontando cancelamentos, refunds ou reversões nesta primeira versão.
- O nome do campo deve refletir a natureza bruta do dado, por exemplo `gross_volume_cents`.

### Admin response policy
- O namespace `/admin` mantém a política de erros públicos genéricos do projeto.
- Como o endpoint não aceita filtros nesta fase, a chance de `payload invalido` deve ser mínima.
- User token continua sem acesso ao dashboard admin.

### Claude's Discretion
- Shape exato do payload consolidado, desde que inclua `total_users`, `active_users`, `total_orders`, `orders_by_status` e o volume bruto.
- Se o payload também expõe a janela calculada (`window_days`, `starts_at`, `ends_at`) para ajudar o frontend a rotular o card.
- Nome final do service de leitura do dashboard e eventuais serializers auxiliares.

</decisions>

<specifics>
## Specific Ideas

- `GET /admin/dashboard` deve ser um endpoint de leitura simples e sem parâmetros.
- O painel admin desta fase privilegia um snapshot estável dos últimos 30 dias.
- O volume financeiro é bruto por pedidos criados no período, não por ledger líquido.

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `marketplace_backend/app/controllers/admin/application_controller.rb`: já fornece o guard admin-only para a nova rota.
- `marketplace_backend/app/models/order.rb`: define todos os status válidos do domínio, úteis para o mapa completo com zeros.
- `marketplace_backend/app/services/seller_finance/read_summary.rb`: já demonstra padrões de agregação financeira em cents e serialização enxuta de totais.
- `marketplace_backend/app/controllers/admin/orders_controller.rb`: já abriu a superfície administrativa de leitura de pedidos e pode orientar o estilo do novo controller de dashboard.

### Established Patterns
- O projeto prefere endpoints admin específicos, com boundaries separados de buyer/seller.
- Totais financeiros são tratados em cents no backend.
- Respostas admin atuais são diretas, com payloads previsíveis e sem parâmetros desnecessários quando o caso de uso ainda é simples.
- A barreira entre token de user e token de admin já está bem coberta por testes de boundary.

### Integration Points
- `marketplace_backend/config/routes.rb`: adicionar `GET /admin/dashboard`.
- `marketplace_backend/app/controllers/admin`: criar controller de dashboard ou endpoint dedicado.
- `marketplace_backend/test/integration`: adicionar teste de dashboard admin e regressão de boundary.
- `marketplace_backend/app/models/order.rb` e `marketplace_backend/app/models/user.rb`: fontes primárias das agregações de pedidos e usuários.

</code_context>

<deferred>
## Deferred Ideas

- Filtros customizados por período no dashboard.
- Volume líquido, segmentações financeiras e séries temporais.
- Drill-down por seller, buyer, categoria ou anúncio.
- Métricas de contestação entram na fase 27, não aqui.

</deferred>

---

*Phase: 26-admin-metrics-dashboard*
*Context gathered: 2026-03-10*
