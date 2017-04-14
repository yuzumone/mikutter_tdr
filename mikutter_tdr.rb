# -*- coding: utf-8 -*-

Plugin.create(:mikutter_tdr) do

  require_relative 'api'

  filter_extract_datasources { |datasources|
    begin
      datasources[:mikutter_tdl_greeting] = 'TDR/ディズニーランドパレード'
      datasources[:mikutter_tdl_attraction] = 'TDR/ディズニーランドアトラクション'
      datasources[:mikutter_tdl_restaurant] ='TDR/ディズニーランドレストラン'
      datasources[:mikutter_tds_greeting] = 'TDR/ディズニーシーパレード'
      datasources[:mikutter_tds_attraction] = 'TDR/ディズニーシーアトラクション'
      datasources[:mikutter_tds_restaurant] = 'TDR/ディズニーシーレストラン'
      datasources[:mikutter_tdr_weather] = 'TDR/舞浜の天気'
    rescue => e
      puts e
      puts e.backtrace
    end
    [datasources]
  }

  on_boot do
    attraction = Plugin::TDR::AttractionAPI.new
    attraction.start
    restaurant = Plugin::TDR::RestaurantAPI.new
    restaurant.start
    greeting = Plugin::TDR::GreetingAPI.new
    greeting.start
    weather = Plugin::TDR::WeatherAPI.new
    weather.start
  end
end
