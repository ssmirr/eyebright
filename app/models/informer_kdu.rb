class InformerKdu

  attr_reader :height, :width, :tile_width, :tile_height, :scale_factors

  def initialize(id)
    @id = id
    @path = Resolver.path(id)
  end

  def inform
    kdu_info
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

  def kdu_info
    result = `#{kdu_info_cmd}`
    xml = Nokogiri::XML result
    codestream = xml.xpath("//JP2_family_file/jp2c/codestream")
    @width = codestream.xpath('./width')[0].text.to_i
    @height = codestream.xpath('./height')[0].text.to_i
    siz = codestream.xpath('./SIZ')[0].text
    match = siz.match /Stiles=\{(.*)\}/
    tile_width, tile_height = match[1].split(',')
    @tile_width = tile_width.to_i
    @tile_height = tile_height.to_i

    @levels = extract_levels

    get_scale_factors
  end

  def kdu_info_cmd
    "kdu_jp2info -siz -boxes 1 -com -i #{@path}"
  end

  def extract_levels
    # FIXME: get the current number of levels
    6
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
