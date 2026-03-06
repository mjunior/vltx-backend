# Phase 1 Research: User and Profile Foundation

**Phase:** 1 — User and Profile Foundation
**Date:** 2026-03-05
**Source Inputs:** 01-CONTEXT.md, REQUIREMENTS.md, PROJECT.md, codebase scan

## Objective
Definir a melhor forma de implementar a fundação de `User` + `Profile` no Rails atual, com regras de entrada seguras para signup e separação clara entre credenciais e dados de perfil.

## Existing Code Constraints
- App Rails API-only em `marketplace_backend/`.
- `ApplicationRecord` disponível para novos modelos.
- `filter_parameter_logging` já cobre `passw`, `email`, `token` e `secret`.
- Não há modelos de domínio ainda.

## Recommended Design for Phase 1

### Data model
- `users`:
- `email` (not null)
- `password_digest` (not null, `has_secure_password`)
- timestamps
- `profiles`:
- `user_id` (FK unique + not null)
- `full_name` (nullable)
- `photo_url` (nullable)
- timestamps

### Associations
- `User has_one :profile, dependent: :destroy`
- `Profile belongs_to :user`

### Validation rules (phase scope)
- `User.email`:
- normalizar com `strip.downcase` antes de validação
- formato básico de email
- unicidade case-insensitive
- `User.password`:
- mínimo 8 caracteres
- exigir `password_confirmation` no cadastro
- `Profile`:
- sem obrigatoriedade de campos nesta fase

### Error policy from context
- Login: erro genérico de credenciais inválidas.
- Signup: erro genérico `cadastro inválido` para falhas sensíveis (incluindo email já existente).
- Detalhes técnicos apenas em logs internos.

## API and Service Implications for Later Phases
- Criar serviço de signup desde já (`Users::Create` ou `Auth::Signup`) para manter criação `User + Profile` atômica.
- Retorno estruturado de erro permite política genérica sem vazar informação.

## Test Strategy for this phase
- Model tests:
- normalização de email
- unicidade case-insensitive
- validação de senha mínima
- associação 1:1 user/profile
- Service tests:
- criação transacional de `User` e `Profile`
- falha na criação de profile deve abortar user

## Risks and Mitigations
- **Race em unicidade de email**
- Mitigar com índice único funcional/estratégia case-insensitive no banco.
- **Mensagens de erro vazando enumeração**
- Centralizar serialização de erro e fixar mensagem pública.
- **Dados de perfil acoplados à autenticação**
- Evitar campos de perfil na tabela `users`.

## Deliverables aligned to roadmap plans
- Plan `01-01`: migrations + models + validações essenciais.
- Plan `01-02`: serviço de criação segura + testes focados na fundação de signup.
