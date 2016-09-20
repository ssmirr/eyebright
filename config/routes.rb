Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  image_prefix = 'iiif'
  match "#{image_prefix}/:id/:region/:size/:rotation/:quality.:format", to: 'images#show', via: [:get, :head]
  match "#{image_prefix}/:id/info.json", to: 'images#info', via: [:get, :head]
  get "#{image_prefix}/:id", to: redirect("iiif/%{id}/info.json")
  get "#{image_prefix}/:id/view", to: 'images#view'

  video_prefix = 'iiifv'
  match "#{video_prefix}/:id/:time/:region/:size/:rotation/:quality.:format", to: 'videos#show', via: [:get, :head]

  mount ResqueWeb::Engine => "/jobs"

end
