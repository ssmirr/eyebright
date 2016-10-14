class VideosController < ApplicationController

  # before_action :validate_request, only: [:show]

  def show
    video_filepath = VideoResolver.path(params[:id]) 
    if File.exist? video_filepath
      extractor = VideoImageExtractor.new(request, params)
      image_path = extractor.extract

      if File.size? image_path
        FileUtils.mkdir_p image_cache_directory
        FileUtils.mv image_path, image_cache_file_path
        FileUtils.chmod_R "ugo=rwX", image_cache_directory

        send_file image_cache_file_path, type: Mime::Type.lookup_by_extension(params[:format]), disposition: 'inline'
      else
        head 500
      end
    else
      head 404
    end
  end

  def info
    # If this route is hit then the info.json is not cached to the filesystem.
    # The informer takes the fastest path to getting the information.
    @informer = VideoInformer.new params[:id], request.base_url
    @informer.inform

    content_type = if request.format.to_s == 'application/ld+json'
      'application/ld+json'
    else
      'application/json'
    end

    json = @informer.iiif_info.to_json
    render json: json, content_type: content_type
  end

  def image_info
    @informer = VideoStillInformer.new params[:id], params[:time]
    @informer.inform

    content_type = if request.format.to_s == 'application/ld+json'
      'application/ld+json'
    else
      'application/json'
    end
    json = @informer.iiif_info.to_json
    render json: json, content_type: content_type
  end

  def viewer
  end

  private

  def identifier_directory
    File.join Rails.root, "public/iiifv/#{params[:id]}"
  end

  def image_cache_directory
    File.join(identifier_directory, "/#{params[:time]}/#{params[:region]}/#{params[:size]}/#{params[:rotation]}")
  end

  def image_cache_file_path
    File.join(image_cache_directory, "#{params[:quality]}.#{params[:format]}")
  end



  # def info_cache_directory
  #   identifier_directory
  # end
  #
  # def info_cache_file_path
  #   File.join info_cache_directory, 'info.json'
  # end
  #
  # def validate_request
  #   validator = IiifRequestValidator.new(request.path)
  #   if !validator.valid?
  #     head 400
  #     return
  #   end
  # end

end
