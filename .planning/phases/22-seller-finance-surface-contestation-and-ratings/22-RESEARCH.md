---
phase: 22
slug: seller-finance-surface-contestation-and-ratings
status: completed
created: 2026-03-10
updated: 2026-03-10
---

# Phase 22 Research

## Objective

Plan the last milestone phase that exposes seller financial data safely, adds buyer contestation after delivery, and persists ratings in separate product and seller tables derived from delivered purchases.

## Current Code Snapshot

- `SellerReceivable` already exists with `pending`, `reversed`, and `credited`.
- `Orders::MarkDelivered` already credits the seller wallet and flips the receivable to `credited`.
- `OrdersController` already exposes buyer/seller order actions and serializes order items plus transition history.
- There is still no seller finance HTTP surface.
- `Order` already supports `contested`, but there is no buyer action or service for it.
- There is no rating model, serializer, service, or endpoint.

## Seller Finance Surface Implications

The seller finance panel must now answer two distinct questions:

1. what is still pending to receive
2. what has already been financially realized on seller-owned orders

The existing `SellerReceivables::ReadSummary` solves only the first half, and only at the service layer.

Recommended shape:
- keep `SellerReceivables::ReadSummary` as the pending-source query
- add a second seller-finance read service that merges:
  - pending receivables from `seller_receivables`
  - credited wallet transactions for seller-owned orders
- expose a seller-only HTTP surface, preferably explicit and not coupled to generic `/wallet`

Suggested endpoint:
- `GET /seller/finance`

Suggested response sections:
- `pending_total_cents`
- `pending_receivables`
- `credited_total_cents`
- `transaction_history`

This satisfies `PAY-05` without exposing cross-tenant buyer data.

## Contestation Model

Business rule from roadmap:
- buyer can contest only after `delivered`

Recommended implementation:
- add `Orders::Contest` service
- add `POST /orders/:id/contest`
- use existing workflow substrate from phase 21
- transition `delivered -> contested`

Important scope note:
- this phase should not automatically claw back seller wallet credit
- contestation is a post-delivery operational state, not an automatic financial reversal in the current milestone

That keeps phase 22 aligned with the phase-20 decision that automatic refund stops once seller credit becomes real.

## Ratings Model

Locked product direction:
- ratings must be stored separately by product and by seller
- buyer is only eligible after delivered purchase

Recommended persistence model:
- `product_ratings`
- `seller_ratings`

Each should carry:
- `order_id`
- `order_item_id`
- `buyer_id`
- `product_id` or `seller_id`
- `score` (1..5)
- `comment`

Recommended uniqueness:
- one rating pair per `order_item_id`
- product rating unique on `order_item_id`
- seller rating unique on `order_item_id`

Recommended write flow:
- single service takes `order_item_id`, authenticated buyer, `score`, and `comment`
- service verifies:
  - order item belongs to an order owned by buyer
  - order is `delivered`
  - no prior rating exists for that order item
- service writes both `ProductRating` and `SellerRating` in one transaction

This keeps averages simple later and avoids drift between product and seller review datasets.

## API Surface Recommendation

Suggested routes:
- `GET /seller/finance`
- `POST /orders/:id/contest`
- `POST /orders/:order_id/items/:id/rating`

Important contract rules:
- no seller finance filtering by arbitrary seller id from payload/query
- no contest endpoint for seller
- no rating endpoint that accepts buyer/seller/product identity from payload
- all ownership derived from authenticated user and server-side joins

## Verification Priorities

Critical tests:
- seller finance endpoint only returns current seller data
- pending and credited totals align with receivables + wallet history
- buyer cannot contest before `delivered`
- intruder cannot contest foreign order
- buyer can rate delivered item exactly once
- rating write creates both product and seller records atomically
- buyer cannot rate undelivered or canceled order item

## Planning Implications

- Plan 22-01 should expose seller finance surface on top of existing receivable and wallet data.
- Plan 22-02 should add contestation through the phase-21 workflow boundary.
- Plan 22-03 should add separate rating tables and the single transactional rating service/endpoints.

---
*Phase: 22-seller-finance-surface-contestation-and-ratings*
*Research completed: 2026-03-10*
