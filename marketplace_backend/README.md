# Marketplace Backend

Rails 8 API para o marketplace. O fluxo local e o fluxo automatizado do repositório usam os mesmos entrypoints em `marketplace_backend/bin`.

## Requisitos

- Ruby `3.3.0`
- PostgreSQL local
- Bundler compatível com o lockfile

## Setup local

```bash
cd marketplace_backend
bin/setup
```

## Comandos principais

```bash
cd marketplace_backend
bin/rails test
bin/security
bin/security-regression
bin/ci
bin/rubocop
```

`bin/security` é o gate estático fail-closed do projeto. Ele executa `bundler-audit` e `brakeman` com a mesma política usada em CI.
`bin/security-regression` executa a malha focada de hardening para throttling, CORS, posture de produção e healthcheck-safe behavior.
`bin/ci` executa setup, gate estático e suíte principal do projeto. `bin/rubocop` continua disponível separadamente para style/lint local.

## Admin no Railway

Para criar o primeiro admin no Railway, rode uma task no serviço web:

```bash
cd marketplace_backend
ADMIN_EMAIL=admin@example.com \
ADMIN_PASSWORD='troque-essa-senha' \
bin/rails admin:create
```

Comandos úteis:

- atualizar senha de um admin existente: `ADMIN_RESET_PASSWORD=true`
- forçar admin inativo/ativo: `ADMIN_ACTIVE=false` ou `ADMIN_ACTIVE=true`

## Deploy

O deploy atual usa Railway com build por `Dockerfile`. O healthcheck público esperado é `GET /up`.
