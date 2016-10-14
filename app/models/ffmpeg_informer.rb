class FfmpegInformer

  attr_reader :file, :info

  def initialize(file)
    @file = file
    get_info
  end

  def get_info
    Rails.logger.info ffmpeg_info_cmd
    result = `#{ffmpeg_info_cmd}`

    @info = JSON.parse result
  end

  def width
    video_stream['width']
  end

  def height
    video_stream['height']
  end

  def duration
    @info['format']['duration']
  end

  def frames
    video_stream['nb_frames']
  end

  # TODO: this could look at the format in the info and not rely on extension
  def format
    File.extname(@file).sub('.','')
  end

  def mimetype
    case format
    when 'mp4'
      'video/mp4'
    when 'webm'
      'video/webm'
    end
  end

  def mimetype_with_codecs
    # %Q|#{mimetype}; codecs="#{codecs_string}"|
    mimetype
  end

  def codecs
    [video_codec, audio_codec].compact
  end

  def codecs_string
    codecs.join(',')
  end

  # TODO: use mp4file to get more specific codecs for mp4
  # http://stackoverflow.com/questions/16363167/html5-video-tag-codecs-attribute
  def video_codec
    if video_stream
      if video_stream['codec_name'] == 'h264'
        video_stream['codec_tag_string']
      else
        video_stream['codec_name']
      end
    end
  end

  def audio_codec
    if audio_stream
      if audio_stream['codec_name']== 'aac'
        audio_stream['codec_tag_string']
      else
        audio_stream['codec_name']
      end
    end
  end

  def video_stream
    @info['streams'].find do |stream|
      stream['codec_type'] == 'video'
    end
  end

  def audio_stream
    @info['streams'].find do |stream|
      stream['codec_type'] == 'audio'
    end
  end

  def size
    @info['format']['size']
  end

  def ffmpeg_info_cmd
    # TODO: add -show_data for extradata which might have more codec information?
    "ffprobe -v error -print_format json -show_format -show_streams #{@file}"
  end

end
