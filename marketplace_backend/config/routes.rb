Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  post "auth/signup" => "auth/signups#create"
end
