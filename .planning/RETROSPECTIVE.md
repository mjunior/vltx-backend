# Retrospective

## Milestone: v1.0 — Milestone

**Shipped:** 2026-03-06
**Phases:** 5 | **Plans:** 12 | **Tasks:** 36

### What Was Built
- Base de identidade `User` + `Profile` com credenciais seguras.
- Núcleo JWT com segredos separados e `jti` obrigatório.
- Endpoints de signup/login/refresh/logout com contratos consistentes.
- Rotação one-time de refresh e resposta defensiva a reuse incidente.
- Hardening final com matriz de testes de segurança ampliada.

### What Worked
- Planejamento por fases com objetivos de segurança claros.
- Cobertura de integração e serviço focada em invariantes de sessão.
- Uso de mensagens públicas genéricas para reduzir enumeração/vazamento.

### What Was Inefficient
- Artefatos de validação Nyquist ficaram em draft em todas as fases.
- Algumas atualizações de `STATE.md` exigiram ajuste manual por incompatibilidade de parser.

### Patterns Established
- Fail-closed por padrão para payload/token inválido.
- Revoke global como resposta padrão para reuse incidente.
- Contrato de erro público fixo (`cadastro invalido`, `credenciais invalidas`, `token invalido`, `payload invalido`).

### Key Lessons
- O fluxo de refresh rotativo precisa ser tratado como domínio transacional crítico.
- Logging de incidente deve ser best effort para não degradar disponibilidade.
- Verificação final por milestone evita regressão silenciosa entre fases.

### Cost Observations
- Commits no repositório: 49
- Janela de execução: 2026-03-05 -> 2026-03-06
- Notable: foco em testes antecipados reduziu retrabalho no hardening final.

## Milestone: v1.2 — Cart and Checkout Foundation

**Shipped:** 2026-03-07
**Phases:** 4 | **Plans:** 9 | **Tasks:** 27

### What Was Built
- Carrinho ativo único por usuário com isolamento tenant e contratos autenticados.
- Operações de item com validação server-side de quantidade/preço, transação e bloqueio de produto próprio.
- Guardas de estado para carrinhos inativos com resposta consistente e proteção anti-abuso.
- Checkout com `wallet` only e transição segura para `finished`.
- Service `Orders::PrepareFromCart` integrado, sem persistir pedido nesta etapa.

### What Worked
- Sequenciamento por waves reduziu retrabalho entre domínio, controller e testes.
- Contrato de erro genérico (`payload invalido` / `nao encontrado`) ficou consistente em todos os fluxos negativos.
- Cobertura de integração + serviço por fase acelerou fechamento de requisitos com confiança.

### What Was Inefficient
- `STATE.md` e `ROADMAP.md` ficaram desalinhados em alguns checkpoints e exigiram correção manual no fechamento.
- Comando de milestone não capturou automaticamente accomplishments/tasks de v1.2.

### Patterns Established
- Finalização de carrinho deve ser transacional e lockada para prevenir concorrência futura de criação de pedido.
- Anti-abuso reutiliza revogação de sessão já existente no domínio auth.
- Serializer de cart item inclui payload de produto público para reduzir round-trips no FE.

### Key Lessons
- Ordem incremental (cart -> checkout -> order-prep) permitiu evoluir domínio sem pular invariantes.
- Verificação formal por fase (`*-VERIFICATION.md`) evita dívida de rastreabilidade na virada do milestone.
- Contratos públicos estáveis ajudam FE a evoluir sem regressão por quebra de shape.

### Cost Observations
- Commits no repositório (v1.2): 17
- Janela de execução: 2026-03-07 -> 2026-03-07
- Notable: foco em regras de domínio + testes request-level reduziu bugs de integração.

## Cross-Milestone Trends

- v1.0 estabeleceu baseline forte de segurança de sessão.
- v1.2 consolidou maturidade de contratos multi-tenant no domínio de carrinho/checkout.
- Próximo ciclo deve priorizar engine de pedidos e ledger de carteira com idempotência.
