# CONVENTIONS

## Framework Conventions
- Strong adherence to Rails defaults and naming patterns.
- API-only configuration in `marketplace_backend/config/application.rb`.
- Route definition uses Rails DSL with named route alias (`rails_health_check`).

## Code Organization Patterns
- Base classes retained for extension:
- `ApplicationController`
- `ApplicationRecord`
- `ApplicationJob`
- Minimal custom code; framework defaults are preferred over custom abstractions.

## Configuration Conventions
- Environment-specific behavior in:
- `marketplace_backend/config/environments/development.rb`
- `marketplace_backend/config/environments/test.rb`
- `marketplace_backend/config/environments/production.rb`
- Secrets managed through Rails encrypted credentials (`config/credentials.yml.enc`).

## Dependency Conventions
- Runtime gems grouped globally in `Gemfile`.
- Dev/test quality and debugging gems grouped under `group :development, :test`.
- Explicit Ruby version pin (`ruby "3.3.0"`).

## Routing and API Conventions
- Single endpoint pattern: health route only (`GET /up`).
- No versioned namespace yet (e.g., `/api/v1`) because domain APIs are not started.
- No serializer layer defined yet.

## Style and Quality Conventions
- RuboCop Omakase configured via `rubocop-rails-omakase`.
- Security scanners pre-wired (`brakeman`, `bundler-audit`).
- Test style uses Minitest integration tests.

## Error Handling Conventions (Current State)
- No centralized API error serializer yet.
- Current behavior relies on Rails defaults.
- Recommendation for future phases: define JSON error envelope before adding business endpoints.
