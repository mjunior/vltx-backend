# STACK

## Runtime and Language
- Primary language: Ruby (`3.3.0`) via `.ruby-version`.
- Framework: Rails API mode (`~> 8.0.4`).
- Rack app entrypoint: `marketplace_backend/config.ru`.
- Main app configuration: `marketplace_backend/config/application.rb`.

## Core Framework Components Enabled
- `active_model/railtie`
- `active_job/railtie`
- `active_record/railtie`
- `action_controller/railtie`
- `action_view/railtie`
- `rails/test_unit/railtie`

## Database and Persistence
- Adapter: PostgreSQL via `pg` gem.
- Database config: `marketplace_backend/config/database.yml`.
- Databases by environment:
- `marketplace_backend_development`
- `marketplace_backend_test`
- `marketplace_backend_production` (plus `*_cache`, `*_queue`, `*_cable`).

## Server and Infra Tooling
- App server: Puma (`gem "puma"`).
- Containerization: `marketplace_backend/Dockerfile`.
- Deploy tooling: Kamal (`gem "kamal"`, `marketplace_backend/config/deploy.yml`).
- HTTP acceleration option: Thruster (`gem "thruster"`).

## Developer Tooling
- Lint/style: `rubocop-rails-omakase`.
- Security scanning: `brakeman`, `bundler-audit`.
- Debugging: `debug` gem.
- Test framework: Minitest (`gem "minitest", "~> 5.25"`).

## API Surface (Current)
- Single app route in `marketplace_backend/config/routes.rb`:
- `GET /up` -> `rails/health#show`.

## Notes
- App is API-only (`config.api_only = true`).
- No business models/controllers/resources yet.
