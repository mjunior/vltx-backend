# Marketplace Backend

## What This Is

API backend em Rails 8 para autenticação JWT segura, gestão de perfil do usuário, domínio de produtos, carrinho e carteira financeira em ledger append-only.

## Core Value

Isolamento multi-tenant estrito com contratos de autenticação e catálogo previsíveis.

## Requirements

### Validated

- ✓ Cadastro e login com email/senha — v1.0
- ✓ Access token (15 min) + refresh token (7 dias) com segredos distintos — v1.0
- ✓ Refresh token rotativo one-time com proteção contra replay — v1.0
- ✓ Logout global com revogação por `jti` — v1.0
- ✓ Relação `User has_one Profile` com separação de credenciais e perfil — v1.0
- ✓ Edição de perfil próprio (`PATCH /profile`) — v1.1
- ✓ CRUD privado de produtos com ownership derivado do token — v1.1
- ✓ Listagem pública com busca/faixa/sort (`GET /public/products`) — v1.1
- ✓ Detalhe público seguro (`GET /public/products/:id`) com serializer dedicado — v1.1
- ✓ Carrinho ativo único por usuário autenticado com isolamento tenant — v1.2
- ✓ Operações de item com validação server-side, transação e anti-fraude — v1.2
- ✓ Guardas de estado para carrinhos `finished`/`abandoned` com prevenção de abuso — v1.2
- ✓ Checkout com `wallet` only e transição segura para `finished` — v1.2
- ✓ Service de preparação de pedido sem persistência de `Order` (foundation) — v1.2
- ✓ Carteira em ledger append-only com `balance_after` e centavos inteiros — v1.3
- ✓ Movimentação segura com lock, não-negativação e anti-fraude server-side — v1.3
- ✓ Idempotência de operação e deduplicação de refund sob corrida/retry — v1.3
- ✓ Surface de wallet com isolamento tenant e authz por token (`GET /wallet`, `GET /wallet/transactions`) — v1.3
- ✓ Pedidos persistidos com split por seller, snapshot, estoque consistente e pagamento via wallet — v1.4
- ✓ Workflow seguro de pedido com transições auditáveis e ações explícitas por ator — v1.4
- ✓ Ledger buyer/seller rastreável com `checkout_group`, refund automático e painel financeiro do seller — v1.4
- ✓ Contestação pós-entrega e avaliações separadas por produto/vendedor vinculadas ao `order_item` — v1.4
- ✓ Entidade `Admin` com autenticação própria em `/admin`, JWT secret dedicado e fronteira de autorização separada — v1.5
- ✓ Usuário padrão não consegue escalar privilégios para admin por rotas, payloads ou mutações de `User` — v1.5
- ✓ Admin consegue moderar usuários, anúncios e pedidos globais com escopo operacional separado — v1.5
- ✓ Admin consegue atualizar dados de usuário, incluindo saldo, foto, e-mail e status de verificação por fluxo controlado — v1.5
- ✓ Dashboard admin entrega métricas agregadas e resolução de contestações com refund seguro ao comprador — v1.5
- ✓ Rate limiting em Rack para auth user/admin, refresh e endpoints sensíveis com boundary antes do controller — v1.6
- ✓ Contrato HTTP `429` consistente com proteção healthcheck-safe para abuso — v1.6
- ✓ Postura explícita de produção para SSL, host authorization e CORS por ambiente — v1.6
- ✓ Validação estática de segurança obrigatória em fluxo único local/CI — v1.6
- ✓ Regressão focada para throttling e guardrails críticos de segurança — v1.6

### Active

- [ ] Registrar throttle events e contadores em backend observável para alertas automáticos.
- [ ] Migrar rate limiting para storage distribuído resiliente entre múltiplas instâncias.
- [ ] Permitir gestão operacional de allowlists/blocklists sem deploy.
- [ ] Endurecer login administrativo com MFA/2FA.

### Out of Scope

- CAPTCHA e desafios anti-bot no frontend — exigem experiência de produto e orquestração com o app cliente, fora deste ciclo backend-first.
- WAF/CDN rules gerenciadas externamente — ficam para camada de infraestrutura, não para o milestone de aplicação.
- MFA/2FA admin — continua importante, mas não entra junto com hardening inicial de abuso para não misturar frentes.
- Detecção avançada de fraude por reputação/IP/device — adiada até existir telemetria suficiente e políticas operacionais claras.

## Current State

- **Shipped versions:** v1.0, v1.1, v1.2, v1.3, v1.4, v1.5, v1.6
- **Latest milestone shipped:** v1.6 Security and Abuse Hardening
- **Stack:** Rails API-only 8.0.4, Ruby 3.3.0, PostgreSQL, Redis, gem `jwt`
- **Functional scope now shipped:** auth JWT, perfil, catálogo, carrinho, checkout wallet-only, pedidos, wallet ledger, seller finance, contestação, avaliações, superfície admin segregada e hardening de abuso/produção/CI de segurança
- **Operational follow-ups:** smoke externo do Railway após hardening, observação do workflow remoto de CI e redução da dependência de full suite serial no host local

## Next Milestone Goals

- Telemetria operacional para throttles e abuso.
- Storage distribuído para rate limiting multi-instância.
- Endurecimento de autenticação administrativa com MFA/2FA.
- Ferramentas operacionais para allowlist/blocklist sem deploy.

## Constraints

- Toda autorização de recursos privados usa usuário derivado do token.
- Endpoints privados exigem autenticação.
- Endpoints públicos não expõem dados sensíveis.
- Operações de carteira nunca confiam em valores enviados pelo frontend.
- Ledger de carteira é append-only: sem `UPDATE`/`DELETE` em transações.
- Transições críticas de pedido devem ser autorizadas por ator e validadas server-side; cliente nunca escolhe estado arbitrário.
- Admin não pode ser derivado por flag mutável em `users`; a fronteira de identidade precisa ser separada do domínio de usuário padrão.
- Rotas administrativas devem viver em escopo `/admin`, mesmo quando reutilizarem services internos já existentes.
- Rate limits precisam respeitar tráfego legítimo entre buyer, seller, admin e healthchecks sem degradar disponibilidade básica.
- Guardrails de produção não podem quebrar o deploy no Railway nem assumir infraestrutura fora do app.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| JWT com `jti` e revogação por sessão | Controle explícito de sessão | ✓ Good (v1.0) |
| Refresh one-time rotativo com resposta a reuse | Mitigar replay de refresh token | ✓ Good (v1.0) |
| Ownership sempre derivado do token | Bloquear spoofing via frontend | ✓ Good (v1.1) |
| Catálogo público em `/public` com serializer dedicado | Evitar vazamento e estabilizar contrato | ✓ Good (v1.1) |
| Detalhe público com máscara uniforme de 404 | Reduzir enumeração de recursos | ✓ Good (v1.1) |
| Carrinho só aceita dados críticos validados no backend | Evitar fraude/abuso de payload manipulável | ✓ Good (v1.2) |
| Um carrinho ativo por usuário | Simplificar checkout e reduzir abuso por multiplicação de carrinhos | ✓ Good (v1.2) |
| Checkout `wallet` only com finalização atômica | Garantir caminho de pagamento mínimo seguro antes de persistir pedidos | ✓ Good (v1.2) |
| Preparação de pedido sem persistência nesta etapa | Permitir evolução incremental para ORD-01..03 | ✓ Good (v1.2) |
| Ledger de carteira append-only com lock por operação | Priorizar integridade financeira sobre simplicidade | ✓ Good (v1.3) |
| Extrato de wallet hardcoded em últimas 30 transações | Simplicidade e previsibilidade com superfície mínima inicial | ✓ Good (v1.3) |
| Débito buyer agregado por `checkout_group` com pedidos splitados por seller | Manter UX de uma compra única com rastreabilidade interna por pedido | ✓ Good (v1.4) |
| Fluxo de status do pedido via ações explícitas e trilha auditável | Evitar troca indevida de estado por payload manipulado ou corrida | ✓ Good (v1.4) |
| Crédito seller só em `delivered` | Reduzir risco de refund após liberação financeira | ✓ Good (v1.4) |
| Avaliações persistidas separadamente por produto e por vendedor | Simplificar cálculo futuro de médias agregadas sem ambiguidade | ✓ Good (v1.4) |
| Query de pedido deve nascer tenant-scoped, não apenas validar ownership após busca | Reduzir superfície de cross-access e endurecer isolamento | ✓ Good (v1.4) |
| Admin será uma entidade própria com autenticação segregada em `/admin` | Reduz risco de privilege escalation e separa políticas operacionais do usuário comum | ✓ Good (v1.5) |
| JWT admin terá secret dedicado | Limita blast radius entre sessões admin e user e permite políticas independentes de rotação/revogação | ✓ Good (v1.5) |
| Status de verificação do usuário nasce como fundação sem OTP acoplado neste milestone | Permite preparar banner/fluxo futuro sem travar o painel admin na entrega de e-mail | ✓ Good (v1.5) |
| Rate limiting será aplicado no Rack antes do controller | Bloqueia bursts cedo, reduz custo por request e centraliza política anti-abuso | ✓ Good (v1.6) |
| Security tooling continua fail-closed no fluxo padrão de CI | Evita regressão silenciosa ao depender de execução manual esporádica | ✓ Good (v1.6) |
| `/up` permanece fora do boundary de abuso e de partes críticas do hardening de produção | Preserva probes e healthchecks durante deploy e operação | ✓ Good (v1.6) |
| Regressões críticas de segurança devem existir em comando curto separado da suíte completa | Reduz chance de drift e facilita enforcement contínuo | ✓ Good (v1.6) |

<details>
<summary>Historical Milestone Context</summary>

### v1.6 Security and Abuse Hardening

- Boundary de throttling em Rack para auth, cart, checkout e mutações administrativas sensíveis
- Postura explícita de produção para SSL, hosts e CORS por ambiente
- Gate estático fail-closed com `bundler-audit` e `brakeman`
- Regressão explícita de hardening com `bin/security-regression`

### v1.5 Admin Panel

- Superfície administrativa segregada com entidade `Admin`, auth própria e JWT dedicado
- Moderação global de usuários, anúncios e pedidos
- Atualização administrativa de dados de usuário e status de verificação
- Dashboard admin e resolução operacional de contestações

</details>

---
*Last updated: 2026-03-11 after completing v1.6 Security and Abuse Hardening*
