Gem::Specification.new do |s|
  s.name = %q{jack}
  s.version = "0.0.1"
  s.authors = ["dan sinclair"]
  s.email = %q{dj2@everburning.com}
  s.homepage = %q{http://http://github.com/dj2/jack/}
 
  s.summary = %q{An evented Beanstalk client.}
  s.description = %q{An evented Beanstalk client.}
 
  s.add_dependency('eventmachine')
 
  s.has_rdoc = true
  s.rdoc_options << '--title' << 'Jack Documentation' <<
                    '--main' << 'README.rdoc' <<
                    '--line-numbers'
 
  s.files = %w(README.rdoc COPYING lib/jack.rb lib/jack/beanstalk_connection.rb
    lib/jack/connection.rb lib/jack/errors.rb lib/jack/job.rb)
end