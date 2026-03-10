# Frontend API Guide

Este arquivo descreve os endpoints atuais do backend por grupo funcional, com payloads esperados, resposta útil e intenção de uso. A ideia é servir quase como um prompt operacional para o frontend.

## Regras Globais

- Base auth privada: usar header `Authorization: Bearer <access_token>`.
- Todos os IDs são `uuid`.
- Endpoints privados nunca devem enviar `user_id`, `seller_id`, `buyer_id` ou `status` escolhidos pelo cliente, salvo quando o contrato explicitamente pedir.
- Fluxos de erro mais comuns:
  - `401` `{"error":"token invalido"}`
  - `404` `{"error":"nao encontrado"}`
  - `422` `{"error":"payload invalido"}`

## 1. Autenticação

### `POST /auth/signup`

Caso de uso: criar conta.

```json
{
  "email": "buyer@example.com",
  "password": "password123",
  "password_confirmation": "password123"
}
```

### `POST /auth/login`

Caso de uso: autenticar e abrir sessão.

```json
{
  "email": "buyer@example.com",
  "password": "password123"
}
```

Resposta útil:

```json
{
  "data": {
    "access_token": "<jwt>",
    "refresh_token": "<jwt>"
  }
}
```

### `POST /auth/refresh`

Caso de uso: renovar tokens.

```json
{
  "refresh_token": "<jwt>"
}
```

### `POST /auth/logout`

Caso de uso: encerrar sessão.

```json
{
  "refresh_token": "<jwt>"
}
```

## 2. Perfil

### `PATCH /profile`

Caso de uso: editar perfil do usuário autenticado.

```json
{
  "full_name": "Mauricio Silva",
  "address": "Rua Exemplo, 123",
  "photo_url": "https://cdn.exemplo.com/avatar.png"
}
```

## 3. Catálogo Público

### `GET /public/products`

Caso de uso: vitrine pública.

Query params suportados:
- `query`
- `min_price`
- `max_price`
- `sort`

### `GET /public/products/:id`

Caso de uso: detalhe público do produto.

## 4. Produtos do Seller

### `GET /products`

Caso de uso: listar produtos do seller autenticado.

### `POST /products`

Caso de uso: criar produto.

```json
{
  "title": "Camiseta básica",
  "description": "Algodão 100%, cor preta",
  "price": "59.90",
  "stock_quantity": 10
}
```

### `PATCH /products/:id`

Caso de uso: editar produto próprio.

```json
{
  "title": "Camiseta básica premium",
  "price": "69.90",
  "stock_quantity": 8
}
```

### `PATCH /products/:id/deactivate`

Caso de uso: retirar produto de circulação sem apagar histórico.

### `DELETE /products/:id`

Caso de uso: soft-delete do produto próprio.

## 5. Carrinho

### `POST /cart`

Caso de uso: obter/criar carrinho ativo do usuário.

Payload: vazio.

### `POST /cart/items`

Caso de uso: adicionar item.

```json
{
  "product_id": "<uuid>",
  "quantity": 2
}
```

### `PATCH /cart/items/:id`

Caso de uso: alterar quantidade.

```json
{
  "quantity": 3
}
```

### `DELETE /cart/items/:id`

Caso de uso: remover item.

### `POST /cart/checkout`

Caso de uso: finalizar compra do carrinho com carteira interna.

```json
{
  "payment_method": "wallet"
}
```

Resposta útil:

```json
{
  "data": {
    "order_ids": ["<uuid>", "<uuid>"],
    "checkout_group_id": "<uuid>",
    "summary": {
      "total_items": 3,
      "subtotal_cents": 12000
    }
  }
}
```

Regras de frontend:
- um checkout pode gerar múltiplos pedidos
- se qualquer item falhar por estoque, o checkout inteiro falha

## 6. Wallet

### `GET /wallet`

Caso de uso: mostrar saldo atual.

### `GET /wallet/transactions`

Caso de uso: extrato da carteira.

Detalhe:
- compras agregadas do checkout usam `reference_type = "checkout_group"`
- a resposta pode incluir `checkout_group_id`, `order_ids` e `orders_count`

## 7. Pedidos

### `GET /orders`

Caso de uso: listar pedidos do buyer ou seller logado.

### `GET /orders/:id`

Caso de uso: abrir detalhe do pedido.

### `POST /orders/:id/advance`

Caso de uso: seller avançar o fluxo.

Payload: vazio.

Fluxo esperado:
- `paid -> in_separation`
- `in_separation -> confirmed`

### `POST /orders/:id/cancel`

Caso de uso: buyer cancelar enquanto `paid`.

Payload: vazio.

Efeito de negócio:
- restitui estoque
- gera refund automático buyer-side

### `POST /orders/:id/deliver`

Caso de uso: buyer marcar como entregue.

Payload: vazio.

Efeito de negócio:
- crédito real entra na wallet do seller

### `POST /orders/:id/contest`

Caso de uso: buyer contestar compra após entrega.

Payload: vazio.

Regras:
- só buyer
- só depois de `delivered`
- não existe refund automático neste endpoint

## 8. Financeiro do Seller

### `GET /seller/finance`

Caso de uso: dashboard financeiro seller.

Payload: vazio.

Resposta esperada:

```json
{
  "data": {
    "seller_id": "<uuid>",
    "pending_total_cents": 3000,
    "pending_total": "30.00",
    "credited_total_cents": 9000,
    "credited_total": "90.00",
    "pending_receivables": [
      {
        "order_id": "<uuid>",
        "buyer_id": "<uuid>",
        "amount_cents": 3000,
        "amount": "30.00",
        "status": "pending",
        "order_status": "paid"
      }
    ],
    "transaction_history": [
      {
        "order_id": "<uuid>",
        "amount_cents": 9000,
        "amount": "90.00",
        "transaction_type": "credit",
        "order_status": "delivered"
      }
    ]
  }
}
```

## 9. Avaliações

### `POST /orders/:order_id/items/:id/rating`

Caso de uso: buyer avaliar item comprado.

```json
{
  "rating": {
    "score": 5,
    "comment": "Produto excelente, entrega rápida"
  }
}
```

Resposta útil:

```json
{
  "data": {
    "product_rating_id": "<uuid>",
    "seller_rating_id": "<uuid>"
  }
}
```

Regras:
- endpoint é por `order_item`
- só pode avaliar item elegível após entrega
- um item só pode ser avaliado uma vez

## 10. Sugestão de Fluxos de Tela

### Comprador

- login
- catálogo público
- detalhe do produto
- adicionar ao carrinho
- revisar carrinho
- checkout com wallet
- lista de pedidos
- detalhe do pedido
- marcar como entregue
- contestar
- avaliar item

### Seller

- login
- gerir produtos
- ver pedidos recebidos
- avançar pedidos
- acompanhar `GET /seller/finance`

## 11. Cuidados de Integração

- Não construir frontend assumindo update genérico de `status`.
- Não assumir um único pedido por checkout.
- Não assumir refund instantâneo em contestação.
- Não enviar IDs sensíveis no payload quando o backend já deriva isso do token ou do path.
- Sempre tratar `404` privado como possível falta de ownership.
