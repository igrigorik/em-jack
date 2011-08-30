require 'spec_helper'

if RUBY_VERSION > '1.9'
  require 'fiber'

  describe EMJack::Connection do
    it "should process live messages" do
      EM.run do
        EM.add_timer(10) { EM.stop }

        Fiber.new do
          bean = EMJack::Connection.new
          bean.fiber!

          bean.put("hello!")
          job = bean.reserve
          job.body.should == "hello!"
          job.delete

          EM.stop
        end.resume
      end
    end
    it "should process each job" do
      EM.run do
        EM.add_timer(10) { EM.stop }
        
        job_body = ''
        
        f = Fiber.new do
          bean = EMJack::Connection.new
          bean.fiber!
        
          bean.put("hello!")
          bean.put("bonjour!")   
          
          mock = double()
          mock.should_receive(:foo).with("hello!")
          mock.should_receive(:foo).with("bonjour!")
          
          bean.each_job(0) do |job|
            mock.foo(job.body)
            job_body = job.body
            job.delete
          end
          
        end
        
        f.resume
        
        EM.add_timer(1) { EM.stop unless f.alive?; job_body.should eq "bonjour!" unless f.alive? }
        
      end
    end
  end
end
