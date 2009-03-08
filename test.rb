$:.unshift("lib")

require 'rubygems'
require 'eventmachine'
require 'jack'

class KeyboardHandler < EM::Connection
  include EM::Protocols::LineText2
  
  def post_init
    @jack = Jack::Connection.new
  end
    
  def receive_line(line)
    line.chomp!
    
    case(line)
    when /^\s*$/ then
      return
      
    when /^use / then
      tube = line.gsub(/use /, '')
      df = @jack.use(tube)
      df.callback { |tube| puts "Using #{tube}" } unless df.nil?
      
    when /^watch / then
      tube = line.gsub(/watch /, '')
      df = @jack.watch(tube)
      df.callback { |tube| puts "Watching #{tube}" } unless df.nil?
      
    when /^put / then
      msg = line.gsub(/put /, '')
      df = @jack.put(msg)
      df.callback { |id| puts "Inserted job #{id}" }
      
    when /^delete / then
      id = line.gsub(/delete /, '').to_i
      job = Jack::Job.new(@jack, id, "asdf", 12)
      df = job.delete
      df.callback { puts "Deleted" }
      
    when 'reserve' then
      df = @jack.reserve
      df.callback { |job| puts "Reserved #{job}" }
      
    when 'help' then
      msg = "COMMANDS:\n"
      msg << "  put <msg>    - put message onto beanstalk\n"
      msg << "  delete <id>  - delete message with ID <id>\n"
      msg << "  reserve      - reserve a job on beanstalk\n"
      msg << "  use <tube>   - use tube for messages\n"
      msg << "  watch <tube> - add <tube to watch list for messages\n"
      msg << "  help         - this help text\n"
      msg << "  quit         - quit application\n"

      puts msg
    
    when 'quit' then
      EM.stop_event_loop
    end
  end
end

EM.run do
  EM.open_keyboard(KeyboardHandler)
end