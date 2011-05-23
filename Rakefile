require 'bundler'
require 'bundler/setup'
require 'bundler/gem_helper'

Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new('spec') do |t|
  t.verbose = false
end
