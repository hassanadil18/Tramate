Rails.application.routes.draw do
  # API credentials routes
  resources :api_credentials

  # Authentication routes
  get "auth/login" => "auth#login"
  get "auth/register" => "auth#register"
  post "auth/authenticate" => "auth#authenticate"
  get "auth/logout" => "auth#logout"

  # Dashboard routes
  get "dashboard" => "dashboard#index"

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

  # Set the root path to use dashboard controller
  root "layouts#application"
end
