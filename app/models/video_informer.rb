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
    video_paths.map do |video_file|
      FfmpegInformer.new video_file
    end
  end

  def video_paths
    Dir.glob(@path + '/*').grep(/\.(mp4|webm)/)
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
          width: version.width,
          height: version.height,
          duration: version.duration,
          type: version.mimetype_with_codecs,
          format: version.format,
          size: version.size,
          # ffmpeg_info: version.info,
        }
        video_file['frames'] = version.frames if version.frames
        video_file
      end
    end
  end

  def video_identifier(version)
    File.join @base_url, 'iiifv', video_path_after_root(version)
  end

  def video_path_after_root(version)
    path_after_root version.file
  end

  def path_after_root(file_path)
    root_path = File.join Rails.root, 'public', 'iiifv'
    file_path.sub /^#{root_path}/, ''
  end

  def sorted_sources
    sources.sort_by{ |source| source[:width] * source[:height] }.reverse
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
    File.join @base_url, 'iiifv', path_after_root(track_file)
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
    File.join Rails.root, "public/iiifv", @id
  end

  # TODO: Dry up info_cache_file_path here and in informer.rb
  def info_cache_file_path
    File.join identifier_directory, 'info.json'
  end

end
