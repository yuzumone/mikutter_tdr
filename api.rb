# -*- coding: utf-8 -*-

require_relative 'api/attraction_api'
require_relative 'api/greeting_api'
require_relative 'api/character_api'
require_relative 'api/restaurant_api'
require_relative 'api/rehab_api'
require_relative 'api/weather_api'

module Plugin::TDR
  class API
    class << self
      # リダイレクト先のURLを取得
      # http://opentechnica.blogspot.jp/2012/10/rubyurlurl.html
      def get_content_with_redirection(url)
        client = HTTPClient.new
        def client.allow_all_redirection_callback(uri, res)
          urify(res.header['location'][0])
        end
        client.redirect_uri_callback = client.method(:allow_all_redirection_callback)
        client.get_content url
      end
    end
  end
end