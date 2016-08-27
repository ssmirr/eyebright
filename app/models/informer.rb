class Informer

  attr_reader :height, :width, :tile_width, :tile_height, :scale_factors

  def initialize(id)
    @id = id
    @path = Resolver.path(id)
  end

  # Inform does the work of getting the information needed, but does not create
  # the info.json response. We do the least we possibly can for most cases.
  # TODO: This is kind of wonky but it is always necessary to call this method
  # before we can call iiif_info, but in most cases we never really need the
  # full info.json response.
  def inform
    # If the info.json exists in the file system cache then we read that in
    # and initialize the variables that are used by an extractor like width,
    # height, and scale factors.
    if File.exist? info_cache_file_path
      parse_info_file
    else
      # If a cached file does not exist, then we use OpenJPEG to get the
      # information. We use this tool as it more clearly gives all the relevant
      # information including number of resolution levels.
      get_opj_info
    end
    # Now that we have the information that an extractor regularly needs one
    # way or another we can cache it.
    memcache_info
  end

  # Creates the info.json response.
  # Before calling this method #inform needs to be called so that the info.json
  # can be created.
  def iiif_info
    if @iiif_info
      @iiif_info
    elsif File.exist? info_cache_file_path
      read_info_file
    else
      create_full_info
    end
  end

  def get_opj_info
    puts opj_info_cmd
    result = `#{opj_info_cmd}`
    width_match = result.match /x1=(.*),/
    @width =  width_match[1].to_i

    height_match = result.match /, y1=(.*)/
    @height =  height_match[1].to_i

    levels_match = result.match /numresolutions=(.*)/
    @levels = levels_match[1].to_i - 1

    tiles_match_width = result.match /tdx=(.*),/
    @tile_width =  tiles_match_width[1].to_i

    tiles_match_height = result.match /tdy=(.*)/
    @tile_height =  tiles_match_height[1].to_i

    get_scale_factors
    create_full_info
  end

  def create_full_info
    @iiif_info = {
      width: @width,
      height: @height,
      sizes: sizes,
      tiles: [
        {
          width: @tile_width,
          scaleFactors: @scale_factors
        }
      ],
      protocol: 'http://iiif.io/api/image',
      profile: [
        "http://iiif.io/api/image/2/level1.json"
      ],
      '@id' => info_id,
      '@context' => 'http://iiif.io/api/image/2/context.json'
    }
    # Cache the info doc now. We do the caching here so that it gets cached
    # whether it is being created via an image or an info.json request.
    FileUtils.mkdir_p identifier_directory
    File.open(info_cache_file_path, 'w') do |fh|
      fh.puts @iiif_info.to_json
    end
    # Also cache to Memcached.

    @iiif_info
  end

  def info_id
    File.join IiifUrl.base_url, @id
  end

  def opj_info_cmd
    "opj_dump -i #{@path}"
  end

  def get_scale_factors
    @scale_factors = (0..@levels).map do |level|
      2**level
    end
  end

  # TODO: Sizes could include sizes from the profile document when those are
  # for a full region. This would be a hint about images that can be returned
  # quickly.
  def sizes
    w = @width
    h = @height
    sizes = []
    (0..@levels).each do |level|
      sizes << { width: w, height: h }
      w = (w/2.0).ceil
      h = (h/2.0).ceil
    end
    sizes.reverse
  end

  def parse_info_file
    @iiif_info = read_info_file
    @width = @iiif_info['width']
    @height = @iiif_info['height']
    @scale_factors = @iiif_info['tiles'][0]['scaleFactors']
  end

  def read_info_file
    json = File.read(info_cache_file_path)
    JSON.parse json
  end

  private

  # In Memcache we store just enough information for the extractors to use
  # without having to return here for the information.
  def memcache_info
    MDC.set @id, {width: @width, height: @height, scale_factors: @scale_factors }
    Rails.logger.info "Memcache Set #{@id}"
  end

  def identifier_directory
    File.join Rails.root, "public/iiif", @id
  end

  # TODO: Dry this up
  def info_cache_file_path
    File.join identifier_directory, 'info.json'
  end
end
