module Resolver

  def self.path(id)
    File.join Rails.root, "/tmp/jp2s/#{id}.jp2"
  end

end
