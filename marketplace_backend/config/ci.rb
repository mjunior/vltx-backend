CI_STEPS = [
  ["Setup", "env RAILS_ENV=test DATABASE_URL=${DATABASE_URL:-postgresql://localhost/marketplace_backend_test} bin/setup --skip-server"],
  ["Security: Static gate", "bin/security"],
  ["Tests: Rails", "env RAILS_ENV=test DATABASE_URL=${DATABASE_URL:-postgresql://localhost/marketplace_backend_test} PARALLEL_WORKERS=1 bin/rails test"],
  ["Tests: Seeds", "env RAILS_ENV=test DATABASE_URL=${DATABASE_URL:-postgresql://localhost/marketplace_backend_test} bin/rails db:seed:replant"],
].freeze
