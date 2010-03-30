Gem::Specification.new do |s|
  s.name = %q{em-jack}
  s.version = "0.1.0"
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
    lib/em-jack/connection.rb lib/em-jack/errors.rb lib/em-jack/job.rb
    lib/em-jack/handlers/buried.rb lib/em-jack/handlers/inserted.rb
    lib/em-jack/handlers/not_ignored.rb lib/em-jack/handlers/ok.rb
    lib/em-jack/handlers/released.rb lib/em-jack/handlers/reserved.rb
    lib/em-jack/handlers/using.rb lib/em-jack/handlers/watching.rb
    lib/em-jack/handlers/deleted.rb lib/em-jack/handlers/errors.rb
    lib/em-jack/handlers/paused.rb lib/em-jack/handlers/touched.rb
    lib/em-jack/handlers/kicked.rb)
end
