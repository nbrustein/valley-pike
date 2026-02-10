Rails.application.routes.draw do
  devise_for :identities, controllers: { sessions: "identities/sessions" }

  post "identity/magic_link_identity", to: "create_magic_link_identity#create_magic_link_identity", as: :identity_magic_link_identity
  post "auth/password_session", to: "auth#create_password_session", as: :password_session
  resource :profile, only: %i[show update]

  root "home#index"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
