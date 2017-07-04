Rails.application.routes.draw do
  resources :dts_hourlies
  devise_for :people
  resources :people
  get "/dts", to: "dts_hourlies#dts", as: "dts"
  get "/app/views/home/index", to: "home#index", as: "index"
  root 'home#index'
end