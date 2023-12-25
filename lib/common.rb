require 'colorator'
require_relative 'video_operations/version'
require_relative 'options'

# Require all Ruby files in 'lib/', except this file
Dir[File.join(__dir__, '*.rb')].each do |file|
  require file unless file.end_with?('/common.rb')
end

def common(command)
  @options = parse_options command
  help_stabilize 'Video file name must be provided.' if ARGV.empty?
end

def rotate
  common :rotate
  help_stabilize 'Degrees to rotate must be provided.' if ARGV.length == 1
  help_stabilize "Too many parameters specified.\n#{ARGV}" if ARGV.length > 2
  video_in = ARGV[0]
  degrees = ARGV[1].to_f
  video_out = "#{File.dirname video_in}/rotated_#{File.basename video_in}"
  VideoOperations.new(video_in, video_out, **@options).rotate(degrees)
rescue NoMethodError => e
  printf "Error: #{e.message} (perhaps you did not provide a numeric value for the rotation degrees?)"
  exit 4
end

def stabilize
  common :stabilize
  help_stabilize "Too many parameters specified.\n#{ARGV}" if ARGV.length > 1
  video_in = ARGV[0]
  video_out = "#{File.dirname video_in}/stabilized_#{File.basename video_in}"
  VideoOperations.new(video_in, video_out, **@options).stabilize
end
