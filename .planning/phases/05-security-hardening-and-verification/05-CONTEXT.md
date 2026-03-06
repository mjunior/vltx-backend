# Phase 5: Security Hardening and Verification - Context

**Gathered:** 2026-03-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Consolidar hardening final de segurança e validação da milestone v1 com suíte abrangente de testes de auth/sessão, critérios de severidade explícitos e evidências de ausência de regressão. Esta fase não adiciona novos recursos de produto; fecha robustez e critérios de aceite.

</domain>

<decisions>
## Implementation Decisions

### Final Test Matrix
- Suíte final prioriza **integration/request tests** com complementos de service tests.
- Cobertura obrigatória de fluxo feliz: `signup`, `login`, `refresh`, `logout`.
- Cobertura obrigatória de cenários de falha/ataque:
  - replay/reuse
  - token expirado
  - token inválido/malformado
  - payload inválido
- Testes de contrato HTTP (status + shape de resposta) são obrigatórios em todos os endpoints de auth.

### Hardening Severity Policy
- Qualquer falha de segurança ou regressão de contrato bloqueia a fase.
- Vazamento de mensagem sensível (enumeração/estado interno) é bloqueador imediato.
- Regressão em one-time refresh ou revogação global é bloqueador imediato.
- Teste flaky em suíte de segurança também é bloqueador até estabilização.

### Minimal Audit Scope
- Fase 5 cobre comportamento externo + logging mínimo de incidente.
- Reuse incidente deve gerar log de aplicação com contexto mínimo.
- Conteúdo mínimo de log: `user_id`, tipo de incidente, timestamp (sem token raw/jti raw sensível).
- Logging é best effort: falha de log não quebra fluxo de auth.

### Milestone Completion Criteria
- Suíte completa de testes deve estar 100% verde.
- Todos os requisitos v1 devem estar `Complete` e sem gaps.
- `05-VERIFICATION.md` deve fechar com status `passed`.
- Após fase 5, executar fechamento formal da milestone (`$gsd-complete-milestone`).

### Claude's Discretion
- Organização da suíte final entre integração/serviço mantendo os gates acima.
- Estrutura de utilitários/helpers de teste para reduzir duplicação sem alterar contratos.

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `marketplace_backend/test/integration/auth_*_test.rb`: base já ampla para todos fluxos principais.
- `marketplace_backend/test/services/auth/sessions/revocation_test.rb` e `rotation_test.rb`: cobertura de núcleo de sessão revogável.
- `marketplace_backend/app/controllers/application_controller.rb`: centraliza mensagens públicas de erro.
- `marketplace_backend/app/services/auth/sessions/*`: pontos claros para hardening de incident logging.

### Established Patterns
- Contratos públicos estáveis (`token invalido`, `credenciais invalidas`, `cadastro invalido`).
- Refresh one-time com revogação global em incidente já implementado.
- Política atual de segurança é fail-closed para validação de token/sessão.

### Integration Points
- `marketplace_backend/test/integration/*`: expandir casos negativos e cobertura de contrato.
- `marketplace_backend/test/services/auth/sessions/*`: reforçar invariantes de revogação/reuse.
- `marketplace_backend/app/services/auth/sessions/detect_reuse.rb`: ponto primário para log mínimo de incidente.

</code_context>

<specifics>
## Specific Ideas

- Consolidar uma matriz de cenários de segurança explícita para impedir lacunas no fechamento de v1.
- Tratar flaky test de segurança como falha de release, não como débito pós-milestone.
- Fechar milestone somente com evidência documental (`VERIFICATION passed` + requisitos completos + suíte verde).

</specifics>

<deferred>
## Deferred Ideas

- Auditoria avançada persistida (event store/model dedicado) permanece fora de v1.
- Denylist de access token para invalidação imediata segue fora do escopo atual.

</deferred>

---

*Phase: 05-security-hardening-and-verification*
*Context gathered: 2026-03-06*
