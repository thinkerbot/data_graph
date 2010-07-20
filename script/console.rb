#!/usr/bin/env ruby

require 'rubygems'
require 'bundler'
Bundler.setup

$:.unshift File.expand_path('../../test/models', __FILE__)

require 'data_graph'
require 'job'
require 'irb'

ActiveRecord::Base.logger = Logger.new(StringIO.new)
ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')

connection = ActiveRecord::Base.connection.raw_connection
connection.execute_batch File.read(File.expand_path("../../test/ddl/create.sql", __FILE__))
connection.execute_batch File.read(File.expand_path("../../test/ddl/insert.sql", __FILE__))

IRB.start
