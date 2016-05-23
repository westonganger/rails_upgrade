require File.join(File.dirname(__FILE__), 'lib/rails_upgrade/version.rb')
require 'bundler/gem_tasks'

task :test do 
  require 'rake/testtask'
  Rake::TestTask.new do |t|
    t.libs << 'test'
    t.test_files = FileList['test/**/tc_*.rb']
    t.verbose = true
  end
end

task default: :test
