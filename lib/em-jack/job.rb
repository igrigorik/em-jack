module EMJack
  class Job
    attr_accessor :jobid, :body, :ttr, :conn
    
    def initialize(conn, jobid, body)
      @conn = conn
      @jobid = jobid.to_i
      @body = body
    end
    
    def delete(&blk)
      @conn.delete(self, &blk)
    end
    
    def stats(&blk)
      @conn.stats(:job, self, &blk)
    end

    def to_s
      "#{@jobid} -- #{body.inspect}"
    end
  end
end