Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  get "public/products" => "public/products#index"
  get "public/products/:id" => "public/products#show"
  post "cart" => "carts#create"
  patch "profile" => "profiles#update"
  get "products" => "products#index"
  post "products" => "products#create"
  patch "products/:id" => "products#update"
  patch "products/:id/deactivate" => "products#deactivate"
  delete "products/:id" => "products#destroy"
  post "auth/signup" => "auth/signups#create"
  post "auth/login" => "auth/logins#create"
  post "auth/refresh" => "auth/refreshes#create"
  post "auth/logout" => "auth/logouts#create"
end
