$:.unshift File.expand_path('../lib', __FILE__)
require 'data_graph/version'
$:.shift

Gem::Specification.new do |s|
  s.name = 'data_graph'
  s.version = DataGraph::VERSION
  s.author = 'Simon Chiang'
  s.email = 'simon.a.chiang@gmail.com'
  s.homepage = ''
  s.platform = Gem::Platform::RUBY
  s.summary = ''
  s.require_path = 'lib'
  s.rubyforge_project = ''
  s.has_rdoc = true
  s.rdoc_options.concat %W{--main README -S -N --title Data\ Graph}
  
  # add dependencies
  s.add_dependency('activerecord', '= 2.3.5')
  s.add_dependency('composite_primary_keys', '= 2.3.5.1')
  s.add_development_dependency('sqlite3-ruby', '~> 1.2.5')
  
  # list extra rdoc files here.
  s.extra_rdoc_files = %W{
    History
    README
  }
  
  # list the files you want to include here.
  s.files = %W{
    lib/data_graph.rb
    lib/data_graph/cpk_linkage.rb
    lib/data_graph/graph.rb
    lib/data_graph/linkage.rb
    lib/data_graph/node.rb
    lib/data_graph/utils.rb
    lib/data_graph/version.rb
  }
end