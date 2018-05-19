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
      def fetch url
        client = HTTPClient.new
        header = {
            'User-Agent' => 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/63.0.3239.132 Safari/537.36',
            'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8',
            'Accept-Encoding' => 'gzip, deflate, br',
            'Accept-Language' => 'ja',
            'Upgrade-Insecure-Requests' => '1',
            'Connection' => 'keep-alive'
        }
        cookie = WebAgent::Cookie.new
        cookie.name = 'tdrloc'
        cookie.value = UserConfig[:mikutter_tdr_cookie_value]
        cookie.url = Addressable::URI.parse('https://www.tokyodisneyresort.jp/view_interface.php?blockId=94199&pageBlockId=13476&nextUrl=tdlattraction')
        client.cookie_manager.add cookie
        res = client.get(url, :header => header)
        body = Zlib::GzipReader.new(StringIO.new(res.body.to_s)).read
        JSON.parse body
      end
    end
  end
end
