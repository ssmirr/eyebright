# TODO: Allow for other resolvers.
module Resolver

  def self.path(id)
    if Rails.env == "development"
      File.join Rails.root, "/tmp/jp2s/#{id}.jp2"
    else
      first_two = id[0,2]
      "/access-images/jp2s/#{first_two}/#{id}.jp2"
    end
  end

end
