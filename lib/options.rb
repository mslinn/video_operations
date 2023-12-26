require 'colorator'
require 'optparse'

VERBOSITY = %w[trace debug verbose info warning error fatal panic quiet].freeze

def help(msg = nil)
  printf "Error: #{msg}\n\n".yellow unless msg.nil?
  printf 'Commands are: flip, rotate and stabilize'
  exit 1
end

def help_flip(msg = nil)
  printf "Error: #{msg}\n\n".yellow unless msg.nil?
  msg = <<~END_HELP
    flip: Flips a video using FFmpeg.

    Syntax: flip PATH_TO_VIDEO AXIS

    AXIS can be 'h' (horizontal) or 'v' (vertical)
  END_HELP
  printf msg.cyan
  exit 1
end

def help_rotate(msg = nil)
  printf "Error: #{msg}\n\n".yellow unless msg.nil?
  msg = <<~END_HELP
    rotate: Rotates a video using FFmpeg.

    Syntax: rotate PATH_TO_VIDEO DEGREES

    Options:
      -f Overwrite output file if present
      -h Show this help message
      -v Verbosity; one of: #{VERBOSITY.join ', '}
  END_HELP
  printf msg.cyan
  exit 1
end

def help_stabilize(msg = nil)
  printf "Error: #{msg}\n\n".yellow unless msg.nil?
  msg = <<~END_HELP
    stabilize: Stabilizes a video using the FFmpeg vidstabdetect and vidstabtransform filters.

    Syntax: stabilize [Options] PATH_TO_VIDEO

    Options:
      -f Overwrite output file if present
      -h Show this help message
      -s Shakiness compensation 1..10 (default 5)
      -v Verbosity; one of: #{VERBOSITY.join ', '}
      -z Zoom percentage (computed if not specified)

    See:
      https://www.ffmpeg.org/ffmpeg-filters.html#vidstabdetect-1
      https://www.ffmpeg.org/ffmpeg-filters.html#toc-vidstabtransform-1
  END_HELP
  printf msg.cyan
  exit 1
end

def parse_options(command)
  options = option_defaults command
  opts = do_parse command
  begin
    opts.order!(into: options)
  rescue OptionParser::InvalidOption => e # Handle negative rotation values, which look like options
    raise e unless command == :rotate

    begin
      !Float(ARGV[0]).nil? # If not a negative number then this is an invalid option
    rescue StandardError
      raise e
    end
  end

  help_stabilize "Invalid verbosity value (#{options[:verbose]}), must be one of one of: #{VERBOSITY.join ', '}." \
    if options[:verbose] && !options[:verbose] in VERBOSITY

  help_stabilize "Invalid shake value (#{options[:shake]})." \
    if command == :stabilize && (options[:shake].negative? || options[:shake] > 10)

  options
end

private

def option_defaults(command)
  case command
  when :flip, :rotate
    { loglevel: 'warning' }
  when :stabilize
    { shake: 5, loglevel: 'warning' }
  else
    help 'Error: Unknown command'
  end
end

def do_parse(command)
  OptionParser.new do |parser|
    parser.program_name = File.basename __FILE__
    @parser = parser

    parser.on('-f', '--overwrite', 'Overwrite output file if present')
    parser.on('-l', '--loglevel LOGLEVEL', Integer, "Logging level (#{VERBOSITY.join ', '})")
    parser.on('-v', '--verbose VERBOSE', 'Zoom percentage')

    case command
    when :flip
    # No options
    when :stabilize
      parser.on('-s', '--shake SHAKE', Integer, 'Shakiness (1..10)')
      parser.on('-z', '--zoom ZOOM', Integer, 'Zoom percentage')
    when :rotate
    # No options
    else
      help 'Error: Unknown command'
    end

    parser.on_tail('-h', '--help', 'Show this message') do
      command == :stabilize ? help_stabilize : help_rotate
    end
  end
end
