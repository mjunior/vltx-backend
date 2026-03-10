# Phase 24: Global Moderation Surface - Context

**Gathered:** 2026-03-10
**Status:** Ready for planning

<domain>
## Phase Boundary

Esta fase entrega a primeira superfície de moderação global em `/admin`: desativação de usuários, remoção de anúncios inapropriados e leitura global de pedidos da plataforma.
O foco é dar alcance operacional ao admin sem reutilizar os escopos tenant-only de buyer/seller. Ações administrativas sobre contestação ou edição ampla de dados de usuário ficam para fases posteriores.

</domain>

<decisions>
## Implementation Decisions

### Global user deactivation
- Admin pode desativar qualquer usuário da plataforma, sem distinção entre buyer e seller.
- A desativação deve bloquear todo acesso imediatamente.
- Todas as `refresh_sessions` do usuário devem ser revogadas na hora.
- Usuário desativado não consegue mais fazer login e recebe a mesma resposta pública genérica de credencial inválida.
- A resposta de sucesso pode ser mínima, com payload enxuto suficiente para o painel refletir o novo estado.

### Product moderation action
- Moderação de anúncio inapropriado será feita por `soft_delete` direto.
- O produto removido pelo admin deve sumir imediatamente do catálogo público.
- O seller ainda pode ver o produto no próprio contexto privado/histórico; a moderação aqui não precisa apagá-lo de toda superfície interna.
- Nesta fase não é necessário capturar motivo textual de moderação.
- A resposta de sucesso pode ser mínima, retornando apenas o estado relevante do recurso moderado.

### Global admin order read
- Esta fase expõe `GET /admin/orders` e `GET /admin/orders/:id`.
- Não entram filtros nesta primeira versão; a listagem global pode ser simples.
- O payload pode reaproveitar ao máximo o serializer atual de pedidos, mas com autenticação admin-only e sem tenant scope por buyer/seller.
- O admin deve conseguir ver todos os pedidos, inclusive `canceled`, `refunded` e `contested`.
- Ações administrativas sobre pedidos não entram nesta fase; ficam fora do boundary atual.

### Admin response and error policy
- Em `/admin`, manter a mesma política de erro público genérico do projeto: `token invalido`, `nao encontrado`, `payload invalido`.
- Recurso inexistente continua retornando `404 nao encontrado`.
- Para tentativa de moderar recurso já moderado/inativo, erro explícito é aceitável se simplificar a implementação.
- Respostas de sucesso devem ser mínimas nesta fase, em vez de devolver o recurso completo quando isso não for necessário.

### Claude's Discretion
- Nome final dos services/controllers admin de moderação, desde que o namespace `/admin` fique consistente com a fundação da fase 23.
- Se a leitura global de pedidos reaproveita o serializer atual integralmente ou uma variação admin-safe mínima.
- Códigos/shape exatos do erro explícito para recurso já moderado, mantendo coerência com o app.

</decisions>

<specifics>
## Specific Ideas

- Desativar usuário é um bloqueio operacional completo: desloga, revoga sessões e impede novo login.
- Produto moderado some da vitrine pública, mas ainda pode ser consultado no contexto privado do seller.
- O painel admin desta fase privilegia operações mínimas e seguras, com payloads enxutos.

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `marketplace_backend/app/controllers/admin/application_controller.rb`: guard `authenticate_admin!` e `current_admin` já entregues na fase 23.
- `marketplace_backend/app/services/auth/sessions/revoke_all.rb`: padrão pronto para revogar sessões do usuário no momento da desativação.
- `marketplace_backend/app/services/products/soft_delete.rb`: service já existente para soft delete de produto, hoje owner-scoped.
- `marketplace_backend/app/services/products/deactivate.rb`: alternativa já existente, mas descartada como ação primária de moderação para esta fase.
- `marketplace_backend/app/controllers/orders_controller.rb` + `marketplace_backend/app/serializers/orders/order_serializer.rb`: base de leitura de pedido que pode ser reaproveitada sem tenant scope.

### Established Patterns
- Rotas privadas existentes derivam identidade do token e mantêm mensagens públicas genéricas.
- Ownership/tenant scope hoje nasce no query scope; a leitura admin precisará conscientemente sair desse padrão sem afetar os controllers atuais.
- Produto público já respeita `deleted_at` e `active`, então `soft_delete` é suficiente para removê-lo da vitrine.
- O projeto prefere responses mínimas e determinísticas quando o recurso completo não é necessário.

### Integration Points
- `marketplace_backend/config/routes.rb`: ampliar o namespace `/admin` com `users`, `products` e `orders`.
- `marketplace_backend/app/controllers/admin/users_controller.rb`: evoluir além da leitura de `verification_status` para incluir desativação.
- `marketplace_backend/app/controllers/admin/orders_controller.rb`: criar leitura global de listagem e detalhe.
- `marketplace_backend/app/services/products/soft_delete.rb` e domínio de `User`/`RefreshSession`: adaptar services ou criar boundaries admin-specific para moderação global.
- `marketplace_backend/test/integration`: adicionar request tests cobrindo user deactivation, product moderation e global order access via admin.

</code_context>

<deferred>
## Deferred Ideas

- Filtros/paginação avançados em `/admin/orders`.
- Motivo textual de moderação para usuário ou produto.
- Ações administrativas em pedido além da leitura global.
- Alteração ampla de dados do usuário e saldo ficam para a fase 25.

</deferred>

---

*Phase: 24-global-moderation-surface*
*Context gathered: 2026-03-10*
