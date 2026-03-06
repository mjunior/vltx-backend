# TESTING

## Testing Stack
- Framework: Minitest (pinned to `~> 5.25`).
- Rails integration: `rails/test_unit/railtie` enabled.
- Test boot file: `marketplace_backend/test/test_helper.rb`.

## Test Execution
- Primary command:
- `bundle exec rails test`
- Parallelization configured by default:
- `parallelize(workers: :number_of_processors)` in `test_helper.rb`.

## Current Test Coverage Scope
- Healthcheck integration coverage exists in:
- `marketplace_backend/test/integration/healthcheck_test.rb`

## Implemented Scenarios
- `GET /up` returns success.
- Route map effectively exposes only app-level healthcheck endpoint (`/up`) when filtering framework-internal routes.

## Fixtures and Data Strategy
- `fixtures :all` is enabled in base `ActiveSupport::TestCase`.
- No domain fixtures currently because there are no domain models yet.

## Quality/CI Tooling Present
- `bin/ci` scaffold exists.
- Security and lint tools available for CI hardening:
- `bin/brakeman`
- `bin/bundler-audit`
- `bin/rubocop`

## Testing Gaps
- No request specs beyond healthcheck.
- No model/job/controller domain tests yet.
- No contract testing for external integrations (none implemented yet).

## Recommended Next Testing Steps
- Add request tests with JSON schema assertions when first business endpoint is added.
- Add failure-path tests for validation and error formatting once API error contract is defined.
