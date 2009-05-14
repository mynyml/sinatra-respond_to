require 'test/test_helper'

class App < Sinatra::Base
  register Sinatra::RespondTo

  get '/foo' do
    'foo'
  end

  get '/bar' do
    respond_to do |wants|
      wants.xml  { '<bar>baz</bar>' }
      wants.json { '{bar:baz}' }
    end
  end

  get '/format' do
    format.to_s
  end
end

class RespondToTest < Test::Unit::TestCase
  include Sinatra::Test

  def setup
    @client = Sinatra::TestHarness.new(App)
  end

  def test_strips_url_extention
    response = @client.get '/foo.html'
    assert_equal 'foo', response.body
  end

  def test_sets_content_type
    response = @client.get '/foo.xml'
    assert_equal 'application/xml', response.content_type
  end

  def test_sets_default_content_type
    App.set :default_content_type, :json

    response = @client.get '/foo'
    assert_equal 'application/json', response.content_type
  end

  def test_sets_javascript_content_type_on_xhr_request
    App.set :assume_xhr_is_js, true

    response = @client.get '/foo', :env => { 'HTTP_X_REQUESTED_WITH' => 'XMLHttpRequest' }
    assert_equal 'application/javascript', response.content_type
  end

  def test_handles_xhr_as_regular_request
    App.set :default_content_type, :html
    App.set :assume_xhr_is_js, false

    response = @client.get '/foo', :env => { 'HTTP_X_REQUESTED_WITH' => 'XMLHttpRequest' }
    assert_equal 'text/html', response.content_type
  end

  def test_calls_proper_handler
    response = @client.get '/bar.xml'
    assert_equal '<bar>baz</bar>', response.body

    response = @client.get '/bar.json'
    assert_equal '{bar:baz}', response.body
  end

  def test_lack_of_handler_returns_404
    response = @client.get '/bar.html'
    assert_equal 404, response.status
  end

  def test_lack_of_handler_raises_format_error
    App.error(Sinatra::RespondTo::UnhandledFormat) { 'unhandled format' }

    response = @client.get '/bar.html'
    assert_equal 'unhandled format', response.body
  end

  def test_makes_resquested_format_available
    response = @client.get '/format.xml'
    assert_equal 'xml', response.body
  end
end
