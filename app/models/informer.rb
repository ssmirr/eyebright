class Informer

  attr_reader :height, :width, :tile_width, :tile_height, :scale_factors

  def initialize(id)
    @id = id
    @path = Resolver.path(id)
  end

  def inform
    opj_info
    {
      width: @width,
      height: @height,
      tile_width: @tile_width,
      tile_height: @tile_height
    }
  end

  def info(id_url)
    {
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
      '@id' => id_url,
      '@context' => 'http://iiif.io/api/image/2/context.json'
    }
  end

  def opj_info
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
end
