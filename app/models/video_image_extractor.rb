class VideoImageExtractor

  include Converter

  def initialize(request, params)
    @request = request
    @iiif = IiifUrl.parse request.path
    @params = params
    @id = params[:id]
    @path = video_path
    get_informer
    enrich_iiif_params
    # FIXME: pick better temporary images
    @temp_out_image = Tempfile.new [@id, '.jpg']
    @temp_response_image = Tempfile.new [@id, ".#{@params[:format]}"]
  end

  def video_path
    @informer = VideoInformer.new @id, @request.base_url
    @informer.inform
    @video_info = @informer.iiif_info

    max = @video_info[:sources].max_by do |source|
      source[:width] * source[:height]
    end
    File.join VideoResolver.path(@id), "#{max[:width]},#{max[:height]}", "default.#{max[:format]}"
  end

  def get_informer
    mc_info = MDC.get "video:#{@id}"
    if mc_info
      Rails.logger.info "Memcached Hit #{@id}"
      @informer = OpenStruct.new mc_info
    else
      @informer = VideoInformer.new @id, @request.base_url
      @informer.inform
    end
  end

  def extract
    # Check for full size image first
    if !full_size_image?
      Rails.logger.info ffmpeg_image_extractor_cmd
      `#{ffmpeg_image_extractor_cmd}`
      FileUtils.mkdir_p full_size_image_directory
      FileUtils.cp @temp_out_image.path, full_size_image_path
    end
    `#{convert_cmd}`
    @temp_response_image
  end

  def ffmpeg_image_extractor_cmd
    # Use fast input seeking: https://trac.ffmpeg.org/wiki/Seeking
    # TODO: Handle time better. For now just convert to an integer to make sure it is safe
    "ffmpeg -y -ss #{ffmpeg_time} -i #{@path} -vframes 1 #{@temp_out_image.path}"
  end

  def ffmpeg_time
    if @params[:time].match /^(\d\d\:\d\d\:\d\d|\d+)(\.\d+)?$/
      @params[:time]
    else
      # TODO: raise an error
    end
  end

  def full_size_image?
    File.exist? full_size_image_path
  end

  def full_size_image_path
    File.join full_size_image_directory, "default.jpg"
  end

  def full_size_image_directory
    File.join Rails.root,
     "public/iiifvi/#{@id}",
     "#{@params[:time]}/full/full/0"
  end

  def base_convert_cmd
    cmd = "convert "
    # There should always be this full size image now
    cmd << " #{full_size_image_path}"

    unless @iiif[:region] == 'full'
      cmd << " -crop #{@iiif[:region][:w]}x#{@iiif[:region][:h]}+#{@iiif[:region][:x]}+#{@iiif[:region][:y]}"
    end
    cmd
  end

end
