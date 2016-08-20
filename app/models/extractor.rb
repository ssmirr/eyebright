class Extractor
  # Just a kdu extractor for now

  def initialize(url, params)
    @path = Resolver.path params[:id]
    @iiif = IiifUrl.parse url
    @informer = Informer.new params[:id]
    @informer.inform
    @sizer = @iiif[:size].is_a?(String) ? {w: @informer.width, h: @informer.height} : @iiif[:size]
    # FIXME: pick better temporary images
    @temp_out_image = Tempfile.new [params[:id], '.tif']
    @temp_response_image = Tempfile.new [params[:id], ".#{params[:format]}"]
  end

  def extract
    if @iiif[:region] == 'full'
      top, left, height, width = [0, 0, @informer.height, @informer.width]
    else
      top, left, height, width = @iiif[:region][:y], @iiif[:region][:y], @iiif[:region][:h], @iiif[:region][:w]
    end

    @top_pct = top.to_f / @informer.height
    @left_pct = left.to_f / @informer.width
    @height_pct = height.to_f / @informer.height
    @width_pct = width.to_f / @informer.width
    cmd = kdu_cmd
    puts cmd
    `#{kdu_cmd}`
    `#{convert_cmd}`
    FileUtils.rm @temp_out_image.path
    @temp_response_image
  end

  def kdu_cmd
    cmd = "kdu_expand -i #{@path} -o #{@temp_out_image.path} -region '{#{@top_pct},#{@left_pct}},{#{@height_pct},#{@width_pct}}'"
    reduction = if @iiif[:size] == 'full'
      0
    else
      pick_reduction
    end
    cmd + " -reduce #{reduction}"
  end

  def convert_cmd
    cmd = "convert #{@temp_out_image.path} "
    if convert_resize
      cmd << " -resize #{convert_resize} "
    end

    if @iiif[:rotation][:degrees] != 0
      if ![90, 180, 270].any?{|degree| degree == @iiif[:rotation][:degrees]}
        cmd << " -virtual-pixel white"
      end
      cmd << " +distort srt #{@iiif[:rotation][:degrees]}"
    end

    if @iiif[:rotation][:mirror]
      cmd << " -flop"
    end

    case @iiif[:quality]
      when 'grey'
        cmd << ' -colorspace Gray'
      when 'bitonal'
        cmd << ' -colorspace Gray'
        cmd << ' -type Bilevel'
      end

    cmd << " #{@temp_response_image.path}"
    puts cmd
    cmd
  end

  def convert_resize
    size = @iiif[:size]
    if size == 'full'
      nil
    elsif !size[:w] && size[:h]
      "x#{size[:h]}"
    elsif size[:w] && !size[:h]
      "#{size[:w]}x"
    elsif size[:w] && size[:h]
      "#{size[:w]}x#{size[:h]}!"
    else
      # raise InvalidAttributeError, "Invalid size: #{size}"
    end
  end

  def pick_reduction
    if @sizer[:w]
      region_width = @iiif[:region] == 'full' ? @informer.width : @iiif[:region][:w]
      reduction_factor = (region_width / @sizer[:w])
    else
      region_height = @iiif[:region] == 'full' ? @informer.height : @iiif[:region][:h]
      reduction_factor = (region_height / @sizer[:h])
    end

    scale_factors = @informer.scale_factors.reverse()
    reduction_scale_matches = []
    current_level = scale_factors.length - 1
    scale_factors.each_with_index do |scale_factor, index|
      scale_factor_reduction = {
        scale_factor: scale_factor,
        reduction: current_level
      }
      reduction_scale_matches << scale_factor_reduction
      current_level -= 1
    end

    # select every reduction_scale_match that is the same or larger than our
    # reduction_factor
    same_or_bigger = reduction_scale_matches.select do |rsm|
      reduction_factor >= rsm[:scale_factor]
    end

    # Pick the first one that matches as the reduction. But if there is none
    # that are bigger then our size
    if same_or_bigger.length > 0
      same_or_bigger[0][:reduction]
    else
      0
    end

  end

end
