$:.unshift(File.dirname(__FILE__))

require 'em-jack/job'
require 'em-jack/errors'
require 'em-jack/beanstalk_connection'
require 'em-jack/connection'

module EMJack
  module VERSION
    STRING = '0.0.4'
  end
end
