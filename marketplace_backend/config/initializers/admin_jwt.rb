require Rails.root.join("app/services/admin_auth/jwt/config")

AdminAuth::Jwt::Config.load_from_env!
