# Phase 23: Admin Identity Boundary and Verification Foundation - Context

**Gathered:** 2026-03-10
**Status:** Ready for planning

<domain>
## Phase Boundary

Esta fase entrega a fundação de identidade administrativa separada do domínio `User`: entidade `Admin`, autenticação em `/admin`, JWT com secret dedicado e guard próprio, além do status `unverified`/`verified` no `User`.
Ela não entrega ainda as operações funcionais de moderação e backoffice das próximas fases; aqui o foco é isolar identidade, sessão e contrato base com segurança.

</domain>

<decisions>
## Implementation Decisions

### Admin identity model
- `Admin` será uma entidade própria, separada de `User`.
- Criação de admin será apenas interna por seed/manual bootstrap; não existe signup público de admin.
- Login admin usa `email + password`.
- Neste ciclo existe apenas um tipo de admin, sem roles/permissões internas adicionais.
- Se admin estiver desativado, a autenticação falha com resposta pública genérica de credenciais inválidas.

### Admin session boundary
- Fluxo admin também terá `access + refresh`.
- Sessões administrativas ficam segregadas das sessões de `User`, com storage próprio em vez de compartilhar a tabela atual de refresh sessions.
- JWT admin usa secret dedicado e não reutiliza o secret de user.
- TTL pode começar igual ao fluxo atual (`15 min` access / `7 dias` refresh) para reduzir variabilidade desnecessária nesta primeira entrega.
- `POST /admin/auth/logout` já entra nesta fase e revoga as sessões admin.

### Admin controller and auth contract
- Namespace administrativo nasce em `/admin`.
- Esta fase já expõe `POST /admin/auth/login`, `POST /admin/auth/refresh` e `POST /admin/auth/logout`.
- Guard/admin context deve ser separado de `current_user`; usar `current_admin`/`authenticate_admin!` para evitar confusão e vazamento de escopo nos controllers existentes.
- Mensagens públicas permanecem genéricas, seguindo o padrão atual (`credenciais invalidas`, `token invalido`).
- Estrutura base do namespace admin pode ser criada agora, mas rotas funcionais como `/admin/users` e `/admin/orders` ficam para fases seguintes.

### User verification status foundation
- Todo `User` novo nasce como `unverified`.
- Admin poderá alterar manualmente o status de verificação para suportar o banner/indicador futuro no frontend.
- Nesta fase o status de verificação será visível apenas nas rotas `/admin`, não nas respostas públicas nem nas rotas privadas atuais do usuário.
- O backend nesta fase só precisa persistir e expor o status; OTP/e-mail verification fica fora do escopo.

### Claude's Discretion
- Nome final das classes/módulos de auth admin mantendo separação explícita do fluxo atual de `User`.
- Se o refresh admin usa tabela/model `AdminRefreshSession` dedicado ou nomenclatura equivalente, desde que não compartilhe persistência com `User`.
- Shape exato do payload de resposta de token admin, preservando consistência suficiente com o contrato atual.

</decisions>

<specifics>
## Specific Ideas

- A separação entre `Admin` e `User` é uma medida deliberada para bloquear privilege escalation por mutação de atributos do usuário padrão.
- O namespace `/admin` deve existir desde a base para que o restante do painel admin cresça sem misturar authz com buyer/seller.
- O status `verified` existe aqui como fundação para um banner/indicador visual futuro no frontend, não como entrega de OTP neste milestone.

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `marketplace_backend/app/services/auth/jwt/config.rb`: já concentra secrets, TTL e validação de configuração; pode inspirar um config paralelo de admin JWT com secret dedicado.
- `marketplace_backend/app/services/auth/jwt/issuer.rb` e `verifier.rb`: padrão pronto de emissão/validação com claims mínimas (`sub`, `jti`, `type`, `iat`, `exp`).
- `marketplace_backend/app/services/auth/sessions/*`: fluxo atual de refresh rotativo e revogação global pode ser espelhado para admin com persistência separada.
- `marketplace_backend/app/controllers/application_controller.rb`: concentra respostas públicas genéricas (`token invalido`, `credenciais invalidas`, `payload invalido`).
- `marketplace_backend/app/controllers/auth/logins_controller.rb`, `refreshes_controller.rb` e `logouts_controller.rb`: servem de contrato base para os endpoints admin equivalentes.

### Established Patterns
- Tokens privados usam claims mínimas e erro público genérico.
- Access e refresh já são separados por secret e `type`; o projeto prioriza fail-closed em validação de token.
- Controllers privados existentes sempre derivam identidade autenticada do token, nunca de IDs enviados pelo cliente.
- Escopo tenant atual em controllers como `OrdersController` depende diretamente de `current_user`, reforçando a necessidade de um guard separado para admin.

### Integration Points
- `marketplace_backend/config/routes.rb`: adicionar namespace `/admin` com subescopo de auth.
- `marketplace_backend/app/controllers`: criar base/admin auth controllers separados do fluxo `Auth::...` atual.
- `marketplace_backend/app/models`: introduzir `Admin` e storage de sessão admin separado do domínio de `User`.
- `marketplace_backend/test/integration`: adicionar suíte paralela cobrindo login/refresh/logout admin e rejeição de token user em rotas admin.
- `marketplace_backend/test/test_helper.rb` e config de ambiente: incluir secret(s) de admin JWT para teste/desenvolvimento.

</code_context>

<deferred>
## Deferred Ideas

- MFA/2FA para admin.
- Roles/permissões internas entre diferentes tipos de admin.
- Exposição do status `verified` nas rotas de usuário comum.
- OTP/e-mail verification end-to-end.
- Rotas funcionais de admin (`/admin/users`, `/admin/orders`, `/admin/products`) pertencem às próximas fases.

</deferred>

---

*Phase: 23-admin-identity-boundary-and-verification-foundation*
*Context gathered: 2026-03-10*
