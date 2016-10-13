Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  # Image API
  image_prefix = 'iiif'
  match "#{image_prefix}/:id/:region/:size/:rotation/:quality.:format", to: 'images#show', via: [:get, :head]
  match "#{image_prefix}/:id/info.json", to: 'images#info', via: [:get, :head]
  get "#{image_prefix}/:id", to: redirect("#{image_prefix}/%{id}/info.json")
  get "#{image_prefix}/:id/view", to: 'images#view'

  # Experimental Video API
  video_prefix = 'iiifv'
  time_constraint = /(\d\d\:\d\d\:\d\d|\d+)(\.\d+)?/
  match "#{video_prefix}/:id/:time/:region/:size/:rotation/:quality.:format", constraints: {time: time_constraint}, to: 'videos#show', via: [:get, :head]
  match "#{video_prefix}/:id/:time/info.json", constraints: {time: time_constraint}, to: 'videos#image_info', via: [:get, :head]
  # info.json for the video
  match "#{video_prefix}/:id/info.json", to: 'videos#info', via: [:get, :head]
  get "#{video_prefix}/:id", to: redirect("#{video_prefix}/%{id}/info.json")

  mount ResqueWeb::Engine => "/jobs"

end
