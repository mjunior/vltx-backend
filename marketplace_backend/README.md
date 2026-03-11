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

## Deploy

O deploy atual usa Railway com build por `Dockerfile`. O healthcheck público esperado é `GET /up`.
