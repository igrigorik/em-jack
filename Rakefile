require 'rake'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'spec/rake/spectask'
 
spec = eval(File.read(File.join(File.dirname(__FILE__), "em-jack.gemspec")))
 
task :default => :gem
 
Spec::Rake::SpecTask.new do |t|
  t.libs << 'lib'
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.spec_opts = ["-colour"]
end
 
desc 'Generate RDoc documentation for EMJack'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_files.include('README.rdoc', 'COPYING', 'lib/**/*.rb')
  rdoc.main = 'README.rdoc'
  rdoc.title = 'EM Jack Documentation'
 
  rdoc.rdoc_dir = 'doc'
  rdoc.options << '--line-numbers'
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_tar = true
end
