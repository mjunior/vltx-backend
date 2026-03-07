# Auth API Integration Guide (v1.0)

Este documento descreve as rotas de autenticação atualmente disponíveis no backend, com payloads de exemplo, respostas e quando usar cada endpoint.

## Base

- Base URL local: `http://localhost:3000`
- Content-Type recomendado: `application/json`
- CORS (dev): origem permitida `http://localhost:4200`
- Auth atual: header `Authorization: Bearer <access_token>` (sem cookie HttpOnly)
- Rotas públicas de auth:
  - `POST /auth/signup`
  - `POST /auth/login`
  - `POST /auth/refresh`
  - `POST /auth/logout`
- Healthcheck:
  - `GET /up`

## Contrato de Erros

O backend usa mensagens públicas fixas:

- `{"error":"cadastro invalido"}` com status `422`
- `{"error":"credenciais invalidas"}` com status `401`
- `{"error":"payload invalido"}` com status `422`
- `{"error":"token invalido"}` com status `401`

## 1) Signup

Cria `User + Profile` e já retorna o par de tokens.

### Quando usar

- Primeiro cadastro do usuário.

### Request

`POST /auth/signup`

```json
{
  "user": {
    "email": "user@example.com",
    "password": "password123",
    "password_confirmation": "password123"
  }
}
```

### Response de sucesso (`201`)

```json
{
  "data": {
    "id": 1,
    "email": "user@example.com",
    "profile_id": 1,
    "access_token": "<jwt>",
    "refresh_token": "<jwt>",
    "token_type": "Bearer",
    "access_expires_in": 900,
    "refresh_expires_in": 604800
  }
}
```

### Erros comuns

- `422 cadastro invalido` (email inválido, duplicado, confirmação divergente, payload fora do formato esperado)

## 2) Login

Autentica por email/senha e retorna novo par de tokens.

### Quando usar

- Início de sessão.
- Reautenticação após logout ou refresh inválido.

### Request

`POST /auth/login`

```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

### Response de sucesso (`200`)

Mesmo contrato do signup:

```json
{
  "data": {
    "id": 1,
    "email": "user@example.com",
    "profile_id": 1,
    "access_token": "<jwt>",
    "refresh_token": "<jwt>",
    "token_type": "Bearer",
    "access_expires_in": 900,
    "refresh_expires_in": 604800
  }
}
```

### Erros comuns

- `401 credenciais invalidas` (email/senha incorretos)
- `422 payload invalido` (faltou email ou password)

## 3) Refresh

Rota de rotação do refresh token (uso único). Emite novo access + novo refresh.

### Quando usar

- Quando o access token expirar (ou estiver perto de expirar).
- Em interceptador de `401` para requests autenticadas, uma única tentativa.

### Quando NAO usar

- Não chamar em paralelo (duas chamadas simultâneas com o mesmo refresh causam falha em pelo menos uma).
- Não reutilizar refresh token antigo (ele é inválido após uso).
- Não chamar se usuário já fez logout.
- Não insistir em loop se receber `401 token invalido`.

### Request

`POST /auth/refresh`

```json
{
  "refresh_token": "<refresh-jwt-atual>"
}
```

### Regras importantes de payload

- `Content-Type` deve ser JSON.
- Envie apenas `refresh_token` no body.

### Response de sucesso (`200`)

```json
{
  "data": {
    "id": 1,
    "email": "user@example.com",
    "profile_id": 1,
    "access_token": "<novo-access-jwt>",
    "refresh_token": "<novo-refresh-jwt>",
    "token_type": "Bearer",
    "access_expires_in": 900,
    "refresh_expires_in": 604800
  }
}
```

### Erros comuns

- `422 payload invalido` (body vazio, campos extras, content-type não JSON)
- `401 token invalido` (refresh expirado, malformado, revogado, reutilizado ou inconsistente)

### Comportamento de segurança crítico

Se houver detecção de reuse/replay de refresh revogado, o backend invalida sessões ativas do usuário (logout global defensivo).

## 4) Logout

Revoga as sessões ativas do usuário autenticado.

### Quando usar

- Logout explícito no frontend.
- Encerramento de sessão por ação do usuário.

### Request

`POST /auth/logout`

Headers:

```http
Authorization: Bearer <access-token>
Content-Type: application/json
```

Body:

```json
{}
```

### Response de sucesso

- `204 No Content`

### Erros comuns

- `401 token invalido` (token ausente/malformado/expirado/inválido)
- `422 payload invalido` (content-type não JSON)

## Fluxo recomendado no Frontend

1. Signup/Login: salvar `access_token` e `refresh_token`.
2. Requisições autenticadas: usar `Authorization: Bearer <access_token>`.
3. Se access expirar/`401`: tentar `POST /auth/refresh` uma vez.
4. Se refresh sucesso: atualizar os dois tokens e repetir request original.
5. Se refresh falhar com `401 token invalido`: limpar sessão local e redirecionar para login.
6. Logout: chamar `/auth/logout`; em qualquer caso limpar tokens locais.

## Healthcheck

`GET /up`

- Uso: monitoramento de disponibilidade da API.
- Sucesso: `200 OK`.
