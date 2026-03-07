# FE Profile and Product Integration Specs (v1.1)

## Objetivo

Especificar, para integração de frontend, os endpoints da milestone **v1.1** relacionados a:
- edição de perfil
- criação e gestão de produtos
- consumo público do catálogo

## Base

- API base local: `http://localhost:3000`
- Auth privada: header `Authorization: Bearer <access_token>`
- `Content-Type: application/json` nos endpoints com body JSON

## Pré-requisito de sessão (Auth)

### 1) Login

- **Quando usar:** antes de qualquer endpoint privado (`/profile`, `/products*`)
- **Endpoint:** `POST /auth/login`

Request:
```json
{
  "email": "seller@example.com",
  "password": "password123"
}
```

Response `200`:
```json
{
  "data": {
    "id": "uuid-user",
    "email": "seller@example.com",
    "profile_id": "uuid-profile",
    "access_token": "jwt-access",
    "refresh_token": "jwt-refresh",
    "token_type": "Bearer",
    "access_expires_in": 900,
    "refresh_expires_in": 604800
  }
}
```

### 2) Refresh de sessão

- **Quando usar:** quando o `access_token` expirar (401 `token invalido`) e você ainda tiver `refresh_token` válido
- **Endpoint:** `POST /auth/refresh`
- **Observação:** refresh token é **rotativo** (one-time use). Sempre substitua os dois tokens pelo novo par retornado.

Request:
```json
{
  "refresh_token": "jwt-refresh-atual"
}
```

Response `200`: mesmo contrato do login (novo par de tokens).

### 3) Logout

- **Quando usar:** logout explícito do usuário
- **Endpoint:** `POST /auth/logout`
- **Response:** `204 No Content`

---

## Perfil

### PATCH `/profile`

- **Quando usar:** usuário autenticado quer atualizar seu próprio perfil
- **Auth:** obrigatório
- **Payload permitido:** somente `name`, `address`
- **Semântica:** PATCH parcial
  - campo ausente: mantém valor atual
  - campo `null`: limpa valor

Request:
```json
{
  "name": "Maria Souza",
  "address": "Rua Exemplo, 100"
}
```

Response `200`:
```json
{
  "data": {
    "id": "uuid-profile",
    "name": "Maria Souza",
    "address": "Rua Exemplo, 100"
  }
}
```

Erros comuns:
- `401 {"error":"token invalido"}`
- `422 {"error":"payload invalido"}` (chaves inválidas, tipo inválido, body inválido)

---

## Produtos Privados (Seller)

## POST `/products`

- **Quando usar:** criar anúncio
- **Auth:** obrigatório
- **Payload:** obrigatório com root `product`
- **NUNCA enviar:** `owner_id`, `user_id` (será rejeitado)

Request:
```json
{
  "product": {
    "title": "Notebook Gamer",
    "description": "RTX 4060, 16GB RAM, SSD 1TB",
    "price": "7599.90",
    "stock_quantity": 5
  }
}
```

Response `201`:
```json
{
  "data": {
    "id": "uuid-product",
    "title": "Notebook Gamer",
    "description": "RTX 4060, 16GB RAM, SSD 1TB",
    "price": "7599.90",
    "stock_quantity": 5,
    "active": true
  }
}
```

Erros comuns:
- `401 {"error":"token invalido"}`
- `422 {"error":"payload invalido"}`

## PATCH `/products/:id`

- **Quando usar:** editar anúncio próprio
- **Auth:** obrigatório
- **Payload permitido:** `title`, `description`, `price`, `stock_quantity`, `active`
- **Regra:** `active: false` não é permitido aqui (usar rota de deactivate)

Request:
```json
{
  "product": {
    "price": "6999.00",
    "stock_quantity": 3,
    "active": true
  }
}
```

Response `200`:
```json
{
  "data": {
    "id": "uuid-product",
    "title": "Notebook Gamer",
    "description": "RTX 4060, 16GB RAM, SSD 1TB",
    "price": "6999.00",
    "stock_quantity": 3,
    "active": true
  }
}
```

Erros comuns:
- `404 {"error":"nao encontrado"}` (produto inexistente ou de outro usuário)
- `401 {"error":"token invalido"}`
- `422 {"error":"payload invalido"}`

## PATCH `/products/:id/deactivate`

- **Quando usar:** desativar anúncio próprio
- **Auth:** obrigatório
- **Body:** não necessário

Response `200`:
```json
{
  "data": {
    "id": "uuid-product",
    "title": "Notebook Gamer",
    "description": "RTX 4060, 16GB RAM, SSD 1TB",
    "price": "6999.00",
    "stock_quantity": 3,
    "active": false
  }
}
```

Erros comuns:
- `404 {"error":"nao encontrado"}`
- `401 {"error":"token invalido"}`

## DELETE `/products/:id`

- **Quando usar:** remover anúncio próprio (soft delete)
- **Auth:** obrigatório

Response:
- `204 No Content`

Erros comuns:
- `404 {"error":"nao encontrado"}`
- `401 {"error":"token invalido"}`

---

## Catálogo Público

### GET `/public/products`

- **Quando usar:** listar vitrine pública sem autenticação
- **Filtros opcionais:**
  - `q` (busca em `title`/`description`)
  - `min_price`
  - `max_price`
  - `sort` (`newest`, `price_asc`, `price_desc`)

Exemplo:
`GET /public/products?q=notebook&min_price=1000&max_price=8000&sort=price_desc`

Response `200`:
```json
{
  "data": [
    {
      "id": "uuid-product",
      "title": "Notebook Gamer",
      "description": "RTX 4060, 16GB RAM, SSD 1TB",
      "price": "6999.00",
      "stock_quantity": 3
    }
  ],
  "meta": {
    "total": 1
  }
}
```

Erros comuns:
- `422 {"error":"payload invalido"}` (filtro/sort inválido)

### GET `/public/products/:id`

- **Quando usar:** página de detalhe pública do anúncio
- **Sem auth**
- **Máscara de segurança:** inexistente/inativo/deletado/UUID inválido => `404` sem body

Response `200`:
```json
{
  "data": {
    "id": "uuid-product",
    "title": "Notebook Gamer",
    "description": "RTX 4060, 16GB RAM, SSD 1TB",
    "price": 6999.0,
    "stock_quantity": 3
  }
}
```

Response `404`:
- sem body

---

## Ciclo de Vida Recomendado (Frontend)

1. **Autenticar vendedor**
   - `POST /auth/login`
   - salvar `access_token` e `refresh_token`
2. **Atualizar perfil do usuário**
   - `PATCH /profile` com nome/endereço
3. **Criar anúncio**
   - `POST /products`
4. **Ajustar anúncio conforme operação do seller**
   - `PATCH /products/:id` para editar
   - `PATCH /products/:id/deactivate` para desativar
   - `DELETE /products/:id` para remoção lógica
5. **Consumir catálogo público (sem auth)**
   - `GET /public/products` para listagem/busca/filtros
   - `GET /public/products/:id` para detalhe
6. **Manter sessão ativa**
   - ao receber `401 token invalido` por expiração do access token: chamar `POST /auth/refresh`
   - substituir tokens no frontend pelo novo par
7. **Logout**
   - `POST /auth/logout` e limpar tokens locais

## Regras de Segurança de Integração (obrigatórias)

- Nunca enviar `owner_id`/`user_id` em payload de produto.
- Sempre usar `Authorization: Bearer <access_token>` nos endpoints privados.
- Em refresh, tratar token como one-time (rotativo): refresh antigo não deve ser reutilizado.
- Em `404` de endpoints de produto, considerar também cenário de recurso de outro usuário (máscara de multi-tenant).
