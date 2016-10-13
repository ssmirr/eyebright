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
    case File.extname @file
    when '.mp4'
      'video/mp4'
    when '.webm'
      'video/webm'
    end
  end

  def video_stream
    @info['streams'].find do |stream|
      stream['codec_type'] == 'video'
    end
  end

  def ffmpeg_info_cmd
    "ffprobe -v error -print_format json -show_format -show_streams #{@file}"
  end

end
