Rails.application.routes.draw do
  # Admin
  namespace :admin do
    resources :postal_codes, only: :index
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # PWA
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Sitemap
  get "sitemap", to: "sitemaps#show", as: :sitemap, defaults: { format: :xml }

  # Locale switching
  get "locale/:locale", to: "locale#switch", as: :switch_locale

  # Legal pages
  get "privacy", to: "pages#privacy", as: :privacy
  get "terms", to: "pages#terms", as: :terms

  # FAQ page (SEO)
  get "faq", to: "pages#faq", as: :faq

  # Location hierarchy pages (SEO)
  get "provinces", to: "locations#provinces", as: :provinces
  get "provinces/:province", to: "locations#province", as: :province
  get "provinces/:province/:district", to: "locations#district", as: :province_district

  # Postal codes
  get "p/:postal_code", to: "postal_codes#show", as: :postal_code
  get "data", to: "postal_codes#data", as: :postal_data, defaults: { format: :json }
  get "search", to: "postal_codes#search", as: :search
  get "locate", to: "postal_codes#locate", as: :locate
  post "track_copy", to: "postal_codes#track_copy", as: :track_copy
  post "track_search", to: "postal_codes#track_search", as: :track_search
  root "postal_codes#index"
end
