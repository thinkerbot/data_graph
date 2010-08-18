#!/usr/bin/env ruby

require 'rubygems'
require 'bundler'
Bundler.setup

$:.unshift File.expand_path('../../test/models', __FILE__)

require 'data_graph'
require 'job'
require 'product'
require 'irb'
require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: ruby script/console.rb [options]"

  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end
  
  opts.on_tail("-h", "--help", "Print Help") do |v|
    puts opts
    exit
  end
end.parse!

ActiveRecord::Base.logger = Logger.new(options[:verbose] ? STDOUT : StringIO.new)
ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')

connection = ActiveRecord::Base.connection.raw_connection
connection.execute_batch File.read(File.expand_path("../../test/ddl/create.sql", __FILE__))
connection.execute_batch File.read(File.expand_path("../../test/ddl/insert.sql", __FILE__))

IRB.start
