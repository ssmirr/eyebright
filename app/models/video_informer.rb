class VideoInformer

  attr_reader :ffmpeg_info, :height, :width, :duration, :frames

  def initialize(id)
    @id = id
    @path = VideoResolver.path(id)
  end

  def inform
    if File.exist? info_cache_file_path
      parse_info_file
    else
      get_ffmpeg_info
    end
    memcache_info
  end

  def get_ffmpeg_info
    Rails.logger.info ffmpeg_info_cmd
    result = `#{ffmpeg_info_cmd}`
    @ffmpeg_info = JSON.parse result
    video_stream = get_video_stream
    @width = video_stream['width']
    @height = video_stream['height']
    @duration = video_stream['duration']
    @frames = video_stream['nb_frames']
    create_full_info
  end

  def ffmpeg_info_cmd
    "ffprobe -v error -print_format json -show_format -show_streams #{@path}"
  end

  def get_video_stream
    @ffmpeg_info['streams'].find do |stream|
      stream['codec_type'] == 'video'
    end
  end

  def iiif_info
    if @iiif_info
      @iiif_info
    elsif File.exist? info_cache_file_path
      read_into_file
    else
      create_full_info
    end
  end

  def create_full_info
    @iiif_info = {
      width: @width,
      height: @height,
      duration: @duration,
      frames: @frames,
      protocol: 'http://iiif.io/api/video',
      profile: ["http://iiif.io/api/video/0/level-1.json"],
      '@id' => info_id,
      '@context' => ["http://iiif.io/api/video/0/context.json"],
      'comments' => [
        '"sizes" not yet implemented',
        'Does "tiles" make sense?',
        'What "supports" might be different for a video?',
        'Maybe specify available times or available frames for still images?'
      ]
    }
    FileUtils.mkdir_p identifier_directory
    File.open(info_cache_file_path, 'w') do |fh|
      fh.puts @iiif_info.to_json
    end
    @iiif_info
  end

  def info_id
    # FIXME: this won't work if trailing slash given for base_url setting
    File.join IiifUrl.base_url + 'v', @id
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
