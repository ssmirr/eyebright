# TODO: This could use a better 
module Converter

  def convert_cmd
    cmd = base_convert_cmd

    if @iiif[:quality] == 'pixelized'
      cmd << ' -scale 10% -scale 1000%'
    end

    if convert_resize
      cmd << " -resize #{convert_resize} "
    end

    if @iiif[:rotation][:mirror]
      degrees = @iiif[:rotation][:degrees]
      cmd << if degrees == 0 || degrees == 180
        " -flop"
      elsif degrees == 90 || degrees == 270
        " -flip"
      end
    end

    if @iiif[:rotation][:degrees] != 0
      if ![90, 180, 270].any?{|degree| degree == @iiif[:rotation][:degrees]}
        cmd << " -virtual-pixel white"
      end
      # cmd << " -distort SRT #{@iiif[:rotation][:degrees]}"
      cmd << " -rotate #{@iiif[:rotation][:degrees]}"
    end

    case @iiif[:quality]
    when 'gray'
      cmd << ' -colorspace Gray'
    when 'bitonal'
      cmd << ' -colorspace Gray'
      cmd << ' -type Bilevel'
    when 'dither'
      # TODO: add other dither options
      cmd << ' -dither FloydSteinberg -colors 8'
    when 'negative'
      cmd << ' -negate'
    when 'paint'
      cmd << ' -paint 5'
    end

    cmd << " #{@temp_response_image.path}"
    puts cmd
    cmd
  end


  def enrich_iiif_params
    if @iiif[:region].is_a?(Hash) && @iiif[:region].key?(:pctx) && !@iiif[:region].key?(:x)
      # calculate x,y,w,h and enrich the params with what we find
      @iiif[:region][:x] = (@informer.width * (@iiif[:region][:pctx]/100)).round
      @iiif[:region][:y] = (@informer.height * (@iiif[:region][:pcty]/100)).round
      @iiif[:region][:w] = (@informer.width * (@iiif[:region][:pctw]/100)).round
      @iiif[:region][:h] = (@informer.height * (@iiif[:region][:pcth]/100)).round
    end

    if square?
      if @informer.width == @informer.height
        # image is square already
        x = 0
        y = 0
        w = @informer.width
        h = @informer.width
      elsif @informer.width < @informer.height
        # image is portrait
        x = 0
        w = @informer.width
        h = @informer.width
        case @iiif[:region]
        when 'square'
          # y will be minus half the width from the centerpoint
          centery = (@informer.height/2).round
          halfwidth = (@informer.width/2).round
          y = centery - halfwidth
        when '!square'
          # top gravity
          y = 0
        when 'square!'
          # bottom gravity
          y = @informer.height - @informer.width
        end

      elsif @informer.width > @informer.height
        # orientation is landscape
        y = 0
        w = @informer.height
        h = @informer.height
        case @iiif[:region]
        when 'square'
          # x will be minus half the height from the centerpoint
          centerx = (@informer.width/2).round
          halfheight = (@informer.height/2).round
          x = centerx - halfheight
        when '!square'
          # top gravity
          x = 0
        when 'square!'
          # bottom gravity
          x = @informer.width - @informer.height
        end
      end

      @iiif[:region] = {}
      @iiif[:region][:x] = x
      @iiif[:region][:y] = y
      @iiif[:region][:w] = w
      @iiif[:region][:h] = h
      @iiif[:region][:region_type] = 'regionSquare'
    end

    # TODO: If @iiif size is pct enrich
    if @iiif[:size].is_a?(Hash) && @iiif[:size][:pct]
      # determine size of original resulting image
      region_width = if @iiif[:region] == 'full'
        @informer.width
      else
        @iiif[:region][:w]
      end
      # determine the final size that we want for the image
      percent_factor = @iiif[:size][:pct] / 100
      @iiif[:size][:w] = (region_width * percent_factor).round
    end

  end # end enrich_iiif_params


  def square?
    if @iiif[:region] == 'full'
      false
    else
      ['square', '!square', 'square!'].any?{|sq| sq == @iiif[:region]} ||
      @iiif[:region][:region_type] == 'regionSquare'
    end
  end

  def convert_resize
    size = @iiif[:size]
    if size == 'full'
      nil
    elsif !size[:w] && size[:h]
      "x#{size[:h]}"
    elsif size[:w] && !size[:h]
      "#{size[:w]}"
    elsif size[:w] && size[:h]
      if size[:confined]
        "#{size[:w]}x#{size[:h]}"
      else
        "#{size[:w]}x#{size[:h]}!"
      end
    end
  end

end
