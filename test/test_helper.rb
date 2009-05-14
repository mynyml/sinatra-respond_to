# stdlib
require 'pathname'
require 'test/unit'

# gems
require 'rubygems'
require 'sinatra/base'
require 'sinatra/test'
begin
  require 'ruby-debug'
rescue LoadError, RuntimeError
end

# local
root  = Pathname(__FILE__).dirname.parent.expand_path
require root.join('lib/sinatra/respond_to')
