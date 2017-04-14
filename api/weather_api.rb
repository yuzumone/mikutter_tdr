# -*- coding: utf-8 -*-

require 'rss'
require_relative 'model'

module Plugin::TDR
  class WeatherAPI
    def start
      Thread.new {
        rss = RSS::Parser.parse('https://rss-weather.yahoo.co.jp/rss/days/4510.xml')
        rss.items.reject { |item| item.description == '注意報があります' }
      }.next { |items|
        msgs = []
        items.each_with_index do |item, i|
          site = Plugin::TDR::Site.new(
              name: item.title.match(/【.+?】/),
              profile_image_url: File.join(File.dirname(__FILE__), '../weather.png')
          )
          weather = Plugin::TDR::Weather.new(
              title: item.title,
              text: item.description,
              link: item.link,
              created: Time.now,
              modified: Time.now - i,
              site: site
          )
          msgs.push(weather)
        end
        msgs
      }.next { |msgs|
        Plugin.call :appear, msgs
        Plugin.call :extract_receive_message, :mikutter_tdr_weather, msgs
      }.trap { |e| error e }
    end
  end
end
