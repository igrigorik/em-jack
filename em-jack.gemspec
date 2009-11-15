Gem::Specification.new do |s|
  s.name = %q{em-jack}
  s.version = "0.0.4"
  s.authors = ["dan sinclair"]
  s.email = %q{dj2@everburning.com}
  s.homepage = %q{http://github.com/dj2/em-jack/}
 
  s.summary = %q{An evented Beanstalk client.}
  s.description = %q{An evented Beanstalk client.}
 
  s.add_dependency('eventmachine')
 
  s.has_rdoc = true
  s.extra_rdoc_files = ['README.rdoc']
  s.rdoc_options << '--title' << 'EM-Jack Documentation' <<
                    '--main' << 'README.rdoc' <<
                    '--line-numbers'
 
  s.files = %w(README.rdoc COPYING lib/em-jack.rb lib/em-jack/beanstalk_connection.rb
    lib/em-jack/connection.rb lib/em-jack/errors.rb lib/em-jack/job.rb)
end
