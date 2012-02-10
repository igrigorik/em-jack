# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$:.unshift(lib) unless $:.include?(lib)

require 'em-jack/version'

Gem::Specification.new do |s|
  s.name        = 'em-jack'
  s.version     = EMJack::VERSION
  s.authors     = ['Dan Sinclair']
  s.email       = ['dj2@everburning.com']
  s.homepage    = 'https://github.com/dj2/em-jack/'
  s.summary     = 'An evented Beanstalk client'
  s.description = 'An evented Beanstalk client'

  s.required_rubygems_version = '>= 1.3.6'

  s.add_dependency 'eventmachine', ['>= 0.12.10']

  s.add_development_dependency 'bundler', ['~> 1.0.13']
  s.add_development_dependency 'rake',    ['>= 0.8.7']
  s.add_development_dependency 'rspec',   ['~> 2.6']

  s.files        = `git ls-files`.split("\n")
  s.test_files   = `git ls-files -- {spec}/*`.split("\n")
  s.require_path = 'lib'
end
