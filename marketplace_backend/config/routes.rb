Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  post "auth/signup" => "auth/signups#create"
  post "auth/login" => "auth/logins#create"
  post "auth/refresh" => "auth/refreshes#create"
  post "auth/logout" => "auth/logouts#create"
end
