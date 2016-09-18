# TODO: Allow for other resolvers.
module Resolver

  def self.path(id)
    first_two = id[0,2]
    if Rails.env == "development"
      File.join Rails.root, "/test/images/#{first_two}/#{id}.jp2"
    else      
      "/access-images/jp2s/#{first_two}/#{id}.jp2"
    end
  end

end
