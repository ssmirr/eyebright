class ImagesController < ApplicationController

  def show
    first_two = params[:id][0,2]
    # jp2_filepath = "/access-images/jp2s/#{first_two}/#{params[:id]}.jp2"
    jp2_filepath = Resolver.path(params[:id])

    if File.exist? jp2_filepath
      extractor = Extractor.new(request.original_url, params)
      image_path = extractor.extract

      if File.size? image_path
        FileUtils.mkdir_p image_cache_file_directory
        FileUtils.mv image_path, image_cache_file_path
        FileUtils.chmod_R "ugo=rwX", image_cache_file_directory

        send_file image_cache_file_path, type: Mime::Type.lookup_by_extension(params[:format]), disposition: 'inline'
      else
        render status: 500
      end
    else
      render status: 404
    end
  end

  def info
    @informer = Informer.new params[:id]
    @informer.inform
    id_url = File.join("#{request.protocol}#{request.host_with_port}", 'iiif', params[:id])
    render json: @informer.info(id_url).to_json
  end

  private

  def image_cache_file_directory
    File.join(Rails.root, "public/iiif/#{params[:id]}/#{params[:region]}/#{params[:size]}/#{params[:rotation]}")
  end

  def image_cache_file_path
    File.join(image_cache_file_directory, "#{params[:quality]}.#{params[:format]}")
  end
end
