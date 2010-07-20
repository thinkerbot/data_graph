$:.unshift File.expand_path('../lib', __FILE__)
require 'data_graph/version'
$:.shift

Gem::Specification.new do |s|
  s.name = 'data_graph'
  s.version = DataGraph::VERSION
  s.author = 'Your Name Here'
  s.email = 'your.email@pubfactory.edu'
  s.homepage = ''
  s.platform = Gem::Platform::RUBY
  s.summary = ''
  s.require_path = 'lib'
  s.rubyforge_project = ''
  s.has_rdoc = true
  s.rdoc_options.concat %W{--main README -S -N --title Data-Graph}
  
  # add dependencies
  # s.add_dependency('x', '= 1.0')
  
  # list extra rdoc files here.
  s.extra_rdoc_files = %W{
    History
    README
  }
  
  # list the files you want to include here.
  s.files = %W{
  }
end