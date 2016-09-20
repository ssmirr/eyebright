# TODO: Allow for other resolvers.
module VideoResolver

  def self.path(id)
    # first_two = id[0,2]
    # File.join Rails.configuration.eyebright['base_resolver_path'], first_two, "#{id}.jp2"
    File.join Rails.configuration.eyebright['base_video_resolver_path'], "#{id}.mp4"
  end

end
