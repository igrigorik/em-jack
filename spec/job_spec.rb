$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'rubygems'
require 'spec'
require 'jack'

describe Jack::Job do
  it 'should convert jobid to an integer' do
    j = Jack::Job.new(nil, 1, "body", "40")
    j.ttr.class.should == Fixnum
  end
  
  it 'should convert ttr to an integer' do
    j = Jack::Job.new(nil, "1", "body", 40)
    j.jobid.class.should == Fixnum
  end
  
  it 'should send a delete command to the connection' do
    conn = mock(:conn)
    conn.should_receive(:delete).with(1)
    
    j = Jack::Job.new(conn, 1, "body", 40)
    j.delete
  end
end