module Jack
  class Job
    attr_accessor :jobid, :body, :ttr, :conn
    
    def initialize(conn, jobid, body, ttr)
      @conn = conn
      @jobid = jobid.to_i
      @body = body
      @ttr = ttr.to_i
    end
    
    def delete
      @conn.delete(self)
    end
    
    def to_s
      "#{@jobid} -- #{body.inspect}"
    end
  end
end