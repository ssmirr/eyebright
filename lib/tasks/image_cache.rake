namespace :iiifis do

  desc 'prune all the file cache based on a profile'
  task :prune_all => :environment do
    cp = CachePruner.new(IIIF_PROFILE)
    cp.prune_all
  end

  desc 'prune for single identifier'
  task :prune, [:id] => :environment do |t, args|
    if !args[:id]
      puts 'bin/rake iiifis:prune[IDENTIFIER]'
      exit
    end
    cp = CachePruner.new(IIIF_PROFILE)
    directory = File.join Rails.root, 'public/iiif', args[:id]
    cp.prune directory
  end

end
