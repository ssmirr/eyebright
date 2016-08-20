Rails.application.routes.draw do
  get 'iis/show'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html



  get "iiif/:id/:region/:size/:rotation/:quality.:format" => 'images#show'

  get "iiif/:id/info.json" => 'images#info'

  get "iiif/:id", to: redirect("iiif/%{id}/info.json")
end
