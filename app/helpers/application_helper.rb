module ApplicationHelper

  def embed_osd_js
    Rails.application.config.action_controller.relative_url_root.to_s + '/osd/openseadragon.js'
  end

end
