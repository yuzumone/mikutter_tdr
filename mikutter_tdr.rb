# -*- coding: utf-8 -*-

Plugin.create(:mikutter_tdr) do

  require 'date'
  require_relative 'api'

  filter_extract_datasources { |datasources|
    begin
      datasources[:mikutter_tdl_show] = 'TDR/ディズニーランドパレード'
      datasources[:mikutter_tdl_attraction] = 'TDR/ディズニーランドアトラクション'
      datasources[:mikutter_tdl_greeting] = 'TDR/ディズニーランドキャラクターグリーティング'
      datasources[:mikutter_tdl_restaurant] ='TDR/ディズニーランドレストラン'
      datasources[:mikutter_tdl_rehab] = 'TDR/ディズニーランドリハブ'
      datasources[:mikutter_tds_show] = 'TDR/ディズニーシーパレード'
      datasources[:mikutter_tds_attraction] = 'TDR/ディズニーシーアトラクション'
      datasources[:mikutter_tds_greeting] = 'TDR/ディズニーシーキャラクターグリーティング'
      datasources[:mikutter_tds_restaurant] = 'TDR/ディズニーシーレストラン'
      datasources[:mikutter_tds_rehab] = 'TDR/ディズニシーリハブ'
      datasources[:mikutter_tdr_weather] = 'TDR/舞浜の天気'
    rescue => e
      puts e
      puts e.backtrace
    end
    [datasources]
  }

  on_boot do
    d = UserConfig[:mikutter_tdr_cookie_date]
    last = Date.parse d unless d.nil?
    now = Date.today
    if last.nil? || now > last
      get_cookie
      UserConfig[:mikutter_tdr_cookie_date] = now.strftime("%Y%m%d")
    end
    attraction = Plugin::TDR::AttractionAPI.new
    attraction.start
    show = Plugin::TDR::ShowAPI.new
    show.start
    greeting = Plugin::TDR::GreetingAPI.new
    greeting.start
    restaurant = Plugin::TDR::RestaurantAPI.new
    restaurant.start
    rehab = Plugin::TDR::RehabAPI.new
    rehab.start
    weather = Plugin::TDR::WeatherAPI.new
    weather.start
  end

  def get_cookie
    client = HTTPClient.new
    url = 'https://www.tokyodisneyresort.jp/view_interface.php?' +
    'blockId=94199&pageBlockId=13476&nextUrl=tdlattraction'
    header = {
      'User-Agent' => 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/63.0.3239.132 Safari/537.36',
      'Accept' => 'application/json, text/javascript, */*; q=0.01',
      'Accept-Encoding' => 'gzip, deflate, br',
      'Accept-Language' => 'ja',
      'Connection' => 'keep-alive',
      'X-Requested-With' => 'XMLHttpRequest',
      'Content-Type' => 'application/x-www-form-urlencoded; charset=UTF-8'
    }
    data = {
      'lat' => '35.6330126',
      'lon' => '139.8840456'
    }
    res = client.post(url, :body => data, :header => header)
    UserConfig[:mikutter_tdr_cookie_value] = res.cookies.find { |cookie| cookie.name == 'tdrloc' }.value
  end
end
