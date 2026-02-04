require "sidekiq/web"

Rails.application.routes.draw do
  authenticate :admin, ->(admin) { admin.super_admin? } do
    mount Sidekiq::Web => "/admin/sidekiq"
  end

  devise_for :admins, path: "admin", path_names: {
    sign_in: "login",
    sign_out: "logout"
  }, controllers: {
    omniauth_callbacks: "admins/omniauth_callbacks",
    sessions: "admins/sessions"
  }, skip: [ :passwords, :registrations ]

  devise_scope :admin do
    get "admin/login", to: "admins/sessions#new", as: :new_admin_session
    delete "admin/logout", to: "admins/sessions#destroy", as: :destroy_admin_session
  end

  root "events#index"

  resources :events, only: [ :index ], param: :slug do
    member do
      get :show, path: ""
    end
  end

  get "events/:event_slug/apply", to: "visa_letter_applications#new", as: :new_event_application
  post "events/:event_slug/apply", to: "visa_letter_applications#create", as: :event_applications

  resources :visa_letter_applications, only: [ :show ] do
    member do
      get :verify_email
      post :confirm_verification
      post :resend_verification
      post :resend_letter
      get :download_letter
    end
  end

  get "lookup", to: "visa_letter_applications#lookup", as: :lookup_application
  post "lookup", to: "visa_letter_applications#find"

  get "documentation", to: "pages#documentation", as: :documentation

  get "verify", to: "verifications#show", as: :verify
  post "verify", to: "verifications#verify"

  namespace :admin do
    get "/", to: "dashboard#index", as: :dashboard

    resource :settings, only: [ :show, :update ]

    resources :events
    resources :visa_letter_applications, only: [ :index, :show ] do
      member do
        post :approve
        post :reject
        post :regenerate_letter
        post :downgrade_rejection
      end
    end
    resources :letter_templates do
      member do
        post :set_default
      end
    end
    resources :admins
  end

  get "up" => "rails/health#show", as: :rails_health_check
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
end
