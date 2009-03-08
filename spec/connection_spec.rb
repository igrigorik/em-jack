$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'rubygems'
require 'spec'

require 'jack'

describe Jack::Connection do
  before(:each) do
    @connection_mock = mock(:conn)
    EM.should_receive(:connect).and_return(@connection_mock)
  end
  
  it 'should use a default host of "localhost"' do
    conn = Jack::Connection.new
    conn.host.should == 'localhost'
  end
  
  it 'should use a default port of 11300' do
    conn = Jack::Connection.new
    conn.port.should == 11300    
  end
  
  it 'should watch and use a provided tube on connect' do
    @connection_mock.should_receive(:send).once.with(:use, "mytube")
    @connection_mock.should_receive(:send).once.with(:watch, "mytube")
    conn = Jack::Connection.new(:tube => "mytube")
  end
  
  it 'should send the "use" command' do
    @connection_mock.should_receive(:send).once.with(:use, "mytube")
    conn = Jack::Connection.new
    conn.use("mytube")
  end
  
  it 'should not send the use command to the currently used tube' do
    @connection_mock.should_receive(:send).once.with(:use, "mytube")
    conn = Jack::Connection.new
    conn.use("mytube")
    conn.use("mytube")
  end
  
  it 'should send the "watch" command' do
    @connection_mock.should_receive(:send).once.with(:watch, "mytube")
    conn = Jack::Connection.new
    conn.watch("mytube")
  end
  
  it 'should not send the watch command for a tube currently watched' do
    @connection_mock.should_receive(:send).once.with(:watch, "mytube")
    conn = Jack::Connection.new
    conn.watch("mytube")
    conn.watch("mytube")
  end
  
  it 'should send the "put" command' do
    msg = "my message"
    @connection_mock.should_receive(:send_with_data).once.
                      with(:put, msg, anything, anything, anything, msg.length)
    conn = Jack::Connection.new
    conn.put(msg)
  end
  
  it 'should default the delay, priority and ttr settings' do
    @connection_mock.should_receive(:send_with_data).once.
                      with(:put, anything, 65536, 0, 300, anything)
    conn = Jack::Connection.new
    conn.put("msg")
  end
  
  it 'should accept a delay setting' do
    @connection_mock.should_receive(:send_with_data).once.
                      with(:put, anything, anything, 42, anything, anything)
    conn = Jack::Connection.new
    conn.put("msg", :delay => 42)
  end
  
  it 'should accept a ttr setting' do
    @connection_mock.should_receive(:send_with_data).once.
                      with(:put, anything, anything, anything, 999, anything)
    conn = Jack::Connection.new
    conn.put("msg", :ttr => 999)
  end
  
  it 'should accept a priority setting' do
    @connection_mock.should_receive(:send_with_data).once.
                      with(:put, anything, 233, anything, anything, anything)
    conn = Jack::Connection.new
    conn.put("msg", :priority => 233)
  end
  
  it 'shoudl accept a priority, delay and ttr setting' do
    @connection_mock.should_receive(:send_with_data).once.
                      with(:put, anything, 99, 42, 2000, anything)
    conn = Jack::Connection.new
    conn.put("msg", :priority => 99, :delay => 42, :ttr => 2000)
  end
  
  it 'should force delay to be >= 0' do
    @connection_mock.should_receive(:send_with_data).once.
                      with(:put, anything, anything, 0, anything, anything)
    conn = Jack::Connection.new
    conn.put("msg", :delay => -42)
  end
  
  it 'should force ttr to be >= 0' do
    @connection_mock.should_receive(:send_with_data).once.
                      with(:put, anything, anything, anything, 300, anything)
    conn = Jack::Connection.new
    conn.put("msg", :ttr => -42)
  end
  
  it 'should force priority to be >= 0' do
    @connection_mock.should_receive(:send_with_data).once.
                      with(:put, anything, 65536, anything, anything, anything)
    conn = Jack::Connection.new
    conn.put("msg", :priority => -42)
  end
  
  it 'should force priority to be < 2**32' do
    @connection_mock.should_receive(:send_with_data).once.
                      with(:put, anything, (2 ** 32), anything, anything, anything)
    conn = Jack::Connection.new
    conn.put("msg", :priority => (2 ** 32 + 1))
  end
  
  it 'should handle a non-string provided as the put message' do
    msg = 22
    @connection_mock.should_receive(:send_with_data).once.
                      with(:put, msg.to_s, anything, anything, anything, msg.to_s.length)
    conn = Jack::Connection.new
    conn.put(msg) 
  end
  
  it 'should send the "delete" command' do
    @connection_mock.should_receive(:send).once.with(:delete, 1)
    job = Jack::Job.new(nil, 1, "body", 40)
    conn = Jack::Connection.new
    conn.delete(job)
  end
  
  it 'should handle a nil job sent to the "delete" command' do
    @connection_mock.should_not_receive(:send).with(:delete, nil)
    conn = Jack::Connection.new
    conn.delete(nil)
  end
  
  it 'should send the "reserve" command' do
    @connection_mock.should_receive(:send).with(:reserve)
    conn = Jack::Connection.new
    conn.reserve
  end
end