module Sinatra
  module RespondTo
    class UnhandledFormat < Sinatra::NotFound; end

    def self.registered(app)
      app.helpers RespondTo::Helpers

      app.set :default_charset, 'utf-8'
      app.set :default_content, :html
      app.set :assume_xhr_is_js, true
    end

    # We remove the trailing extension so routes
    # don't have to be of the style
    #
    #   get '/resouce.:format'
    #
    # They can instead be of the style
    #
    #   get '/resource'
    #
    # and the format will automatically be available in as <tt>format</tt>
    before do
      request.path_info.gsub! %r{\.([^\./]+)$}, ''
      self.format = ($1 || options.default_content).to_sym
      self.format = :js if request.xhr? && options.assume_xhr_is_js?

      content_type format
    end

    module Helpers
      attr_accessor :format

      def respond_to(&block)
        wants = {}
        def wants.method_missing(type, *args, &block)
          Sinatra::Base.send(:fail, "Unknown media type for respond_to: #{type}\nTry registering the extension with a mime type") if Sinatra::Base.media_type(type).nil?
          self[type] = block
        end

        yield wants

        handler = wants[format]
        raise UnhandledFormat  if handler.nil?

        content_type format, :charset => options.default_charset if TEXT_MIME_TYPES.include? format && response['Content-Type'] !~ /charset=/

        handler.call
      end
    end
  end

  register RespondTo
end
