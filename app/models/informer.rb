class Informer

  attr_reader :height, :width, :tile_width, :tile_height, :scale_factors

  def initialize(id)
    @id = id
    @path = Resolver.path(id)
  end

  # inform does the work of getting the information needed
  def inform
    if File.exist? info_cache_file_path
      parse_info_file
    else
      opj_info
    end
  end

  def info
    if @info
      @info
    elsif File.exist? info_cache_file_path
      read_info_file
    else
      create_full_info
    end
  end

  def opj_info
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

  # If we're actually
  def create_full_info
    @info = {
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
    # cache the info doc
    FileUtils.mkdir_p identifier_directory
    File.open(info_cache_file_path, 'w') do |fh|
      fh.puts @info.to_json
    end
    @info
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
    @info = read_info_file
    @width = info['width']
    @height = info['height']
    @scale_factors = info['tiles'][0]['scaleFactors']
  end

  def read_info_file
    json = File.read(info_cache_file_path)
    JSON.parse json
  end

  private

  def identifier_directory
    File.join Rails.root, "public/iiif", @id
  end

  # TODO: Dry this up
  def info_cache_file_path
    File.join identifier_directory, 'info.json'
  end
end
