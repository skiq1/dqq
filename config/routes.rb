Rails.application.routes.draw do
  devise_for :users
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
    get "posts/:id/download_as_zip", to: "posts#download_as_zip", as: :download_post_as_zip
    get "posts/unpin_all", to: "posts#unpin_all", as: :unpin_all
  end

  constraints(slug: /[^\.\/]+/) do
    get "/:slug", to: "posts#handle_slug", as: :post_by_slug, constraints: lambda { |req|
      excluded_words = %w[manifest rails favicon]
      !excluded_words.include?(req.params[:slug])
    }
  end


  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Defines the root path route ("/")
  # root "posts#index"
end
