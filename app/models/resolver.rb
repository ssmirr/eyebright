# TODO: Allow for other resolvers.
module Resolver

  def self.path(id)
    first_two = id[0,2]
    File.join Rails.configuration.eyebright['base_resolver_path'], first_two, "#{id}.jp2"
  end

end
