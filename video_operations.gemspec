require_relative 'lib/video_operations/version'

Gem::Specification.new do |spec|
  host = 'https://github.com/mslinn/video_operations'

  spec.authors               = ['Mike Slinn']
  spec.bindir                = 'exe'
  spec.executables           = %w[rotate stabilize]
  spec.description           = <<~END_DESC
    Can rotate a video, or stabilize it using FFmpeg's vidstabdetect and vidstabtransform filters.
  END_DESC
  spec.email                 = ['mslinn@mslinn.com']
  spec.files                 = Dir['.rubocop.yml', 'LICENSE.*', 'Rakefile', '{lib,spec}/**/*', '*.gemspec', '*.md']
  spec.homepage              = 'https://github.com/mslinn/video_operations'
  spec.license               = 'MIT'
  spec.metadata = {
    'allowed_push_host' => 'https://rubygems.org',
    'bug_tracker_uri'   => "#{host}/issues",
    'changelog_uri'     => "#{host}/CHANGELOG.md",
    'homepage_uri'      => spec.homepage,
    'source_code_uri'   => host,
  }
  spec.name                 = 'video_operations'
  spec.post_install_message = <<~END_MESSAGE

    Thanks for installing #{spec.name}!

  END_MESSAGE
  spec.require_paths         = ['lib']
  spec.required_ruby_version = '>= 3.0.0'
  spec.summary               = 'Can rotate a video, or stabilize it using FFmpeg\'s vidstabdetect and vidstabtransform filters.'
  spec.version               = StabilizeVideo::VERSION
  spec.add_dependency 'colorator', '~> 1.1'
  spec.add_dependency 'optparse'
end
