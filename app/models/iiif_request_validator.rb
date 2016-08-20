class IiifRequestValidator

  def initialize(url)
    @url = url
    @iiif = IiifUrl.parse url
  end

  def valid?
    valid_region? &&
    valid_size? &&
    valid_rotation? &&
    valid_quality? &&
    valid_format?
  end

  def valid_region?
    if @iiif[:region].is_a? String
      ['full', 'square', '!square', 'square!'].any?{ |s| s == @iiif[:region] }
    else
      # TODO: does there need to be more here?
      true
    end
  end

  def valid_size?
    if @iiif[:size].is_a? String
      'full' == @iiif[:size]
    else
      # TODO: does there need to be more here?
      true
    end
  end

  def valid_rotation?
    if @iiif[:rotation].is_a? String
      false
    else
      true
    end
  end

  def valid_quality?
    ['default', 'color', 'gray', 'bitonal'].any?{|q| q == @iiif[:quality]}
  end

  def valid_format?
    ['jpg', 'png'].any?{|f| f == @iiif[:format]}
  end

end
