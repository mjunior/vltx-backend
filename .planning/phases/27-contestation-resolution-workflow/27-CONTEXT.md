# Phase 27: Contestation Resolution Workflow - Context

**Gathered:** 2026-03-10
**Status:** Ready for planning

<domain>
## Phase Boundary

Esta fase fecha a primeira resolução administrativa de contestações no painel admin.
O foco é permitir leitura operacional dos pedidos contestados e decisão explícita de approve/deny sob o guard `/admin`, reaproveitando o domínio de pedidos e refund já existente sem manter seller como autoridade final da mediação.

</domain>

<decisions>
## Implementation Decisions

### Contestation read surface
- Não haverá um recurso separado `/admin/contestations` nesta fase.
- A listagem operacional de contestações será feita em `/admin/orders`.
- O backend pode aceitar filtro por status para permitir leitura de pedidos `contested`.
- O fluxo principal do painel será listar pedidos com `status=contested` e abrir detalhe pelo próprio `/admin/orders/:id`.

### Administrative decision endpoints
- A decisão admin terá endpoints dedicados por ação.
- A aprovação deve ser exposta por um endpoint como `/admin/orders/:id/approve`.
- A negação deve ser exposta por um endpoint como `/admin/orders/:id/deny`.
- Não é necessário criar um recurso intermediário de contestação só para estas ações.

### Deny behavior
- Quando o admin negar a contestação, o pedido deve voltar para `delivered`.
- A negação não deve alterar indevidamente o estado financeiro.
- O deny deve funcionar como resolução operacional explícita, encerrando a contestação.

### Approve behavior
- Quando o admin aprovar a contestação, o comprador deve receber refund seguro e idempotente.
- O comportamento financeiro deve seguir a lógica já existente de reversão de crédito do seller e refund buyer-side.
- Se houver `saldo insuficiente` para reverter o seller, a aprovação deve falhar com o comportamento atual.
- Não haverá fluxo especial de compensação nesta fase.

### Decision metadata
- Não é necessário exigir `reason` textual no approve/deny nesta fase.
- A auditoria pode ser satisfeita com transições e metadata operacionais mínimas registradas pelo backend.

### Admin response policy
- O namespace `/admin` mantém a política de erros públicos genéricos do projeto sempre que possível.
- `nao encontrado` continua para pedido inexistente ou inacessível.
- `payload invalido` cobre decisões inválidas para o estado atual do pedido.
- `saldo insuficiente` pode continuar sendo retornado no approve quando a reversão do seller falhar por falta de saldo.

### Claude's Discretion
- Nome final dos services admin de approve/deny, desde que o boundary administrativo fique explícito.
- Se a listagem admin de pedidos usa filtro opcional genérico por status ou lógica interna dedicada para contested.
- Shape exato do payload de sucesso das ações admin, desde que continue coerente com o serializer de pedido já usado no `/admin/orders/:id`.

</decisions>

<specifics>
## Specific Ideas

- Reutilizar `/admin/orders` como superfície de leitura operacional, com filtro por `status=contested`.
- Aprovação admin reaproveita o fluxo financeiro já consolidado de `ApproveContestation`, mas trocando a autoridade do actor.
- Negação admin deve reverter apenas o estado do pedido de `contested` para `delivered`.

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `marketplace_backend/app/controllers/admin/orders_controller.rb`: já expõe listagem e detalhe global de pedidos em `/admin/orders`.
- `marketplace_backend/app/services/orders/approve_contestation.rb`: já implementa refund buyer-side e reversal seller-side com idempotência financeira.
- `marketplace_backend/app/services/orders/contest.rb`: já move pedido para `contested`.
- `marketplace_backend/app/services/orders/apply_transition.rb`: já conhece as transições de workflow incluindo `contest` e `approve_contest`.
- `marketplace_backend/app/serializers/orders/order_serializer.rb`: já serializa pedidos para admin com `actor_role: "admin"` e `available_actions` zerado.

### Established Patterns
- O projeto prefere boundaries admin-specific quando a autoridade do ator muda.
- Wallet ledger e refund já têm invariantes fortes e respostas conhecidas (`saldo insuficiente`, idempotência).
- Leitura admin global de pedidos já existe; a fase pode evoluir essa superfície em vez de criar outro recurso paralelo.
- Mensagens públicas e shape de erro já estão padronizados no namespace admin.

### Integration Points
- `marketplace_backend/config/routes.rb`: expandir `/admin/orders` com filtro e ações `approve`/`deny`.
- `marketplace_backend/app/controllers/admin/orders_controller.rb`: evoluir para aceitar filtro por status e expor ações operacionais.
- `marketplace_backend/test/integration/admin_orders_index_test.rb` e novos testes admin de resolução: cobrir listagem contestada, approve, deny e boundary.
- `marketplace_backend/app/services/orders/approve_contestation.rb` e workflow de transições: adaptar ou encapsular para o actor administrativo.

</code_context>

<deferred>
## Deferred Ideas

- Recurso separado `/admin/contestations`.
- Motivo textual obrigatório da decisão.
- Tratamento especial para insolvência operacional do seller além do erro atual.
- Drill-down analítico de contestação e histórico expandido ficam fora desta fase.

</deferred>

---

*Phase: 27-contestation-resolution-workflow*
*Context gathered: 2026-03-10*
