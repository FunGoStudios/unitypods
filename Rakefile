require 'rubygems'
require 'rspec/core/rake_task'
begin
  require 'unitypods/version'
rescue LoadError
  require_relative 'lib/unitypods/version'
end

RSpec::Core::RakeTask.new
task :default => :spec

desc "Build the gem"
task :build do
  system "gem build unitypods.gemspec"
end

desc "Build and install the gem"
task :install_local => :build do
  system "gem install -l unitypods-#{Unitypods::VERSION}.gem"
end
