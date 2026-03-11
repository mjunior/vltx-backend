---
phase: 26-admin-metrics-dashboard
plan: 01
subsystem: admin-dashboard
tags: [rails, admin, dashboard, metrics, backoffice]
requires:
  - phase: 24-global-moderation-surface
    provides: superfície admin-only para leitura global
provides:
  - endpoint `/admin/dashboard`
  - agregação fixa dos últimos 30 dias
  - métricas consolidadas de usuários, pedidos e volume bruto
affects: [admin, orders, users, analytics]
tech-stack:
  added: []
  patterns: [fixed-window-dashboard, status-map-with-zeroes, admin-only-metrics-read]
key-files:
  created:
    - marketplace_backend/app/controllers/admin/dashboard_controller.rb
    - marketplace_backend/app/services/admin_dashboard/read_summary.rb
    - marketplace_backend/test/integration/admin_dashboard_test.rb
  modified:
    - marketplace_backend/config/routes.rb
    - marketplace_backend/test/integration/admin_authorization_boundary_test.rb
    - marketplace_backend/test/integration/healthcheck_test.rb
key-decisions:
  - "Dashboard usa janela hardcoded de 30 dias, sem parâmetros do frontend."
  - "Volume financeiro é bruto por soma de `subtotal_cents` dos pedidos criados no período."
  - "`orders_by_status` sempre inclui todos os status do domínio, mesmo com zero."
requirements-completed:
  - ADM-08
completed: 2026-03-11
---

# Phase 26 Plan 01: Admin Dashboard Summary

**O backoffice agora tem um dashboard consolidado com métricas fixas dos últimos 30 dias.**

## Accomplishments
- Criado `GET /admin/dashboard`.
- O payload retorna `total_users`, `active_users`, `total_orders`, `orders_by_status` e `gross_volume_cents`.
- A janela é fixa em 30 dias e o endpoint permanece restrito ao guard admin-only.

## Verification
- `RBENV_VERSION=3.3.0 rbenv exec bundle exec rails test test/integration/admin_dashboard_test.rb test/integration/admin_authorization_boundary_test.rb test/integration/healthcheck_test.rb`

---
*Phase: 26-admin-metrics-dashboard*
*Completed: 2026-03-11*
