---
phase: 21
slug: secure-order-workflow-and-cancellation-refunds
status: completed
created: 2026-03-10
updated: 2026-03-10
---

# Phase 21 Research

## Objective

Plan a secure order workflow that prevents forged status changes, allows actor-scoped actions, restores stock on eligible cancelation, issues idempotent buyer refunds, and releases seller wallet credit only when the buyer marks the order as delivered.

## Existing Code Snapshot

- `Order` already persists the business-visible `status` column with values `paid`, `in_separation`, `confirmed`, `delivered`, `contested`, `canceled`.
- Checkout already creates `Order`, `CheckoutGroup`, and `SellerReceivable` rows in one transaction.
- Buyer wallet debit is aggregated on `checkout_group`, but refund support in the wallet ledger is already append-only and deduplicated by `(wallet_id, reference_type, reference_id)` for `refund`.
- There is no order surface yet: no `OrdersController`, no order serializers, and no actor-scoped order actions.
- `SellerReceivable` currently supports `pending`, `reversed`, and `credited`, which matches the agreed product flow.

## Recommended Workflow Approach

### Primary Recommendation: `Statesman`

Use `Statesman` as the workflow engine for `Order`.

Why it fits this phase:
- It keeps transitions in a dedicated table, which is the strongest fit for `ORD-07` auditability.
- It models transitions through explicit transition methods instead of trusting raw `status` writes.
- It supports validation around allowed transitions and callback hooks for side effects.

Recommended implementation shape:
- Keep `orders.status` as a materialized current-state column for compatibility with existing code and query ergonomics.
- Add `order_transitions` as the audit source of truth.
- Wrap every status change in a domain service that:
  - authorizes the actor,
  - applies the transition through the state machine,
  - synchronizes `orders.status`,
  - performs side effects in the same transaction.

### Secondary Option: `state_machines-activerecord`

This is a valid fallback if gem integration friction with Rails 8 or UUID transitions becomes material during execution.

Tradeoff:
- Simpler DSL on the model.
- Weaker audit story out of the box than a dedicated transition log unless we add our own audit table anyway.

## Side-Effect Model Derived From Locked Decisions

### Seller Advance

Allowed seller path:
- `paid -> in_separation`
- `in_separation -> confirmed`

Not allowed:
- skipping steps,
- moving backwards,
- seller forcing `delivered`, `contested`, or `canceled`.

### Buyer Cancel

Allowed only while order is `paid`.

Side effects:
- restore stock from `order_items`,
- append buyer wallet `refund` linked to `order_id`,
- mark seller receivable `reversed`,
- transition order to `canceled`.

Idempotency expectation:
- repeated cancel attempts must not create duplicate refunds or double stock restoration.

### Buyer Deliver

Allowed only after order reaches `confirmed`.

Side effects:
- transition order to `delivered`,
- change seller receivable from `pending` to `credited`,
- append wallet `credit` to the seller linked to `order_id`.

This honors the previously locked business rule from phase 20: seller money becomes real only after buyer-confirmed delivery.

## API Surface Recommendation

Create an `OrdersController` with actor-safe endpoints instead of generic status update payloads.

Suggested endpoints:
- `GET /orders`
- `GET /orders/:id`
- `POST /orders/:id/advance`
- `POST /orders/:id/cancel`
- `POST /orders/:id/deliver`

Important contract rule:
- never accept raw `status` from the client,
- only accept intent-specific actions.

## Verification Priorities

Critical tests for this phase:
- invalid actor cannot operate on someone else's order,
- seller cannot skip transitions,
- buyer cannot cancel after `paid`,
- buyer cannot mark `delivered` before `confirmed`,
- cancel restores stock exactly once,
- cancel refunds exactly once,
- deliver credits seller exactly once,
- direct `order.update!(status: ...)` is either blocked or not used by any public/domain path.

## References

- Statesman (GitHub): https://github.com/gocardless/statesman
- Statesman (RubyGems): https://rubygems.org/gems/statesman
- state_machines-activerecord (GitHub): https://github.com/state-machines/state_machines-activerecord
- state_machines-activerecord (RubyGems): https://rubygems.org/gems/state_machines-activerecord
- AASM (GitHub): https://github.com/aasm/aasm

## Planning Implications

- Plan 21-01 should establish the workflow/audit substrate first.
- Plan 21-02 should add actor-safe actions and all financial/inventory side effects.
- Plan 21-03 should focus on idempotency, forged transitions, and regression coverage.

---
*Phase: 21-secure-order-workflow-and-cancellation-refunds*
*Research completed: 2026-03-10*
