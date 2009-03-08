require 'jack'

jack = Jack::Connection.new

# default puts errback will be assigned...

r = jack.reserve
r.callback do |job|
  puts job.jobid
  process(job)
end
r.errback do |reason|
  puts "Failed to reserve job #{reason}"
end

jack.reserve do |job|
  puts job.jobid
  process(job)
end

r = jack.delete(job)
r.callback do |jobid|
  puts "Successfully delete #{jobid}"
end
r.errback do |jobid, reason|
  puts "Failed to delete #{jobid} :: #{reason}"
end

r = jack.stats(:tube)
r.callback do |stats|
  puts stats.inspect
end
r.errback do |error|
  puts "Failed to get stats:: #{error}"
end

r = jack.put("my message", :ttr => 300)
r.callback do |jobid|
  puts "put successful #{jobid}"
end
r.errback do |msg, opts, reason|
  puts "Failed ot put #{msg}:: #{reason}"
end

