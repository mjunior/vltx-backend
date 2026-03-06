# ARCHITECTURE

## High-Level Style
- Monolithic Rails API application with conventional Rails structure.
- Currently a "thin skeleton" architecture focused on runtime boot and health endpoint only.

## Main Application Layers
- Configuration layer:
- `marketplace_backend/config/application.rb`
- `marketplace_backend/config/environments/*.rb`
- Routing layer:
- `marketplace_backend/config/routes.rb`
- Controller layer:
- framework health controller (`rails/health#show`) used via route mapping
- Data layer:
- Active Record + PostgreSQL via `marketplace_backend/config/database.yml`
- Test layer:
- Minitest setup in `marketplace_backend/test/test_helper.rb`

## Request Flow
1. Rack boots via `marketplace_backend/config.ru`.
2. Rails app initializes using selected railties.
3. Request to `/up` is routed in `config/routes.rb`.
4. Rails built-in health controller returns liveness response.

## Boundaries and Responsibilities
- `ApplicationController` exists (`marketplace_backend/app/controllers/application_controller.rb`) for future shared API behavior.
- `ApplicationRecord` exists (`marketplace_backend/app/models/application_record.rb`) as base ORM abstraction.
- `ApplicationJob` exists (`marketplace_backend/app/jobs/application_job.rb`) as base async abstraction.

## Architectural Constraints Observed
- API-only middleware profile (`config.api_only = true`).
- Intentionally minimal public surface: only healthcheck route.
- No domain modules/services/policies introduced yet.

## Current Gaps
- No business domain architecture yet (entities, use-cases, services).
- No explicit error serialization strategy.
- No auth/authorization architecture.
- No observability architecture beyond Rails defaults.
