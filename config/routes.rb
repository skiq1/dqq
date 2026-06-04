Rails.application.routes.draw do
  devise_for :users

  # =========================
  # OLD / CURRENT APP
  # =========================
  root "posts#index"

  scope "/manage" do
    resources :posts do
      member do
        get :pin
        get :unpin
      end
    end

    get "/user_posts", to: "posts#user_posts", as: :user_posts
    get "/redirect_posts", to: "posts#redirect_posts", as: :redirect_posts

    get "posts/unpin_all", to: "posts#unpin_all", as: :unpin_all
    get "posts/:id/download_as_zip", to: "posts#download_as_zip", as: :download_post_as_zip
    get "posts/:id/password", to: "posts#password_prompt", as: :post_password
    post "posts/:id/verify_password", to: "posts#verify_password", as: :verify_post_password
  end

  # V2 APP
  namespace :v2 do
    root "explorer#show"

    get "explorer", to: "explorer#show", as: :explorer
    get "explorer/*path", to: "explorer#show", as: :explorer_folder

    resources :folders, only: [:create, :edit, :update, :destroy, :new]
    # resources :folder_pins, only: [:create, :destroy]
    # resources :posts
  end

  # SYSTEM ROUTES
  get "up" => "rails/health#show", as: :rails_health_check

  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # PUBLIC POST SLUGS
  constraints(slug: /[^\.\/]+/) do
    get "/:slug",
        to: "posts#handle_slug",
        as: :post_by_slug,
        constraints: lambda { |req|
          excluded_words = %w[
            manifest
            rails
            favicon
            up
            service-worker
            v2
          ]

          !excluded_words.include?(req.params[:slug])
        }
  end
end
