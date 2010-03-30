$:.unshift(File.dirname(__FILE__))

require 'em-jack/job'
require 'em-jack/errors'
require 'em-jack/beanstalk_connection'
require 'em-jack/connection'

Dir["#{File.dirname(__FILE__)}/em-jack/handlers/*.rb"].each do |file|
  require file
end

module EMJack
  module VERSION
    STRING = '0.1.0'
  end
end
