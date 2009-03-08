module Jack
  class Job
    attr_accessor :jobid, :body, :ttr, :conn
    
    def initialize(conn, jobid, body)
      @conn = conn
      @jobid = jobid.to_i
      @body = body
    end
    
    def delete
      @conn.delete(self)
    end
    
    def stats
      @conn.stats(:job, self)
    end

    def to_s
      "#{@jobid} -- #{body.inspect}"
    end
  end
end