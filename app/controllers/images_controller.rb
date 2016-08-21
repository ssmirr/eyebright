class ImagesController < ApplicationController

  before_filter :validate_request, only: [:show]

  def show
    jp2_filepath = Resolver.path(params[:id])
    if File.exist? jp2_filepath
      extractor = Extractor.new(request.original_url, params)
      image_path = extractor.extract

      if File.size? image_path
        FileUtils.mkdir_p image_cache_directory
        FileUtils.mv image_path, image_cache_file_path
        FileUtils.chmod_R "ugo=rwX", image_cache_directory

        send_file image_cache_file_path, type: Mime::Type.lookup_by_extension(params[:format]), disposition: 'inline'
      else
        render nothing: true, status: 500
      end
    else
      render nothing: true, status: 404
    end
  end

  def info
    @informer = Informer.new params[:id]
    @informer.inform
    id_url = File.join("#{request.protocol}#{request.host_with_port}", 'iiif', params[:id])

    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST, PUT, DELETE, GET, OPTIONS'
    headers['Access-Control-Request-Method'] = '*'
    headers['Access-Control-Allow-Headers'] = 'Origin, X-Requested-With, Content-Type, Accept, Authorization'

    content_type = if request.format.to_s == 'application/ld+json'
      'application/ld+json'
    else
      'application/json'
    end

    json = @informer.info.to_json
    render json: json, content_type: content_type
  end

  private

  def identifier_directory
    File.join Rails.root, "public/iiif/#{params[:id]}"
  end

  def image_cache_directory
    File.join(identifier_directory, "/#{params[:region]}/#{params[:size]}/#{params[:rotation]}")
  end

  def image_cache_file_path
    File.join(image_cache_directory, "#{params[:quality]}.#{params[:format]}")
  end

  def info_cache_directory
    identifier_directory
  end

  def info_cache_file_path
    File.join info_cache_directory, 'info.json'
  end

  def validate_request
    validator = IiifRequestValidator.new(request.original_url)
    if !validator.valid?
      render nothing: true, status: 400
      return
    end
  end

end
