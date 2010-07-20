require 'rubygems'
require 'bundler'
Bundler.setup

module WarnFilter
  FILTER_PATHS = ENV['GEM_PATH'].split(':') + [Bundler.bundle_path.to_s] + [File.expand_path('vendor')]
  @@count = 0
  
  # A running tally of warnings that have been filtered.
  def self.count
    @@count
  end
  
  # Writes the message unless it begins with one of the FILTER_PATHS, in
  # which case the message is interpreted as a warning.  In that case
  # count is incremented and the message is ignored.
  def write(message)
    FILTER_PATHS.any? {|path| message.index(path) == 0 } ? @@count += 1 : super
  end
end

unless ENV['WARN_FILTER'] == 'false'
  $stderr.extend(WarnFilter)
  at_exit do
    if WarnFilter.count > 0
      $stderr.puts "(WarnFilter filtered #{WarnFilter.count} warnings, set WARN_FILTER=false in ENV to see warnings)" 
    end
  end
end

require 'test/unit'
require 'stringio'

module DatabaseTest
  DATABASE = ENV['DATABASE'] || ':memory:'
  
  def setup
    @teardowns = []
    establish_connection
    super
  end
  
  def teardown
    @teardowns.each {|teardown| script(teardown, true) }
    super
  end
  
  def establish_connection
    unless ActiveRecord::Base.connected?
      ActiveRecord::Base.logger = Logger.new(StringIO.new)
      ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => DATABASE)
      script ddl('create')
      script ddl('insert')
    end
  end
  
  def ddl(name)
    File.read File.expand_path("../ddl/#{name}.sql", __FILE__)
  end
  
  def transaction
    connection = ActiveRecord::Base.connection
    
    begin
      connection.increment_open_transactions
      connection.begin_db_transaction
      yield
    ensure
      connection.rollback_db_transaction
      connection.decrement_open_transactions
    end
  end
  
  def script(script, ignore_errors=false)
    begin
      ActiveRecord::Base.connection.raw_connection.execute_batch(script)
    rescue(SQLite3::SQLException)
      raise $! unless ignore_errors
    end
  end
  
  def fixture(setup, teardown=nil)
    if teardown
      @teardowns << teardown
      script(teardown, true)
    end
    script(setup)
  end
end
