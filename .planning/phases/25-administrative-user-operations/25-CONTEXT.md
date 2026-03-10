# Phase 25: Administrative User Operations - Context

**Gathered:** 2026-03-10
**Status:** Ready for planning

<domain>
## Phase Boundary

Esta fase entrega a superfície operacional do admin para editar dados sensíveis de usuários e ajustar saldo com segurança de ledger, além de completar a leitura administrativa de anúncios para o painel.
O foco é ampliar o `/admin` sem romper invariantes já existentes do domínio de `User`, `Profile`, `Wallet` e `Product`. Senha, métricas e resolução de contestação ficam fora desta fase.

</domain>

<decisions>
## Implementation Decisions

### Administrative user update surface
- Admin pode atualizar os dados gerais de qualquer usuário via `PATCH /admin/users/:id`.
- Nesta fase entram `email`, `verification_status`, `active` e campos de perfil equivalentes a nome, endereço e foto.
- Troca manual de senha fica fora da fase.
- `verification_status` pode transitar nos dois sentidos entre `unverified` e `verified`.
- Colisão de e-mail, payload vazio e payload inválido continuam retornando o erro público genérico `payload invalido`.

### Profile photo field
- O backend já possui `profiles.photo_url`; esta fase deve manter esse campo.
- Não entra migração para `avatar_url`.
- Se o painel usar nomenclatura de avatar, isso pode ser tratado no frontend ou por alias futuro, mas não é objetivo desta fase.

### Reactivation rule for inactive users
- Admin pode reativar usuário via `PATCH /admin/users/:id`.
- Quando o usuário estiver inativo, o endpoint só deve aceitar a reativação (`active: true`).
- Qualquer tentativa de editar outros campos de um usuário inativo deve falhar com `payload invalido`.

### Administrative balance adjustments
- Saldo administrativo não será definido por overwrite; todo ajuste deve passar pelo ledger append-only existente.
- O endpoint será separado: `POST /admin/users/:id/balance-adjustments`.
- Ajustes aceitam apenas `credit` e `debit`.
- `reason` textual livre é obrigatório e deve ficar persistido no metadata da transação.
- `debit` pode reduzir saldo desde que o resultado não fique negativo.
- A resposta de sucesso deve incluir o saldo atualizado e o último movimento criado.

### Admin product read surface
- O painel precisa de listagem e detalhe administrativos de anúncios.
- Esta fase adiciona `GET /admin/products` e `GET /admin/products/:id`.
- A leitura é global, sem tenant scope.
- A listagem deve incluir anúncios ativos e `soft_deleted`.
- Não entram filtros nesta primeira versão.

### Admin response policy
- O namespace `/admin` mantém a política de erros públicos genéricos do projeto: `token invalido`, `credenciais invalidas`, `payload invalido`, `nao encontrado`.
- Respostas de update geral podem devolver o recurso administrativo completo.
- Resposta de ajuste de saldo deve devolver o saldo atualizado e a transação criada.

### Claude's Discretion
- Nome final dos services admin de update de usuário, ajuste de saldo e leitura de produtos.
- Se o serializer admin de usuário passa a incluir saldo atual diretamente ou se isso fica restrito ao detalhe e ao endpoint de ajuste.
- Shape exato do payload administrativo de produto, desde que cubra os campos mínimos para o painel.

</decisions>

<specifics>
## Specific Ideas

- `PATCH /admin/users/:id` é a rota canônica de edição ampla do usuário.
- `POST /admin/users/:id/balance-adjustments` é a rota controlada para crédito/débito administrativo.
- `GET /admin/products` e `GET /admin/products/:id` entram nesta fase para viabilizar listagem de anúncios no painel.

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `marketplace_backend/app/controllers/admin/users_controller.rb`: já concentra leitura admin de usuários e a ação de desativação.
- `marketplace_backend/app/serializers/admin/users/user_serializer.rb`: base atual do payload admin de usuário, ainda enxuta.
- `marketplace_backend/app/services/profiles/update_profile.rb`: normalização e update de `full_name`/`address` já existem no fluxo comum.
- `marketplace_backend/app/services/wallets/operations/apply_movement.rb` e `marketplace_backend/app/services/wallets/ledger/append_transaction.rb`: base obrigatória para ajustes auditáveis de saldo.
- `marketplace_backend/app/controllers/admin/products_controller.rb`: namespace já existe com a ação de `soft_delete`.

### Established Patterns
- O projeto mantém boundaries admin-specific em vez de reaproveitar controllers tenant-scoped diretamente.
- Wallet ledger é append-only e já protege contra saldo negativo e conflitos de idempotência.
- `User` normaliza email e valida unicidade case-insensitive no próprio modelo.
- A superfície admin já trabalha com autenticação segregada e falhas públicas genéricas.

### Integration Points
- `marketplace_backend/config/routes.rb`: expandir `/admin/users` com update geral e balance adjustments, e `/admin/products` com listagem/detalhe.
- `marketplace_backend/app/controllers/admin/users_controller.rb`: evoluir de leitura/desativação para update administrativo.
- `marketplace_backend/app/controllers/admin/products_controller.rb`: evoluir de ação única para leitura administrativa de anúncios.
- `marketplace_backend/test/integration`: adicionar suites para update admin de usuário, ajuste admin de saldo e leitura admin de produtos.

</code_context>

<deferred>
## Deferred Ideas

- Reset ou troca administrativa de senha.
- Migração de `photo_url` para `avatar_url`.
- Filtros, paginação e ordenação avançada em `/admin/products`.
- Dashboard de métricas e resolução de contestação ficam para as fases 26 e 27.

</deferred>

---

*Phase: 25-administrative-user-operations*
*Context gathered: 2026-03-10*
