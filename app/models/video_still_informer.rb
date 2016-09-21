class VideoStillInformer

  def initialize(id, time)
    @video_informer = VideoInformer.new id
    @id = id
    @time = time.to_i
  end

  def inform
    if File.exist? info_cache_file_path
      parse_info_file
    else
      @video_informer.inform
      utilize_video_informer
    end
  end

  def utilize_video_informer
    byebug
    @width = @video_informer.width
    @height = @video_informer.height
  end

  def iiif_info
    if @iiif_info
      @iiif_info
    elsif File.exist? info_cache_file_path
      read_info_file
    else
      create_full_info
    end
  end

  private

  # TODO: DRY this up with Informer
  def create_full_info
    @iiif_info = {
      width: @width,
      height: @height,
      # sizes: sizes,
      # tiles: [
      #   {
      #     width: @tile_width,
      #     scaleFactors: @scale_factors
      #   }
      # ],
      protocol: 'http://iiif.io/api/image',
      profile: [
        "http://iiif.io/api/image/2/level2.json",
        profile_description
      ],
      '@id' => info_id,
      '@context' => [
        'http://iiif.io/api/image/2/context.json',
        { ronallo: "http://ronallo.com/ns/",
          gravityBangs: {
            "@id" => "ronallo:gravityBangsFeature",
            "@type" => "iiif:Feature" }
        }]
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

  # TODO: DRY this up with Informer
  def parse_info_file
    @iiif_info = read_info_file
    @width = @iiif_info['width']
    @height = @iiif_info['height']
    # @scale_factors = @iiif_info['tiles'][0]['scaleFactors']
  end

  # TODO: DRY this up with Informer
  def read_info_file
    json = File.read(info_cache_file_path)
    JSON.parse json
  end

  # TODO: DRY this up with Informer
  def identifier_directory
    File.join Rails.root, "public/iiifv", @id, @time.to_s
  end

  # TODO: DRY this up with Informer
  def info_cache_file_path
    File.join identifier_directory, 'info.json'
  end

  # TODO: DRY this up with Informer
  def profile_description
    {
      formats: [:jpg, :png],
      maxWidth: @width,
      maxHeight: @height,
      qualities: [:color, :gray, :bitonal],
      supports: %w[
        baseUriRedirect cors
        regionByPct regionByPx regionSquare
        mirroring rotationArbitrary rotationBy90s
        sizeByConfinedWh SizeByDistortedWh
        sizeByH sizeByPct sizeByW sizeByWh
        gravityBangs
      ]
    }
  end

  def info_id
    File.join IiifUrl.base_url, @id, @time.to_s
  end

end
