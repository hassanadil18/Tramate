Rails.application.routes.draw do
  # Root route - redirects to login if not authenticated, dashboard if authenticated
  root to: "home#index"

  # Authentication routes
  get '/login', to: 'auth#login_form', as: 'auth_login_form'
  post '/login', to: 'auth#login', as: 'auth_login'
  get '/register', to: 'auth#register_form', as: 'auth_register_form'
  post '/register', to: 'auth#register', as: 'auth_register'
  get '/logout', to: 'auth#logout', as: 'auth_logout'

  # User dashboard
  get '/dashboard', to: 'dashboard#index', as: 'dashboard'

  # User resources
  resources :trades, only: [:index, :show]
  resources :channels, only: [:index, :show, :create, :destroy]
  resources :api_credentials
  resources :subscriptions, only: [:index, :show] do
    post 'select', on: :member
    get 'payment', on: :member
    post 'process_payment', on: :member
    get 'success', on: :member
  end
  resources :payments, only: [:index, :show]
  
  # Admin namespace
  namespace :admin do
    # Admin dashboard
    get '/', to: 'dashboard#index', as: :root
    get '/dashboard', to: 'dashboard#index', as: ''
    get '/logs', to: 'dashboard#logs', as: 'logs'
    get '/logs/:id', to: 'dashboard#show_log', as: 'log'

    # Admin resources
    resources :users
    resources :trades
    resources :channels
    resources :subscriptions
    resources :payments
  end

  # API endpoints for registration process
  post "auth/verify_discord_username" => "auth#verify_discord_username"
  get "auth/get_channels" => "auth#get_channels"
  post "auth/update_connection_info" => "auth#update_connection_info"

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
    
    get "subscription" => "registration#subscription", as: :subscription
    post "subscription" => "registration#submit_subscription"
  end
end
