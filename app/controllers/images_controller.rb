class ImagesController < ApplicationController

  def show
    first_two = params[:id][0,2]
    # jp2_filepath = "/access-images/jp2s/#{first_two}/#{params[:id]}.jp2"
    jp2_filepath = Resolver.path(params[:id])

    image_path = if File.exist? jp2_filepath
      extractor = Extractor.new(request.original_url, params)
      extractor.extract
    else
      File.join(Rails.root, "public/placeholder.#{params[:format]}")
    end

    send_file image_path,
      type: Mime::Type.lookup_by_extension(params[:format]),
              disposition: 'inline'

  end

  def info

  end

  private

  def image_cache_file_path
    File.join(Rails.root, "public/#{params[:id]}/#{params[:region]}/#{params[:size]}/#{params[:rotation]}/#{params[:quality]}.#{params[:format]}")
  end
end
