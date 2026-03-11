require_relative "./production_security"

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins do |source, _env|
      ProductionSecurity.cors_origin_allowed?(source)
    rescue ProductionSecurity::ConfigurationError
      false
    end

    resource "*",
      headers: :any,
      expose: ["Authorization"],
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: false
  end
end
