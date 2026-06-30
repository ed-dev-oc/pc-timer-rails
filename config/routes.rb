Rails.application.routes.draw do
  mount MissionControl::Jobs::Engine, at: "/jobs"

  namespace :api, defaults: { format: :json } do
    get :server_time, to: "system#server_time"

    resources :pcs, only: [] do
      member do
        post :signin
        post :signout
        post :heartbeat
        get :session_status
      end

      collection do
        post :register
      end
    end

    resources :coin_slots, only: [] do
      member do
        post :heartbeat
      end
      collection do
        post :register
      end
    end

    resources :coin_slot_sessions, only: [] do
      resources :coin_transactions, only: [ :create ]
    end
  end

  namespace :winform do
    resources :pcs, only: [ :show ] do
      collection do
        get :error
      end

      member do
        get :minimize
      end

      resources :pc_sessions, only: [ :create, :update ]

      resources :coin_slot_sessions, only: [ :create ] do
        collection do
          patch :cancel
        end
      end
    end
  end

  namespace :admin do
    root "dashboard#index"

    resources :coin_slots, except: [ :new, :create, :edit ] do
      member do
        post :restart
        patch :toggle_lock
      end
    end

    resources :pcs, except: [ :new, :create, :edit ] do
      member do
        post :restart
        post :shutdown
        post :enable_or_disabled_kiosk
        post :kiosk_uninstalled
      end

      resources :pc_sessions, only: [ :create ] do
        member do
          post :stop_session
        end
      end
    end
  end

  devise_for :users
  get "settings", to: "users#settings", as: :settings
  patch "settings", to: "users#update", as: :update_settings
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"
end
