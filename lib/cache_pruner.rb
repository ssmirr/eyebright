# TODO: There could also be an alternative implementation that uses the file's
# atime to determine whether to delete a file or not, but that might take
# longer.

# TODO: This currently probably misses some things that are in one profile URL
# but not in another, but oh well close enough for now. What we need to do is
# check whether the whole path from a profile matches which will result in
# pruning more documents.
class CachePruner

  def initialize(profiles)
    @profiles = profiles
    parse_profiles
  end

  # Recurse down through the directories but remove from the top level first
  # so we don't have to recurse through every file.
  # This does no checking for age of the files being deleted.
  # TODO: This could probably be a nice recursive method, but oh well.
  def prune_all
    # find all the identifiers and iterate over them
    Dir.glob(cache_glob).sort.each do |id_directory|
      prune(id_directory)
    end
  end

  def prune(id_directory)
    id = File.basename id_directory
    # puts id
    # clear out regions first
    Dir.glob(id_directory + '/*').each do |region_dir|
      region = File.basename region_dir
      next if region == 'info.json'
      # puts "#{id}/#{region}"
      if @regions.any?{|r| r == region}
        Dir.glob(region_dir + '/*').each do |size_dir|
          size = File.basename size_dir
          # puts "#{id}/#{region}/#{size}"
          if @sizes.any?{|s| s == size}
            Dir.glob(size_dir + '/*').each do |rotation_dir|
              rotation = File.basename rotation_dir
              # puts "#{id}/#{region}/#{size}/#{rotation}"
              if @rotations.any?{|r| r == rotation}
                Dir.glob(rotation_dir + '/*').each do |filename_dir|
                  filename = File.basename filename_dir
                  if !@quality_formats.any?{|qf| qf == filename}
                    delete(filename_dir)
                  end
                end
              else # rotation not in profiles
                delete(rotation_dir)
              end
            end
          else # size not in profiles
            delete(size_dir)
          end
        end
      else # region not in profiles
        delete(region_dir)
      end
    end
  end

  private

  def parse_profiles
    @regions = []
    @sizes = []
    @rotations = []
    @quality_formats = []
    @profiles.each do |profile|
      parts = profile.split('/')
      @regions << parts[1]
      @sizes << parts[2]
      @rotations << parts[3]
      @quality_formats << parts[4]
    end
  end

  def delete(directory)
    puts "delete: #{directory}"
    FileUtils.rm_rf directory
  end

  def cache_directory
    # On deploy public/iiif should be a symlink to where the cache actually
    # lives in order to persist across deploys.
    File.join Rails.root, 'public/iiif'
  end

  def cache_glob
    File.join cache_directory, '*'
  end

end
