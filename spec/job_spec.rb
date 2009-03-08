$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'rubygems'
require 'spec'
require 'jack'

describe Jack::Job do
  it 'should convert jobid to an integer' do
    j = Jack::Job.new(nil, "1", "body")
    j.jobid.class.should == Fixnum
  end
  
  it 'should send a delete command to the connection' do
    conn = mock(:conn)
    
    j = Jack::Job.new(conn, 1, "body")
    
    conn.should_receive(:delete).with(j)
    
    j.delete
  end
end