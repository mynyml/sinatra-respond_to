require 'pathname'

module Sinatra
  module RespondTo
    class UnhandledFormat < Sinatra::NotFound; end

    def self.registered(app)
      app.helpers RespondTo::Helpers

      app.set :default_content_type, :html
      app.set :assume_xhr_is_js,     true

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
      app.before do
        ext = Pathname(request.path_info).extname
        request.path_info.sub!(/#{ext}$/,'')

        ext = ext.empty? ? nil : ext.sub(/^./,'')
        self.format = (request.xhr? && options.assume_xhr_is_js?) ? :js : (ext || options.default_content_type).to_sym

        content_type format
      end
    end

    module Helpers
      attr_accessor :format

      def respond_to(&block)
        wants = {}
        def wants.method_missing(type, *args, &handler)
          self[type] = handler
        end
        block.call(wants)
        raise UnhandledFormat if wants[format].nil?

        handler = wants[format]
        handler.call
      end
    end
  end

  register RespondTo
end
