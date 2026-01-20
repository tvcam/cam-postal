Rails.application.routes.draw do
  # Error pages
  match "/404", to: "errors#not_found", via: :all
  match "/422", to: "errors#unprocessable", via: :all
  match "/500", to: "errors#internal_error", via: :all
  match "/400", to: "errors#bad_request", via: :all

  # Admin
  namespace :admin do
    resources :postal_codes, only: :index
    resources :search_logs, only: :index
    resources :api_access_logs, only: :index
    resources :learned_aliases, only: [ :index, :destroy ] do
      member do
        post :promote
        post :demote
      end
    end
    resources :feedbacks, only: [ :index, :show, :destroy ]
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # PWA
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Sitemap
  get "sitemap", to: "sitemaps#show", as: :sitemap, defaults: { format: :xml }

  # AI/LLM-friendly endpoints
  get "llms-full", to: "postal_codes#llms_full", as: :llms_full, defaults: { format: :txt }

  # Locale switching
  get "locale/:locale", to: "locale#switch", as: :switch_locale

  # Legal pages
  get "privacy", to: "pages#privacy", as: :privacy
  get "terms", to: "pages#terms", as: :terms

  # FAQ page (SEO)
  get "faq", to: "pages#faq", as: :faq

  # API documentation for AI/developers
  get "open-data", to: "pages#api", as: :api

  # Public stats
  get "stats", to: "pages#stats", as: :stats

  # Feedback form
  get "feedback", to: "feedbacks#new", as: :new_feedback
  post "feedback", to: "feedbacks#create", as: :feedback
  get "feedback/thanks", to: "feedbacks#thanks", as: :feedback_thanks

  # Location hierarchy pages (SEO)
  get "provinces", to: "locations#provinces", as: :provinces
  get "provinces/:province", to: "locations#province", as: :province
  get "provinces/:province/:district", to: "locations#district", as: :province_district

  # Postal codes
  get "p/:postal_code", to: "postal_codes#show", as: :postal_code
  get "data", to: "postal_codes#data", as: :postal_data, defaults: { format: :json }
  get "search", to: "postal_codes#search", as: :search
  get "locate", to: "postal_codes#locate", as: :locate
  post "track/copy", to: "postal_codes#record_copy", as: :track_copy
  post "track/search", to: "postal_codes#record_search", as: :track_search

  # Time Capsules
  post "p/:postal_code/capsules", to: "time_capsules#create", as: :postal_code_capsules
  post "capsules/:id/heart", to: "time_capsules#heart", as: :capsule_heart
  post "capsules/:id/flag", to: "time_capsules#flag", as: :capsule_flag

  # Surprise Me / Random Destination
  get "surprise", to: "surprise#index", as: :surprise
  get "surprise/reveal", to: "surprise#reveal", as: :surprise_reveal

  root "postal_codes#index"
end
