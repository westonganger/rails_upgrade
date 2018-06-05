lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rails_upgrade/version.rb'

Gem::Specification.new do |s|
  s.name        = 'rails_upgrade'
  s.version     =  RailsUpgrade::VERSION
  s.author	= "Weston Ganger"
  s.email       = 'weston@westonganger.com'
  s.homepage 	= 'https://github.com/westonganger/rails_upgrade'
  
  s.summary     = "Command line tool for cleaning up & upgrading Rails applications"
  s.description = "Command line tool for cleaning up & upgrading Rails applications"
  s.files = Dir.glob("{lib/**/*}") + %w{ LICENSE README.md Rakefile CHANGELOG.md }
  s.test_files  = Dir.glob("{test/**/*}")

  s.add_dependency 'ruby2ruby'
  s.add_dependency 'ruby_parser'
  s.add_dependency 'logging'
  s.add_dependency 'commander'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'bundler'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'activerecord'

  s.required_ruby_version = '>= 1.9'
  s.require_path = 'lib'
end
