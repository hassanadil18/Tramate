Rails.application.routes.draw do
  # Landing page (public)
  root "home#index"

  # Authentication routes
  get "auth/login" => "auth#login"
  get "auth/register" => "auth#register"
  post "auth/authenticate" => "auth#authenticate"
  post "auth/create" => "auth#create"
  get "auth/logout" => "auth#logout"

  # API endpoints for registration process
  post "auth/verify_discord_username" => "auth#verify_discord_username"
  get "auth/get_channels" => "auth#get_channels"
  post "auth/update_connection_info" => "auth#update_connection_info"

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
    resources :trades, only: [ :index, :show ]
    get "logs" => "dashboard#logs"

    # Additional admin routes for user management
    post "users/:id/toggle_admin" => "users#toggle_admin", as: :toggle_admin
    patch "trades/:id/update" => "trades#update", as: :trade_update

    # Additional admin routes for channel management
    post "channels/:id/activate" => "channels#activate", as: :activate_channel
    post "channels/:id/deactivate" => "channels#deactivate", as: :deactivate_channel
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Multi-step user registration process
  namespace :registration do
    get "step1" => "registration#step1", as: :registration_step1
    post "step1" => "registration#submit_step1"

    get "step2" => "registration#step2", as: :registration_step2
    post "step2" => "registration#submit_step2"

    get "step3" => "registration#step3", as: :registration_step3
    post "step3" => "registration#submit_step3"

    get "step4" => "registration#step4", as: :registration_step4
    post "step4" => "registration#submit_step4"
  end
end
