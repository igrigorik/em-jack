$:.unshift(File.dirname(__FILE__))

require 'jack/job'
require 'jack/errors'
require 'jack/beanstalk_connection'
require 'jack/connection'

module Jack
  module VERSION
    STRING = '0.0.1'
  end
end