# frozen_string_literal: true

# This code is heavily inspired by webmock's NetHttpAdapter
# webmock source code was used as reference material during development.
# https://github.com/bblimke/webmock/blob/master/lib/webmock/http_lib_adapters/net_http.rb
# Thanks, webmock devs.
# https://github.com/bblimke/webmock/blob/master/LICENSE
module RequestTagger
  class HttpMagic
    def initialize
      @original_net_http = original_net_http
      @magic_net_http = magic_net_http
    end

    def wrap
      Net.send(:remove_const, :HTTP)
      Net.send(:const_set, :HTTP, @magic_net_http)
    end

    def restore
      Net.send(:remove_const, :HTTP)
      Net.send(:const_set, :HTTP, @original_net_http)
    end

    private

    def magic_net_http
      Class.new(Net::HTTP) do
        def request(request, body = nil, &block)
          http_tag = RequestTagger::Setup.http_tag
          if request.get_fields(http_tag[:field]).nil?
            request.add_field(http_tag[:field], http_tag[:value])
          end
          super
        end
      end
    end

    def original_net_http
      Net::HTTP
    end
  end
end
