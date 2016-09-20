class VideoImageExtractor

  include Converter

  def initialize(url, params)
    @iiif = IiifUrl.parse url
    @params = params
    @path = VideoResolver.path @params[:id]
    get_informer
    enrich_iiif_params
    # FIXME: pick better temporary images
    @temp_out_image = Tempfile.new [@params[:id], '.tif']
    @temp_response_image = Tempfile.new [@params[:id], ".#{@params[:format]}"]
  end

  def get_informer
    raw_info = `ffprobe -v error -show_entries stream=width,height -of default=noprint_wrappers=1 #{@path}`
    width = raw_info.match(/width=(.*)\n/)[1].to_i
    height = raw_info.match(/height=(.*)\n/)[1].to_i
    @informer = OpenStruct.new height: height, width: width
  end

  def extract
    # TODO: Handle time better. For now just convert to an integer to make sure it is safe
    `ffmpeg -y -i #{@path} -ss #{@params[:time].to_i} -vframes 1 #{@temp_out_image.path}`
    `#{convert_cmd}`
    @temp_response_image
  end

  def base_convert_cmd
    cmd = "convert #{@temp_out_image.path} "
    unless @iiif[:region] == 'full'
      cmd << " -crop #{@iiif[:region][:w]}x#{@iiif[:region][:h]}+#{@iiif[:region][:x]}+#{@iiif[:region][:y]}"
    end
    cmd
  end

end
