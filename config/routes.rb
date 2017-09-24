Rails.application.routes.draw do
  resources :dts_hourlies
  devise_for :people
  resources :people
  resources :names
  resources :activity
  get "/dts", to: "dts_hourlies#dts", as: "dts"
  get "/dts/hourly/live", to: "dts_hourlies#dts_hourlies_live", as: "dts_hourlies_live"
  get "/dts/daypart", to: "dts_hourlies#daypart", as: "daypart"
  get "/dts/daypart/do", to: "dts_hourlies#daypart_do"
  get "/dts/hourly/live/do", to: "dts_hourlies#dts_hourlies_live_do"
  get "/dts/do", to: "dts_hourlies#dts_do", as: "dts_do"
  get "/app/views/home/index", to: "home#index", as: "index"
  get "/setup", to: "home#setup", as: "setup"
  get "/store", to: "home#store", as: "store"
  get "/setup/dp/do", to: "home#setup_dp_do", as: "setup_dp_do"
  root 'home#index'
end