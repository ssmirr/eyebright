Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  match "iiif/:id/:region/:size/:rotation/:quality.:format", to: 'images#show', via: [:get, :head]

  match "iiif/:id/info.json", to: 'images#info', via: [:get, :head]

  get "iiif/:id", to: redirect("iiif/%{id}/info.json")
end
