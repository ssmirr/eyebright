class VideoStillInformer

  def initialize(id, base_url)
    @video_informer = VideoInformer.new id, base_url
    @id = id
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
      # sizes: sizes,
      # tiles: [
      #   {
      #     width: @tile_width,
      #     scaleFactors: @scale_factors
      #   }
      # ],
      'id' => info_id,
      within: video_info_id,
      '_comments': [
        'How can we say that this is an image server of the type that requires a time segment since it is extracting from a video?',
        'How can we say that this image server delivers images from within a particular video?'
      ],
      protocol: 'http://iiif.io/api/image',
      profile: [
        "http://iiif.io/api/image/2/level2.json",
        profile_description
      ],

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
    # TODO: Cache image info.json
    # FileUtils.mkdir_p identifier_directory
    # File.open(info_cache_file_path, 'w') do |fh|
    #   fh.puts @iiif_info.to_json
    # end
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
    File.join Rails.root, "public/iiifvi", @id
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
    File.join IiifUrl.base_url + 'vi', @id
  end

  def video_info_id
    File.join IiifUrl.base_url + 'v', @id
  end

end
