# INTEGRATIONS

## External Services Overview
The current codebase is a minimal Rails API bootstrap and has very limited external integration points.

## Database Integration
- PostgreSQL is the only concrete external dependency currently used.
- Connection settings live in `marketplace_backend/config/database.yml`.
- Connection is expected via local socket by default in development/test.

## Deployment/Operations Integrations
- Kamal scaffolding exists:
- `marketplace_backend/config/deploy.yml`
- `marketplace_backend/.kamal/secrets`
- This indicates a planned deployment integration path, but no environment-specific deploy config has been customized yet.

## Queue/Cache/Cable Backends
- Gems present: `solid_queue`, `solid_cache`, `solid_cable`.
- Production DB blocks are present for queue/cache/cable in `marketplace_backend/config/database.yml`.
- No application jobs, queue usage, or cache strategy implemented yet.

## HTTP/API Integrations
- No outbound HTTP clients found (no Faraday/HTTParty/Net::HTTP wrappers in app code).
- No webhook controllers or signature verification code found.
- No auth provider integrations (OAuth/JWT/SAML) found.

## Messaging/Email Integrations
- Mailer base class exists (`marketplace_backend/app/mailers/application_mailer.rb`) from Rails scaffold.
- No SMTP provider configuration or mail delivery workflow implemented.

## Storage/CDN Integrations
- `image_processing` gem is present by default scaffold.
- Active Storage railtie is not enabled in app config, so storage integrations are currently inactive.

## Risk/Follow-up
- Integrations are mostly scaffold-level and not exercised.
- Future feature work should explicitly define:
- outbound service clients
- retry/error policies
- observability (timeouts, logs, metrics)
