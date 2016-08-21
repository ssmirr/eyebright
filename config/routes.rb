Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  prefix = 'iiif'

  match "#{prefix}/:id/:region/:size/:rotation/:quality.:format", to: 'images#show', via: [:get, :head]

  match "#{prefix}/:id/info.json", to: 'images#info', via: [:get, :head]

  get "#{prefix}/:id", to: redirect("iiif/%{id}/info.json")

  get "#{prefix}/:id/view", to: 'images#view'

  mount ResqueWeb::Engine => "/jobs"

end
