class VideoInformer

  attr_reader :ffmpeg_info, :height, :width, :duration, :frames

  def initialize(id, base_url)
    @id = id
    @base_url = base_url
    @path = VideoResolver.path(id)
  end

  def eyebright_video_prefix
    'iiifv'
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
    video_paths.map do |video_file|
      FfmpegInformer.new video_file
    end
  end

  def video_paths
    progressive_paths = Dir.glob(@path + '/*').grep(/\.(mp4|webm)/)
    # Currently only DASH fMP4 single file sources are looked for. This is
    # DASH which is configured to use byte ranges so these same MP4s can also
    # be provided for
    abr_paths = Dir.glob(@path + '/*-dash/*').grep(/\.mp4/)
    progressive_paths + abr_paths
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
      '_comments': [
        'This is totally not how this should look, but will give some idea of what data we would want about a video and what is possible for extracting from ffmpeg.'
      ],
      '@context' => "http://iiif.io/api/video/0/context.json",
      'id' => info_id,
      profile: "http://iiif.io/api/video/0/level0.json",
      attribution: Rails.configuration.eyebright['attribution'],
      sources: sorted_sources,
      tracks: tracks,
      thumbnail: poster_image,
    }
    if false # TODO: turn video info.json caching on again
      FileUtils.mkdir_p identifier_directory
      File.open(info_cache_file_path, 'w') do |fh|
        fh.puts @iiif_info.to_json
      end
    end
    @iiif_info
  end

  def sources
    if @sources
      @sources
    else
      @sources = @ffmpeg_info.map do |version|
        video_file = {
          id: video_identifier(version),
          duration: version.duration,
          type: version.mimetype_with_codecs,
          format: version.format,
          size: version.size,
        }
        video_file['width'] = version.width if version.width
        video_file['height'] = version.height if version.height
        video_file['frames'] = version.frames if version.frames
        # video_file['ffmpeg_info'] = version.info if Rails.env == 'development'
        video_file
      end
      add_adaptive_bitrate_sources
      @sources
    end
  end

  def add_adaptive_bitrate_sources
    if File.exist? hls_directory
      add_hls_source
    end
    if File.exist? dash_directory
      add_dash_source
    end
  end

  def add_hls_source
    @sources << {
      id: hls_uri,
      type: 'application/vnd.apple.mpegURL',
      format: 'ts', #todo support fMP4 for HLS as well
      "_comments": 'How to say this uses a MPEG-TS container or an fMP4 container?'
    }
  end

  def add_dash_source
    @sources << {
      id: dash_uri,
      type: 'application/dash+xml',
      "_comments": 'Since MPEG-DASH can use many different video and audio codecs, how to say that this uses some variant like DASH264 (which is actually about more than just the video and audio codecs used)?'
    }
  end

  def hls_directory
    File.join @path, "#{@id}-hls"
  end

  def hls_filepath
    File.join hls_directory, "#{@id}-hls.m3u8"
  end

  def hls_uri
    File.join @base_url, eyebright_video_prefix, path_after_root(hls_filepath)
  end

  def dash_directory
    File.join @path, "#{@id}-dash"
  end

  def dash_filepath
    File.join dash_directory, "#{@id}-dash.mpd"
  end

  def dash_uri
    File.join @base_url, eyebright_video_prefix, path_after_root(dash_filepath)
  end

  def video_identifier(version)
    File.join @base_url, eyebright_video_prefix, video_path_after_root(version)
  end

  def video_path_after_root(version)
    path_after_root version.file
  end

  def path_after_root(file_path)
    root_path = File.join Rails.root, 'public', eyebright_video_prefix
    file_path.sub /^#{root_path}/, ''
  end

  def sorted_sources
    # sources.sort_by{ |source| source[:width] * source[:height] }.reverse
    sources
  end

  def info_id
    # FIXME: this won't work if trailing slash given for base_url setting
    File.join IiifUrl.base_url + 'v', @id
  end

  def image_info_id
    File.join IiifUrl.base_url + 'vi', @id
  end

  def track_paths
    Dir.glob(@path + '/*').grep(/\.vtt/)
  end

  def tracks
    track_paths.map do |track_file|
      kind, language = parse_track_name(track_file)
      {
        id: track_identifier(track_file),
        kind: kind,
        language: language,
      }
    end
  end

  def track_identifier(track_file)
    File.join @base_url, eyebright_video_prefix, path_after_root(track_file)
  end

  def parse_track_name(track_file)
    extension = File.extname track_file
    basename = File.basename track_file, extension
    name, kind, language = basename.split('-')
    kind = 'captions' if kind.nil?
    language = 'en' if language.nil?
    [kind, language]
  end

  def poster_image
    {
      "id": File.join(image_info_id, '2/full/full/0/default.jpg'),
      "type": "Image",
      "format": "image/jpeg",
      width: sorted_sources.first[:width],
      height: sorted_sources.first[:height],
      service: {
        "@context": "http://iiif.io/api/image/2/context.json",
        "id": image_info_id,
        profile: "http://iiif.io/api/image/2/level2.json"
      },
    }
  end

  private

  def parse_info_file
    @iiif_info = read_info_file
    @width = @iiif_info['width']
    @height = @iiif_info['height']
    @duration = @iiif_info['duration']
    @frames = @iiif_info['frames']
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
    File.join Rails.root, "public", eyebright_video_prefix, @id
  end

  # TODO: Dry up info_cache_file_path here and in informer.rb
  def info_cache_file_path
    File.join identifier_directory, 'info.json'
  end

end
