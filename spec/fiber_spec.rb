require 'rubygems'
require 'spec'

if RUBY_VERSION > '1.9'
  require 'em-jack'
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
  end
end
