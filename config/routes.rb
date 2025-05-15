Rails.application.routes.draw do
  # Landing page (public)
  root "home#index"

  # Authentication routes
  get "auth/login" => "auth#login"
  get "auth/register" => "auth#register"
  post "auth/register" => "auth#create"
  post "auth/authenticate" => "auth#authenticate"
  get "auth/logout" => "auth#logout"

  # Dashboard routes (protected)
  get "dashboard" => "dashboard#index"

  # API credentials routes
  resources :api_credentials

  # Channel routes
  resources :channels, only: [ :index, :show ]

  # Payments routes
  resources :payments

  # Trades routes
  resources :trades, only: [ :index, :show ]

  # Admin routes namespace
  namespace :admin do
    get "/" => "dashboard#index"
    resources :users
    resources :channels
    resources :payments
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
