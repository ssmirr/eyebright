class VideoInformer

  attr_reader :ffmpeg_info, :height, :width, :duration, :frames

  def initialize(id, base_url)
    @id = id
    @base_url = base_url
    @path = VideoResolver.path(id)
  end

  def inform
    if File.exist? info_cache_file_path
      parse_info_file
    else
      @ffmpeg_info = get_ffmpeg_info
      create_full_info
    end
    memcache_info
  end

  def get_ffmpeg_info
    Dir.glob(@path + '*').map do |video_file|
      FfmpegInformer.new video_file
    end
  end

  def iiif_info
    if @iiif_info
      @iiif_info
    elsif File.exist? info_cache_file_path
      #read_into_file
      create_full_info
    else
      create_full_info
    end
  end

  def create_full_info
    @iiif_info = {
      '@id' => info_id,
      versions: versions,
      protocol: 'http://iiif.io/api/video',
      profile: ["http://iiif.io/api/video/0/level0.json"],
      '@context' => ["http://iiif.io/api/video/0/context.json"],
    }
    if false # TODO: turn video info.json caching on again
      FileUtils.mkdir_p identifier_directory
      File.open(info_cache_file_path, 'w') do |fh|
        fh.puts @iiif_info.to_json
      end
    end
    @iiif_info
  end

  def versions
    @ffmpeg_info.map do |version|
      video_file = {
        "@id" => video_id(version),
        width: version.width,
        height: version.height,
        duration: version.duration,
        format: version.format,
        poster: poster_image(version),
        ffmpeg_info: version.info,
      }
      video_file['frames'] = version.frames if version.frames
      video_file
    end
  end

  def info_id
    # FIXME: this won't work if trailing slash given for base_url setting
    File.join IiifUrl.base_url + 'v', @id
  end

  def video_id(version)
    extname = File.extname version.file
    File.join @base_url, 'videos', @id + extname
  end

  def poster_image(version)
    File.join info_id, '0/full/full/0/default.jpg'
  end

  private

  def parse_info_file
    @iiif_info = read_info_file
    @width = @iiif_info['width']
    @height = @iiif_info['height']
    @duration = @iiif_info['duration']
    @frames = @iiif_info['frames']
    # @scale_factors = @iiif_info['tiles'][0]['scaleFactors']
  end

  def read_info_file
    json = File.read(info_cache_file_path)
    JSON.parse json
  end

  # In Memcache we store just enough information for the extractors to use
  # without having to return here for the information.
  def memcache_info
    MDC.set "video:#{@id}", memcache_info_to_store
    Rails.logger.info "Memcache Set #{@id}"
  end

  def memcache_info_to_store
    {width: @width, height: @height, duration: @duration, frames: @frames}
  end

  def identifier_directory
    File.join Rails.root, "public/iiifv", @id
  end

  # TODO: Dry up info_cache_file_path here and in informer.rb
  def info_cache_file_path
    File.join identifier_directory, 'info.json'
  end

end
