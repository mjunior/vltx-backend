# Pitfalls Research

**Domain:** Marketplace orders with workflow and wallet settlement
**Researched:** 2026-03-09
**Confidence:** HIGH

## Critical Pitfalls

### Pitfall 1: Client-controlled status changes

**What goes wrong:** buyer ou seller envia estado arbitrário e pula etapas.
**Why it happens:** controller aceita `status` livre ou model permite update direto.
**How to avoid:** ações explícitas de transição, guarda por ator, workflow auditável.
**Warning signs:** endpoint genérico `PATCH /orders/:id` com `status` no payload.
**Phase to address:** Phase 21.

---

### Pitfall 2: Financial side effects without a stable business reference

**What goes wrong:** débito, refund e recebível ficam difíceis de reconciliar.
**Why it happens:** ledger continua preso a `cart_id` mesmo após existir pedido.
**How to avoid:** usar `order_id` como referência principal de negócio.
**Warning signs:** refund procura checkout pelo carrinho em vez do pedido.
**Phase to address:** Phase 20-21.

---

### Pitfall 3: Order creation without stock or idempotency guarantees

**What goes wrong:** pedido duplica, estoque fica negativo ou divergente.
**Why it happens:** criação do pedido, débito e baixa de estoque acontecem em passos independentes.
**How to avoid:** transação com locks e chaves idempotentes no fluxo de checkout.
**Warning signs:** retries de rede criam dois pedidos ou debitam duas vezes.
**Phase to address:** Phase 19.

---

### Pitfall 4: Ratings disconnected from delivered ownership

**What goes wrong:** usuário avalia sem comprar ou avalia várias vezes o mesmo item.
**Why it happens:** rating não valida elegibilidade contra pedido entregue.
**How to avoid:** unicidade por buyer + target + ordem elegível e validação pós-entrega.
**Warning signs:** endpoint aceita `product_id`/`seller_id` sem checar order item entregue.
**Phase to address:** Phase 22.

## Sources

- Padrões de segurança para workflow state machines
- Requisitos do milestone e arquitetura atual do app

---
*Pitfalls research for: secure marketplace orders*
*Researched: 2026-03-09*
