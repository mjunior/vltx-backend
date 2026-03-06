require Rails.root.join("app/services/auth/jwt/config")

Auth::Jwt::Config.load_from_env!
