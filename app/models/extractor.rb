# Just a kdu extractor for now
class Extractor

  include Converter

  def initialize(url, params)
    @iiif = IiifUrl.parse url
    @params = params
    @path = Resolver.path @params[:id]
    get_informer
    enrich_iiif_params
    # FIXME: pick better temporary images
    @temp_out_image = Tempfile.new [@params[:id], '.tif']
    @temp_response_image = Tempfile.new [@params[:id], ".#{@params[:format]}"]
  end

  # We only need the width, height, and scale_factors in the extractor for our
  # calculations. So that's what we get back one way or another.
  def get_informer
    # If the information is in Memcache we use that. Otherwise we use an informer
    # to get the information from the image.
    mc_info = MDC.get @params[:id]
    if mc_info
      Rails.logger.info "Memcached Hit #{@params[:id]}"
      @informer = OpenStruct.new mc_info
    else
      @informer = Informer.new @params[:id]
      @informer.inform
    end
  end

  def extract
    if @iiif[:region] == 'full'
      top, left, height, width = [0, 0, @informer.height, @informer.width]
    else
      top, left, height, width = @iiif[:region][:y], @iiif[:region][:x], @iiif[:region][:h], @iiif[:region][:w]
    end

    @top_pct = top / @informer.height.to_f
    @left_pct = left / @informer.width.to_f
    @height_pct = height / @informer.height.to_f
    @width_pct = width / @informer.width.to_f

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

  def base_convert_cmd
    "convert #{@temp_out_image.path} "
  end

  def pick_reduction
    if @iiif[:size][:w]
      region_width = if @iiif[:region] == 'full'
          @informer.width
        else
          @iiif[:region][:w]
        end
      reduction_factor = (region_width / @iiif[:size][:w].to_f)
    else
      region_height = if @iiif[:region] == 'full'
          @informer.height
        else
          @iiif[:region][:h]
        end
      reduction_factor = (region_height / @iiif[:size][:h].to_f)
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
