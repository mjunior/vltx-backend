# Phase 29: Production Security Posture - Context

**Gathered:** 2026-03-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Esta fase endurece a configuração de produção da API Rails para operar atrás do Railway com baseline explícito de segurança.
O foco é transformar defaults comentados ou frágeis em configuração orientada por ambiente para SSL, host authorization, trusted proxy/CORS e falha explícita quando variáveis críticas de segurança estiverem ausentes.

</domain>

<decisions>
## Implementation Decisions

### Production baseline
- `config/environments/production.rb` deve sair do estado de template comentado e passar a declarar decisões explícitas de segurança.
- A fase deve favorecer comportamento seguro por default em produção, mas sem quebrar o deploy Railway já operacional.
- O hardening precisa respeitar `/up` como rota especial de infraestrutura.

### SSL and reverse proxy
- Produção deve assumir que o app roda atrás de proxy terminando SSL.
- `assume_ssl`, `force_ssl` e `ssl_options` precisam ser avaliados juntos para não redirecionar nem quebrar healthcheck.
- O app deve confiar apenas em headers/proxy dentro de uma política explícita; se for necessário usar env flags para Railway/local smoke tests, isso deve ficar visível.

### Host authorization
- A app deve deixar de depender do bloco comentado de `config.hosts`.
- O domínio Railway público e hosts configurados por ambiente precisam ser aceitos explicitamente.
- `/up` continua excluído de bloqueios colaterais necessários ao deploy/healthcheck.

### CORS posture
- `config/initializers/cors.rb` não pode continuar preso a `http://localhost:4200`.
- As origens permitidas devem vir de configuração por ambiente, com parse explícito e falha clara quando produção exigir origins e elas estiverem ausentes.
- O contrato deve continuar compatível com a SPA/consumidor atual sem abrir `*` amplo por conveniência.

### Critical env validation
- Variáveis críticas de segurança de produção devem falhar de forma explícita no boot quando ausentes ou vazias.
- Escopo mínimo: origins CORS de produção e quaisquer toggles/hosts exigidos pelo hardening.
- Não reabrir a discussão entre `RAILS_MASTER_KEY` e `SECRET_KEY_BASE`; esta fase trata postura de produção, não o modelo de secrets já escolhido.

### Railway compatibility
- O deploy atual no Railway e o healthcheck `/up` são restrições duras.
- Testes e validação devem cobrir o domínio Railway/host headers simulados e provar que o hardening não impede boot nem probe.

### Claude's Discretion
- Nome exato das env vars novas (`ALLOWED_ORIGINS`, `APP_HOSTS`, `FORCE_SSL`, etc.) desde que o contrato fique simples e documentado.
- Se a validação de env crítica mora em `production.rb`, initializer dedicado ou helper reutilizável.
- Estrutura dos testes: request/integration, config tests, ou combinação.

</decisions>

<code_context>
## Existing Code Insights

### Current Gaps
- `marketplace_backend/config/environments/production.rb` ainda deixa `assume_ssl`, `force_ssl`, `hosts` e `host_authorization` comentados.
- `marketplace_backend/config/initializers/cors.rb` aceita apenas `http://localhost:4200`, inadequado para produção.
- O deploy Railway já expõe `/up` via `railway.json` e `Dockerfile`, então qualquer hardening precisa preservar essa rota e o domínio Railway.

### Established Patterns
- O projeto já usa env vars explícitas para banco, JWT e storage.
- Hardening anterior na fase 28 protegeu `/up` e Railway no middleware, então a fase 29 deve seguir a mesma disciplina de infraestrutura first.
- Testes de integração request-level são o padrão para contratos públicos e boundaries.

### Integration Points
- `marketplace_backend/config/environments/production.rb`
- `marketplace_backend/config/initializers/cors.rb`
- `marketplace_backend/railway.json`
- `marketplace_backend/Dockerfile` se precisar refletir env/runtime behavior
- `marketplace_backend/test/*` para regressão de host/CORS/healthcheck

</code_context>

<specifics>
## Specific Ideas

- Introduzir parser simples de listas CSV para `APP_HOSTS` e `CORS_ALLOWED_ORIGINS`.
- Deixar `RAILWAY_PUBLIC_DOMAIN` e host configurado manual como entradas válidas para `config.hosts`.
- Cobrir `OPTIONS`/preflight e request normal com origem permitida vs. negada.
- Validar que `/up` continua `200` mesmo com `Host`/SSL policy endurecida.

</specifics>

<deferred>
## Deferred Ideas

- Trusted proxy CIDR detalhado por provider/CDN.
- CSP, HSTS tuning fino e security headers adicionais fora do baseline Rails.
- Rotação/gestão centralizada de secrets ou vault.
- Multi-domain CORS management UI.

</deferred>

---

*Phase: 29-production-security-posture*
*Context gathered: 2026-03-11*
