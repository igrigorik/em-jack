$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'rubygems'
require 'spec'
require 'em-jack'

describe EMJack::Job do
  before(:each) do
    @conn = mock(:conn)
  end

  it 'converts jobid to an integer' do
    j = EMJack::Job.new(nil, "1", "body")
    j.jobid.class.should == Fixnum
    j.jobid.should == 1
  end
  
  it 'sends a delete command to the connection' do
    j = EMJack::Job.new(@conn, 1, "body")
    @conn.should_receive(:delete).with(j)
    
    j.delete
  end

  it 'sends a stats command to the connection' do
    j = EMJack::Job.new(@conn, 2, 'body')
    @conn.should_receive(:stats).with(:job, j)

    j.stats
  end

  it 'sends a release command to the connection' do
    blk = Proc.new { x = 1 }

    j = EMJack::Job.new(@conn, 2, 'body')
    @conn.should_receive(:release).with(j, {:foo => :bar}, &blk)

    j.release({:foo => :bar}, &blk)
  end
end