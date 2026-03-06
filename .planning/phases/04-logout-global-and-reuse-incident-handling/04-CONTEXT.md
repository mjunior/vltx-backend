# Phase 4: Logout Global and Reuse Incident Handling - Context

**Gathered:** 2026-03-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Implementar endpoint de logout global e consolidar resposta de segurança quando houver detecção de reuse de refresh token revogado. Esta fase fecha o ciclo de sessão revogável sem expandir para denylist de access token ou novos fluxos de recuperação fora de login.

</domain>

<decisions>
## Implementation Decisions

### Logout Endpoint Contract
- Endpoint de logout: `POST /auth/logout`.
- Autenticação do logout será por token no header `Authorization` (Bearer).
- Requisição deve exigir `Content-Type: application/json`.
- Sucesso do logout retorna `204 No Content`.

### Logout Global Semantics
- Logout é idempotente: se usuário válido já não tiver sessão ativa, ainda retorna sucesso (`204`).
- Token inválido/revogado/expirado no logout retorna `401` + `{ error: "token invalido" }`.
- Escopo do logout é global: revogar todas as refresh sessions do usuário.
- Auditoria mínima da fase: atualizar `revoked_at` em lote, sem trilha dedicada extra.

### Reuse Incident Response
- Reuse detectado retorna `401`.
- Corpo público em incidente: `{ error: "token invalido" }`.
- Na detecção, executar revogação global imediata das sessões do usuário.
- Não diferenciar publicamente token expirado/revogado/reuse.

### Invalidation Scope After Incident
- Após incidente, invalidar todas as refresh sessions do usuário.
- Access tokens já emitidos seguem até expiração natural (sem denylist nesta fase).
- Novas tentativas de refresh após incidente devem falhar com `401 token invalido` até novo login.
- Recuperação do usuário exige reautenticação via login.

### Claude's Discretion
- Organização de serviços/controllers para aplicar as políticas acima sem alterar contratos públicos.
- Escolha de helpers internos para reaproveitar validação de token e revogação em lote.

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `marketplace_backend/app/services/auth/sessions/revoke_all.rb`: já implementa revogação global de refresh sessions.
- `marketplace_backend/app/services/auth/sessions/detect_reuse.rb`: já identifica reuse de token revogado e aciona revoke global.
- `marketplace_backend/app/services/auth/jwt/verifier.rb`: valida token e padroniza falha pública de token inválido.
- `marketplace_backend/app/controllers/application_controller.rb`: possui render helpers para erros públicos (`token invalido`, etc).

### Established Patterns
- Contratos de erro públicos genéricos para não vazar estado sensível.
- Rotação one-time de refresh já implementada no endpoint de refresh.
- Sessão de refresh persistida com hash + pepper e timestamps de estado.

### Integration Points
- `marketplace_backend/config/routes.rb`: adicionar `POST /auth/logout` no namespace atual de auth.
- `marketplace_backend/app/controllers/auth/*`: novo controller/ação de logout deve seguir padrão de respostas já usado.
- `marketplace_backend/test/integration/*`: adicionar cobertura de logout global e cenários de token inválido/reuse.

</code_context>

<specifics>
## Specific Ideas

- Logout global deve ser simples para cliente: sucesso com `204` e sem payload.
- Reuse incidente e token inválido compartilham mesma resposta pública para reduzir sinalização de estado interno.
- Reautenticação explícita via login como caminho único de recuperação pós-incidente.

</specifics>

<deferred>
## Deferred Ideas

- Denylist de access token (`jti`) para invalidação imediata permanece fora desta fase.
- Auditoria avançada de incidentes (event store/log dedicado) permanece para fase futura, se necessário.

</deferred>

---

*Phase: 04-logout-global-and-reuse-incident-handling*
*Context gathered: 2026-03-06*
