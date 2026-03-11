# Phase 30: Static Security Gates and Regression Net - Context

**Gathered:** 2026-03-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Esta fase transforma as ferramentas de segurança já presentes no projeto em gates recorrentes e obrigatórios, tanto localmente quanto no workflow do repositório.
Além disso, consolida uma malha explícita de regressão para throttling e guardrails críticos, de modo que mudanças futuras em rotas, middleware ou configuração quebrem checks automaticamente.

</domain>

<decisions>
## Implementation Decisions

### Existing tooling baseline
- `bundler-audit` e `brakeman` já existem no projeto e não devem ser substituídos nesta fase.
- `bin/ci` já executa style/security/tests, mas ainda não representa um workflow de repositório obrigatório.
- A fase deve fechar o gap entre “comandos existem” e “há um gate único, fail-closed e executado em CI”.

### Single security gate
- O projeto precisa de um entrypoint único e curto para validação estática de segurança, utilizável localmente e em CI.
- Esse gate deve falhar de forma explícita se `bundler-audit` ou `brakeman` detectarem problemas.
- O contrato deve ser claro o bastante para aparecer em documentação e em workflow automatizado sem lógica duplicada.

### CI integration
- Como não existe `.github/workflows` no repo, a fase pode criar um workflow explícito de CI.
- O workflow deve incluir ao menos setup Ruby, dependencies, gate de segurança e suíte de testes principal.
- Evitar duplicação excessiva entre `bin/ci`, script de segurança e workflow YAML.

### Regression net
- Os testes de security/hardening adicionados nas fases 28 e 29 já existem; a fase 30 deve agrupá-los num fluxo de regressão com intenção explícita.
- O foco é garantir que rate limiting, CORS, host/SSL posture e healthcheck-safe behavior estejam cobertos por comando ou suíte reconhecível.
- A fase não precisa reinventar testes; pode consolidar e/orquestrar os existentes.

### Claude's Discretion
- Nome e localização do entrypoint único (`bin/security`, `bin/security-check`, rake task, etc.).
- Se o workflow do repositório chama `bin/ci`, `bin/security` separadamente, ou ambos.
- Como agrupar os testes de regressão: script, task, ou seleção explícita de arquivos.

</decisions>

<code_context>
## Existing Code Insights

### Current Assets
- `marketplace_backend/bin/bundler-audit` já fixa `config/bundler-audit.yml`.
- `marketplace_backend/bin/brakeman` já usa `--ensure-latest`.
- `marketplace_backend/config/ci.rb` já roda `rubocop`, `bundler-audit`, `brakeman` e `rails test`.

### Current Gaps
- Não existe workflow de repositório em `.github/workflows`.
- Não existe um entrypoint único dedicado a “security gate” para uso local/CI; hoje a intenção está espalhada em `bin/ci` e passos separados.
- Os testes de regressão de segurança existem, mas não estão agrupados em uma suíte/fluxo nomeado de segurança.

### Integration Points
- `marketplace_backend/bin/*`
- `marketplace_backend/config/ci.rb`
- `marketplace_backend/config/bundler-audit.yml`
- `.github/workflows/*`
- `marketplace_backend/test/config/production_security_posture_test.rb`
- `marketplace_backend/test/integration/cors_security_test.rb`
- `marketplace_backend/test/integration/healthcheck_test.rb`
- suites de auth/cart/admin abuse da fase 28

</code_context>

<specifics>
## Specific Ideas

- Adicionar `bin/security` como orquestrador fail-closed para `bundler-audit` e `brakeman`.
- Adicionar `bin/security-regression` para rodar a seleção curta de testes de hardening das fases 28 e 29.
- Criar `.github/workflows/ci.yml` ou `.github/workflows/security.yml` chamando os binstubs em vez de reescrever comandos crus.
- Atualizar `config/ci.rb` para reutilizar os novos entrypoints e reduzir drift entre local e CI.

</specifics>

<deferred>
## Deferred Ideas

- Upload de SARIF, code scanning ou integração com Dependabot.
- Gates separados por matrix de banco/Ruby.
- Testes de browser/E2E para CORS/frontends.
- Alertas automáticos de expiração de advisories.

</deferred>

---

*Phase: 30-static-security-gates-and-regression-net*
*Context gathered: 2026-03-11*
