# FE Admin Auth Integration

Este arquivo descreve o contrato atual de autenticação do painel admin.

## Regras Globais

- Base privada admin: usar header `Authorization: Bearer <admin_access_token>`.
- O auth admin e o auth de usuário comum são separados.
- Token de `User` nao funciona em `/admin/*`.
- Token de `Admin` nao deve ser reutilizado nas rotas normais do app.
- Erros públicos do fluxo admin:
  - `401` `{"error":"token invalido"}`
  - `401` `{"error":"credenciais invalidas"}`
  - `422` `{"error":"payload invalido"}`

## Modelo de Sessão

- `access_token`: validade de `15 minutos`
- `refresh_token`: validade de `7 dias`
- `token_type`: sempre `"Bearer"`
- Refresh é rotativo:
  - ao chamar `/admin/auth/refresh`, o frontend deve substituir o par antigo inteiro
  - nao reutilizar refresh token antigo depois de rotacionar

## 1. Login Admin

### `POST /admin/auth/login`

Caso de uso: autenticar operador interno.

Payload:

```json
{
  "email": "admin@example.com",
  "password": "password123"
}
```

Resposta de sucesso:

```json
{
  "data": {
    "id": 1,
    "email": "admin@example.com",
    "access_token": "<jwt>",
    "refresh_token": "<jwt>",
    "token_type": "Bearer",
    "access_expires_in": 900,
    "refresh_expires_in": 604800
  }
}
```

Regras para frontend:

- Nao existe signup público de admin.
- Admin inativo retorna o mesmo erro de credencial inválida.
- Se faltar `email` ou `password`, o backend retorna `422 payload invalido`.

Erros esperados:

```json
{
  "error": "credenciais invalidas"
}
```

```json
{
  "error": "payload invalido"
}
```

## 2. Refresh Admin

### `POST /admin/auth/refresh`

Caso de uso: renovar sessão admin sem pedir login novamente.

Payload:

```json
{
  "refresh_token": "<jwt>"
}
```

Resposta de sucesso:

```json
{
  "data": {
    "id": 1,
    "email": "admin@example.com",
    "access_token": "<new-jwt>",
    "refresh_token": "<new-jwt>",
    "token_type": "Bearer",
    "access_expires_in": 900,
    "refresh_expires_in": 604800
  }
}
```

Regras para frontend:

- Sempre substituir `access_token` e `refresh_token` ao receber sucesso.
- Se o refresh falhar com `401 token invalido`, derrubar a sessão admin local e voltar para login.
- Refresh token do auth comum (`/auth/*`) nao funciona aqui.

Erro esperado:

```json
{
  "error": "token invalido"
}
```

## 3. Logout Admin

### `POST /admin/auth/logout`

Caso de uso: encerrar a sessão admin.

Headers:

```http
Authorization: Bearer <admin_access_token>
Content-Type: application/json
```

Payload:

```json
{}
```

Resposta de sucesso:

- Status `204 No Content`

Regras para frontend:

- Ao receber `204`, apagar tokens locais imediatamente.
- O backend revoga as sessões refresh admin do operador.
- Se mandar token de usuário comum, recebe `401 token invalido`.

## 4. Fluxo Recomendado no Frontend

1. Fazer login em `/admin/auth/login`.
2. Salvar `access_token`, `refresh_token`, `access_expires_in` e `refresh_expires_in`.
3. Usar `access_token` em todas as rotas `/admin/*`.
4. Ao receber `401 token invalido` numa rota admin:
   - tentar uma vez `POST /admin/auth/refresh`
   - se refresh funcionar, repetir a request original
   - se refresh falhar, limpar sessão e redirecionar para login admin
5. No logout, chamar `/admin/auth/logout` e limpar storage local.

## 5. Diferenças para Auth de Usuário Comum

- Base path diferente: `/admin/auth/*`
- Entidade autenticada diferente: `Admin`
- JWT secrets diferentes dos usados em `/auth/*`
- Sessões refresh separadas das de `User`
- Tokens nao sao intercambiáveis entre os dois domínios

## 6. Endpoint Admin-Only Já Disponível

Estes endpoints nao são parte do login, mas já podem ser consumidos pelo frontend admin:

### `GET /admin/users`

Caso de uso: listar usuários no painel admin.

Headers:

```http
Authorization: Bearer <admin_access_token>
```

Resposta:

```json
{
  "data": {
    "users": [
      {
        "id": "<user_id>",
        "email": "user@example.com",
        "active": true,
        "verification_status": "unverified",
        "profile": {
          "id": "<profile_id>",
          "name": null,
          "address": null,
          "photo_url": null
        },
        "wallet": {
          "id": null,
          "current_balance_cents": 0
        },
        "created_at": "2026-03-10T06:00:00.000Z",
        "updated_at": "2026-03-10T06:00:00.000Z"
      }
    ]
  }
}
```

### `GET /admin/users/:id`

Caso de uso: abrir detalhe básico de um usuário no painel admin.

Headers:

```http
Authorization: Bearer <admin_access_token>
```

Resposta:

```json
{
  "data": {
    "id": "<user_id>",
    "email": "user@example.com",
    "active": true,
    "verification_status": "verified",
    "profile": {
      "id": "<profile_id>",
      "name": "Usuario Admin",
      "address": "Rua A, 1",
      "photo_url": "https://cdn.example.com/avatar.png"
    },
    "wallet": {
      "id": "<wallet_id>",
      "current_balance_cents": 5000
    },
    "created_at": "2026-03-10T06:00:00.000Z",
    "updated_at": "2026-03-10T06:10:00.000Z"
  }
}
```

### `PATCH /admin/users/:id`

Caso de uso: atualizar dados gerais do usuário pelo painel admin.

Headers:

```http
Authorization: Bearer <admin_access_token>
Content-Type: application/json
```

Payload permitido:

```json
{
  "email": "updated-user@example.com",
  "verification_status": "verified",
  "name": "Nome Atualizado",
  "address": "Rua B, 200",
  "photo_url": "https://cdn.example.com/avatar.png"
}
```

Regras:

- campos aceitos: `email`, `verification_status`, `name`, `address`, `photo_url`, `active`
- quando o usuário estiver inativo, esse endpoint só aceita `{ "active": true }`
- `active: false` também funciona e usa o mesmo bloqueio operacional da desativação
- payload vazio ou campos desconhecidos retornam `422 payload invalido`

Resposta de sucesso:

```json
{
  "data": {
    "id": "<user_id>",
    "email": "updated-user@example.com",
    "active": true,
    "verification_status": "verified",
    "profile": {
      "id": "<profile_id>",
      "name": "Nome Atualizado",
      "address": "Rua B, 200",
      "photo_url": "https://cdn.example.com/avatar.png"
    },
    "wallet": {
      "id": "<wallet_id>",
      "current_balance_cents": 5000
    }
  }
}
```

### `POST /admin/users/:id/balance-adjustments`

Caso de uso: aplicar crédito ou débito administrativo no saldo do usuário.

Headers:

```http
Authorization: Bearer <admin_access_token>
Content-Type: application/json
```

Payload:

```json
{
  "transaction_type": "credit",
  "amount_cents": 2500,
  "reason": "Ajuste manual"
}
```

Regras:

- `transaction_type`: `credit` ou `debit`
- `amount_cents`: inteiro positivo
- `reason`: string obrigatória
- débito nao pode deixar saldo negativo
- usuário inativo retorna `422 payload invalido`

Resposta de sucesso:

```json
{
  "data": {
    "user_id": "<user_id>",
    "current_balance_cents": 2500,
    "transaction": {
      "id": "<tx_id>",
      "transaction_type": "credit",
      "amount_cents": 2500,
      "balance_after_cents": 2500,
      "reference_type": "admin_adjustment",
      "reference_id": "<reference_id>",
      "metadata": {
        "source": "admin_adjustment",
        "reason": "Ajuste manual",
        "note": "admin:admin@example.com"
      },
      "created_at": "2026-03-10T23:00:00.000Z"
    }
  }
}
```

### `GET /admin/users/:id/verification-status`

Headers:

```http
Authorization: Bearer <admin_access_token>
```

Resposta:

```json
{
  "data": {
    "id": 123,
    "email": "user@example.com",
    "verification_status": "unverified"
  }
}
```

Valores possíveis de `verification_status`:

- `unverified`
- `verified`

Observação:

- Esse campo nao aparece no contrato atual de login do usuário comum.
- Para o frontend admin, prefira `GET /admin/users` e `GET /admin/users/:id` como fonte principal.

### `PATCH /admin/users/:id/deactivate`

Caso de uso: desativar usuário globalmente pelo painel admin.

Headers:

```http
Authorization: Bearer <admin_access_token>
Content-Type: application/json
```

Payload:

```json
{}
```

Resposta:

```json
{
  "data": {
    "id": "<user_id>",
    "active": false
  }
}
```

Comportamento esperado:

- o usuário perde acesso imediatamente
- refresh sessions do usuário são revogadas
- o usuário nao consegue mais logar

Erros:

- `401 {"error":"token invalido"}`
- `404 {"error":"nao encontrado"}`
- `422 {"error":"payload invalido"}`

### `PATCH /admin/products/:id/soft_delete`

Caso de uso: remover anúncio inapropriado globalmente.

Headers:

```http
Authorization: Bearer <admin_access_token>
Content-Type: application/json
```

Payload:

```json
{}
```

Resposta:

```json
{
  "data": {
    "id": "<product_id>",
    "deleted_at": "2026-03-10T06:00:00.000Z"
  }
}
```

Comportamento esperado:

- o produto sai imediatamente de `/public/products`
- o detalhe público `/public/products/:id` passa a responder `404`
- o seller ainda pode ver esse produto na listagem privada `/products`

Erros:

- `401 {"error":"token invalido"}`
- `404 {"error":"nao encontrado"}`
- `422 {"error":"payload invalido"}`

### `GET /admin/products`

Caso de uso: listar anúncios no painel admin.

Headers:

```http
Authorization: Bearer <admin_access_token>
```

Resposta:

```json
{
  "data": {
    "products": [
      {
        "id": "<product_id>",
        "title": "Produto A",
        "description": "Descricao do produto",
        "price": "20.00",
        "price_cents": 2000,
        "stock_quantity": 3,
        "active": true,
        "deleted_at": null,
        "seller_id": "<seller_id>",
        "created_at": "2026-03-10T23:00:00.000Z",
        "updated_at": "2026-03-10T23:00:00.000Z"
      }
    ]
  }
}
```

Comportamento esperado:

- inclui anúncios ativos e soft-deletados
- nao possui filtros nesta primeira versão

### `GET /admin/products/:id`

Caso de uso: abrir detalhe administrativo de um anúncio específico.

Headers:

```http
Authorization: Bearer <admin_access_token>
```

Resposta:

```json
{
  "data": {
    "id": "<product_id>",
    "title": "Produto A",
    "description": "Descricao do produto",
    "price": "20.00",
    "price_cents": 2000,
    "stock_quantity": 3,
    "active": true,
    "deleted_at": null,
    "seller_id": "<seller_id>"
  }
}
```

### `GET /admin/orders`

Caso de uso: listar todos os pedidos da plataforma no painel admin.

Headers:

```http
Authorization: Bearer <admin_access_token>
```

Payload:

- sem body
- sem filtros nesta primeira versão

Resposta:

```json
{
  "data": {
    "orders": [
      {
        "id": "<order_id>",
        "status": "paid",
        "actor_role": "admin",
        "available_actions": {
          "can_advance": false,
          "can_approve_contest": false,
          "can_cancel": false,
          "can_refund": false,
          "can_deliver": false,
          "can_contest": false,
          "can_rate": false
        }
      }
    ]
  }
}
```

Observações:

- retorna pedidos de todos os usuários
- inclui pedidos em qualquer status, inclusive `canceled`, `refunded` e `contested`
- nesta fase o endpoint é somente leitura

### `GET /admin/orders/:id`

Caso de uso: abrir detalhe global de qualquer pedido.

Headers:

```http
Authorization: Bearer <admin_access_token>
```

Resposta:

```json
{
  "data": {
    "id": "<order_id>",
    "buyer_id": "<buyer_id>",
    "seller_id": "<seller_id>",
    "status": "delivered",
    "actor_role": "admin",
    "items": [],
    "transitions": []
  }
}
```

Erros dos endpoints de pedido admin:

- `401 {"error":"token invalido"}`
- `404 {"error":"nao encontrado"}`
