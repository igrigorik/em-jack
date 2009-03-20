$:.unshift("lib")

require 'rubygems'
require 'eventmachine'
require 'jack'
require 'pp'

$stdout.sync = true

class KeyboardHandler < EM::Connection
  include EM::Protocols::LineText2
  
  def post_init
    @jack = Jack::Connection.new

    print "> "
  end
    
  def receive_line(line)
    line.chomp!
    line.gsub!(/^\s+/, '')

    df = case(line)
    when /^\s*$/ then
      # noop
      nil
      
    when /^use / then
      tube = line.gsub(/use /, '')
      df = @jack.use(tube)
      df.callback { |tube| puts "Using #{tube}" } unless df.nil?
      df
      
    when /^watch / then
      tube = line.gsub(/watch /, '')
      df = @jack.watch(tube)
      df.callback { |tube| puts "Watching #{tube}" } unless df.nil?
      df
      
    when /^put / then
      msg = line.gsub(/put /, '')
      df = @jack.put(msg)
      df.callback { |id| puts "Inserted job #{id}" }
      df

    when /^delete / then
      id = line.gsub(/delete /, '').to_i
      job = Jack::Job.new(@jack, id, "asdf")
      df = job.delete
      df.callback { puts "Deleted" }
      df

    when 'reserve' then
      df = @jack.reserve
      df.callback { |job| puts "Reserved #{job}" }
      df

    when 'list-tubes' then
      df = @jack.list
      df.callback { |tubes| pp tubes }
      df

    when 'list-watched' then
      df = @jack.list(:watched)
      df.callback { |tubes| pp tubes }
      df

    when 'list-used' then
      df = @jack.list(:used)
      df.callback { |tube| puts "Using #{tube}" }
      df

    when 'stats' then
      df = @jack.stats
      df.callback { |stats| pp stats }
      df

    when /^stats-tube\s+(.*)$/ then
      df = @jack.stats(:tube, $1)
      df.callback { |stats| pp stats }
      df

    when /^stats-job\s+(\d+)/ then
      j = Jack::Job.new(@jack, $1, "blah")
      df = j.stats
      df.callback { |stats| pp stats }
      df

    when 'help' then
      msg = "COMMANDS:\n"
      msg << "  put <msg>    - put message onto beanstalk\n"
      msg << "  reserve      - reserve a job on beanstalk\n"
      msg << "  delete <id>  - delete message with ID <id>\n"
      msg << "\n"
      msg << "  use <tube>   - use tube for messages\n"
      msg << "  watch <tube> - add <tube to watch list for messages\n"
      msg << "\n"
      msg << "  stats        - display beanstalk stats\n"
      msg << "  stats-tube <tube> - display tube stats\n"
      msg << "  stats-job <id> - display job stats\n"
      msg << "\n"
      msg << "  list-tubes   - display beanstalk tubes\n"
      msg << "  list-used    - display the currently used tube\n"
      msg << "  list-watched - display the currently watched tubes\n"
      msg << "\n"
      msg << "  help         - this help text\n"
      msg << "  quit         - quit application\n"

      puts msg
      nil
    
    when 'quit' then
      EM.stop_event_loop
      nil
    end

    unless df.nil?
      df.callback { print "> " }
      df.errback { print "> " }
    end

    print "> "
  end
end

EM.run do
  EM.open_keyboard(KeyboardHandler)
end
