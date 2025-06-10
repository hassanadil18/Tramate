Rails.application.routes.draw do
  # Root route - redirects to login if not authenticated, dashboard if authenticated
  root to: "home#index"

  # Authentication routes
  get '/auth/login', to: 'auth#login_form', as: 'auth_login_form'
  post '/auth/login', to: 'auth#login', as: 'auth_login'
  get '/auth/register', to: 'auth#register_form', as: 'auth_register_form'
  post '/auth/register', to: 'auth#register', as: 'auth_register'
  get '/auth/logout', to: 'auth#logout', as: 'auth_logout'

  # Discord OAuth routes
  get '/auth/discord', to: 'discord_auth#authorize', as: 'discord_auth'
  get '/auth/discord/callback', to: 'discord_auth#callback', as: 'discord_callback'

  # User dashboard
  get '/dashboard', to: 'dashboard#index', as: 'dashboard'

  # User resources
  resources :trades, only: [:index, :show]
  resources :channels, only: [:index, :show, :create, :destroy] do
    member do
      get 'verify_discord'
      post 'complete_connection'
    end
  end
  resources :api_credentials do
    member do
      post 'validate'
    end
  end
  resources :subscriptions, only: [:index, :show, :new, :create] do
    post 'select', on: :member
    get 'payment', on: :member
    post 'process_payment', on: :member
    get 'success', on: :member
  end
  resources :payments, only: [:index, :show]
  
  # Admin namespace
  namespace :admin do
    # Admin notifications
    resources :notifications, only: [:index] do
      member do
        post :mark_as_read
      end
      collection do
        post :mark_all_as_read
        get :fetch
      end
    end
    
    # Admin dashboard
    get '/', to: 'dashboard#index', as: :root
    get '/dashboard', to: 'dashboard#index', as: ''
    get '/logs', to: 'dashboard#logs', as: 'logs'
    get '/logs/:id', to: 'dashboard#show_log', as: 'log'

    # Admin resources
    resources :users do
      post :toggle_admin, on: :member
    end
    resources :trades
    resources :channels do
      member do
        post :setup_discord_webhook
        post :test_discord_connection
      end
    end
    resources :subscriptions
    resources :payments
  end

  # API endpoints for registration process
  post "auth/verify_discord_username" => "auth#verify_discord_username"
  get "auth/get_channels" => "auth#get_channels"
  post "auth/update_connection_info" => "auth#update_connection_info"
  # API namespace for external integrations
  namespace :api do
    # Discord webhook endpoint
    post '/discord/webhook', to: 'discord_webhooks#receive'
  end

  # Health check endpoints
  get "health" => "health#show", as: :health_check
  get "up" => "rails/health#show", as: :rails_health_check

  # Multi-step user registration process
  namespace :registration do
    get "step1" => "steps#step1", as: :step1
    post "step1" => "steps#submit_step1"

    get "step2" => "steps#step2", as: :step2
    post "step2" => "steps#submit_step2"

    get "step3" => "steps#step3", as: :step3
    post "step3" => "steps#submit_step3"

    get "step4" => "steps#step4", as: :step4
    post "step4" => "steps#submit_step4"
    
    get "subscription" => "steps#subscription", as: :subscription
    post "subscription" => "steps#submit_subscription"
    
    # Step 5: Payment processing
    get "payment" => "steps#payment", as: :payment
    post "payment" => "steps#submit_payment"
    get "payment/success" => "steps#payment_success", as: :payment_success
  end

  get 'privacy_policy', to: 'static_pages#privacy_policy'
  get 'terms_and_conditions', to: 'static_pages#terms_and_conditions'
end
