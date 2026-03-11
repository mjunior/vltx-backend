# Phase 28: Rack Abuse Boundary - Context

**Gathered:** 2026-03-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Esta fase adiciona um boundary anti-abuso em Rack para bloquear brute force e bursts automatizados antes da camada de controller.
O escopo cobre throttling para auth user/admin, refresh token e endpoints write/high-cost mais sensíveis do domínio atual, com resposta HTTP 429 uniforme e sem vazamento de informação.

</domain>

<decisions>
## Implementation Decisions

### Middleware choice
- O throttling será implementado em Rack, não em controllers ou services.
- A solução preferencial desta fase é um middleware dedicado baseado em `rack-attack`.
- O armazenamento inicial dos contadores pode usar `Rails.cache`, reaproveitando o padrão já existente no projeto para guardas de abuso.

### Auth throttle scope
- `POST /auth/signup`, `POST /auth/login`, `POST /auth/refresh`, `POST /admin/auth/login` e `POST /admin/auth/refresh` devem receber throttles explícitos.
- Login e refresh de admin e user terão regras separadas, para permitir tuning por risco.
- Chaves de throttle devem combinar IP e identificador disponível quando fizer sentido seguro, mas sem depender de payload completo ou credencial válida.

### Sensitive operational endpoints
- Endpoints write/high-cost autenticados devem ganhar throttles adicionais por ator autenticado, com fallback por IP quando não houver identidade resolvida.
- Escopo inicial inclui `POST /cart/checkout`, mutações de `cart/items` e ações admin sensíveis (`balance-adjustments`, `approve`, `deny`, `soft_delete`, `deactivate`).
- Leitura pública e healthcheck ficam fora do throttle desta fase.

### 429 contract
- Resposta de throttle deve ser uniforme e minimalista.
- O contrato deve usar HTTP 429 com corpo genérico, sem informar se o problema foi credencial incorreta, recurso sensível ou limite específico.
- O middleware deve registrar telemetria/log mínimo com chave, tipo de throttle e request metadata segura.

### Safety boundaries
- `/up` nunca pode ser bloqueado pelo rate limiting.
- O domínio Railway e requests normais do deploy/healthcheck precisam continuar funcionais.
- A fase não exige armazenamento distribuído entre instâncias; isso fica para futuro.

### Claude's Discretion
- Valores exatos dos thresholds, desde que sejam defensáveis e diferenciados por risco.
- Organização do initializer/middleware e helpers de classificação de request.
- Se os testes de throttle ficam agrupados em uma suíte nova ou estendidos nas suítes de auth/admin existentes.

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `marketplace_backend/app/services/carts/inactive_cart_abuse_guard.rb` já usa `Rails.cache.increment` com janela temporal, mostrando um padrão local viável para contadores de abuso.
- `marketplace_backend/app/controllers/application_controller.rb` e `marketplace_backend/app/controllers/admin/application_controller.rb` já separam auth de user e admin, o que ajuda a classificar rotas críticas.
- `marketplace_backend/config/routes.rb` concentra todas as rotas sensíveis do domínio atual e torna o escopo da fase fechado.
- A suíte existente já cobre auth user/admin, cart e ações admin sensíveis em integração.

### Established Patterns
- O projeto prefere contratos de erro genéricos para não vazar estado interno.
- Segurança e autorização são validadas por testes de integração request-level e services dedicados quando há lógica de domínio.
- Hardening incremental: primeiro boundary mínimo confiável, depois observabilidade/distribuição em milestones futuros.

### Integration Points
- `marketplace_backend/Gemfile`: adicionar dependência de throttling em Rack, se necessário.
- `marketplace_backend/config/application.rb` ou initializer dedicado: inserir middleware e configurar resposta 429/logging.
- `marketplace_backend/test/integration/*auth*_test.rb`, `cart_checkout_test.rb`, `cart_items_*`, `admin_*`: cobertura de throttle sem quebrar contratos existentes.

</code_context>

<specifics>
## Specific Ideas

- Usar um initializer `rack_attack.rb` com helpers para classificar grupos de rota por risco.
- Separar throttles de auth pública dos throttles de operações autenticadas, para evitar um único bucket excessivamente agressivo.
- Reaproveitar testes de auth/admin/cart existentes para provar tanto o caminho permitido quanto o bloqueado.

</specifics>

<deferred>
## Deferred Ideas

- Redis/shared cache dedicado para rate limiting distribuído.
- Allowlist/blocklist operacional gerenciada por admin.
- Telemetria avançada e alertas automáticos baseados em thresholds agregados.
- CAPTCHA ou proof-of-work no frontend.

</deferred>

---

*Phase: 28-rack-abuse-boundary*
*Context gathered: 2026-03-11*
