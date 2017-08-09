Rails.application.routes.draw do
  resources :dts_hourlies
  devise_for :people
  resources :people
  get "/dts", to: "dts_hourlies#dts", as: "dts"
  get "/dts/hourly/live", to: "dts_hourlies#dts_hourlies_live", as: "dts_hourlies_live"
  get "/dts/hourly/live/do", to: "dts_hourlies#dts_hourlies_live_do"
  get "/dts_post", to: "dts_hourlies#dts_post", as: "dts_post"
  get "/app/views/home/index", to: "home#index", as: "index"
  root 'home#index'
end