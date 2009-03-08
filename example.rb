
jack = Jack::Connection.new

r = jack.use('mytube')
r.callback do |tube|
  puts "Using #{tube}"
end

r = jack.reserve
r.callback do |job|
  puts job.jobid
  process(job)
end

r = jack.delete(job)
r.callback do
  puts "Successfully deleted"
end

r = jack.put("my message", :ttr => 300)
r.callback do |jobid|
  puts "put successful #{jobid}"
end

