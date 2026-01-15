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

  # Legal pages
  get "privacy", to: "pages#privacy", as: :privacy
  get "terms", to: "pages#terms", as: :terms

  # Postal codes
  get "search", to: "postal_codes#search", as: :search
  get "locate", to: "postal_codes#locate", as: :locate
  post "track_copy", to: "postal_codes#track_copy", as: :track_copy
  root "postal_codes#index"
end
