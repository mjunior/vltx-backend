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

## Cross-Milestone Trends

- v1.0 estabeleceu baseline forte de segurança de sessão.
- Próximo ciclo deve priorizar maturidade de validação (Nyquist) e segurança de conta (MFA).
