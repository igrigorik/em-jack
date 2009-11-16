$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'rubygems'
require 'spec'
require 'em-jack'

describe EMJack::Job do
  before(:each) do
    @conn = mock(:conn)
  end

  it 'should convert jobid to an integer' do
    j = EMJack::Job.new(nil, "1", "body")
    j.jobid.class.should == Fixnum
    j.jobid.should == 1
  end
  
  it 'should send a delete command to the connection' do
    j = EMJack::Job.new(@conn, 1, "body")
    @conn.should_receive(:delete).with(j)
    
    j.delete
  end

  it 'should send a stats command to the connection' do
    j = EMJack::Job.new(@conn, 2, 'body')
    @conn.should_receive(:stats).with(:job, j)

    j.stats
  end
end