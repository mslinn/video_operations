require 'colorator'
require 'fileutils'
require 'optparse'
require 'tempfile'

# Require all Ruby files in 'lib/', except this file
Dir[File.join(__dir__, '*.rb')].each do |file|
  unless file.end_with? File.basename(__FILE__)
    # puts "Requiring #{file}"
    require file
  end
end

# Ffmpeg's `deshake` filter can be used for a single-pass shake removal.
# This script does not do that.
# Instead, better results are obtained by running the ffmpeg vidstab library in two passes.
#
# In the first pass, the vidstabdetect filter analysing the video frames and generates a `transforms file`.
# This file contains stabilization data, consisting of translation and rotation transformations.
# By default, the generated transforms file is saved to `transforms.trf`; the `result` option specifies another path.
#
# Options:
#   shakiness: Set the shakiness of input video or quickness of camera.
#              Default value is 5.
#              Value range 1 (little shakiness) to 10 (very shaky).
#
# The second pass uses `transforms.trf` to produce a stable video output.
# Use ffmpeg's unsharp filter for best results.
# Options:
#
#   smoothing: Set the number of frames used for lowpass filtering the camera movements.
#              Default value: 10.
#              Recommended value: videoFPS / 2
#              The number of frames is computed from (value*2 + 1)
#              For example, a number of 10 means that 21 frames are used (10 previous frames and 10 following frames) to smoothen the video.
#              Larger values lead to smoother videos, but limit the acceleration of the camera (pan/tilt movements).
#
#        zoom: Set percentage to zoom the video.
#              Default value is 0 (no zoom).
#              A positive value results in a zoom-in effect; a negative value results in a zoom-out effect.
#
# Syntax:
# stabilize filename
#
# Stage 1 (vidstabdetect filter)
# The `-f null -` option tells ffmpeg to suppress the generation of an output video file
# ffmpeg "$INPUT" -vf vidstabdetect $SUPPRESS_OUTPUT
#
# Analyze strongly shaky video and putting the results in file mytransforms.trf:
# ffmpeg "$INPUT" -vf vidstabdetect=shakiness=10:${TRANSFORM_RESULTS} $SUPPRESS_OUTPUT
# TODO: read from stdin if pipe detected
# TODO: send to stdout if pipe detected
class VideoOperations
  SUPPRESS_OUTPUT = '-f null -'.freeze

  include Arithmetic
  include MSUtil
  include Run

  def initialize(video_in, video_out, **options)
    @options   = options
    @loglevel  = "-loglevel #{options[:loglevel]}"
    @loglevel += ' -stats' unless options[:loglevel] == 'quiet'
    @shakiness = "shakiness=#{options[:shake]}"
    @video_in  = MSUtil.expand_env video_in
    @video_out = MSUtil.expand_env video_out
    unless File.exist?(@video_in)
      printf "Error: file #{@video_in} does not exist.\n"
      exit 2
    end
    unless File.readable? @video_in
      printf "Error: #{@video_in} cannot be read.\n"
      exit 2
    end
    return unless File.exist?(@video_out) && !options.key?(:overwrite)

    printf "Error: #{@video_out} already exists.\n"
    exit 3
  end

  def flip(hflip: false, vflip: true)
    flips = 'hflip' if hflip
    flips += ',' if hflip && vflip
    flips += 'vflip' if vflip
    command = <<~END_CMD
      ffmpeg -y #{@loglevel} -i "#{@video_in}" -vf '#{flips}' "#{@video_out}"
    END_CMD
    run command
  end

  # To rotate and re-encode:
  # ffmpeg -y #{@loglevel} -i "#{@video_in}" -vf "rotate=#{rotation}" "#{@video_out}"
  # To rotate without re-encoding:
  # ffmpeg -y #{@loglevel} -i "#{@video_in}" -metadata:s:v rotate="#{rotation}" -codec copy "#{@video_out}"
  def rotate(degrees)
    rotation = (degrees % 90).zero? ? "PI*#{degrees.to_i / 90}:bilinear=0:oh=iw:ow=ih" : "#{degrees}*(PI/180)"
    command = <<~END_CMD
      ffmpeg -y #{@loglevel} -i "#{@video_in}" -metadata:s:v rotate="#{rotation}" -acodec copy "#{@video_out}"
    END_CMD
    run command
  end

  # Perform stage 2 (vidstabtransform filter)
  def smooth(smooth, path)
    tx_path = "input=#{path}"
    command = <<~END_CMD
      ffmpeg -y #{@loglevel} -i "#{@video_in}" -vf vidstabtransform=#{smooth}:zoom=5:#{tx_path} "#{@video_out}"
    END_CMD
    run command
  end

  def stabilize
    smooth = compute_smoothing
    Tempfile.open('transforms', '/tmp') do |fio|
      analyze_video(@shakiness, fio.path)
      smooth(@input, smooth, fio.path)
    end
  end

  private

  # Analyze a video and store results in temporary file
  def analyze_video(shakiness, path)
    tx_path = "result=#{path}"
    command = <<~END_CMD
      ffmpeg #{@loglevel} -i "#{@video_in}" -vf vidstabdetect=#{shakiness}:#{tx_path} #{SUPPRESS_OUTPUT}
    END_CMD
    run command
  end

  # Perform stage 1
  # fps / 2 yields smoothing value
  def compute_smoothing
    command = <<~END_CMD
      ffprobe -v error -select_streams v:0 -show_entries stream=avg_frame_rate -of default=nw=1:nk=1 -i "#{@video_in}"
    END_CMD
    fraction = run_capture_stdout(command).first

    result = calculate "#{fraction}/2"
    "smoothing=#{result.to_i}"
  end
end
