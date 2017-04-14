# -*- coding: utf-8 -*-

require_relative 'model'
require_relative '../api'

module Plugin::TDR
  class RestaurantAPI
    def initialize
      @saved_tdl_restaurant ||= []
      @saved_tds_restaurant ||= []
    end

    def start
      fetch_tdl
      fetch_tds
      reserver
    end

    private
    # レストランのアップデートを5分ごとに繰り返し実行
    def reserver
      Reserver.new(300) {
        fetch_tdl
        fetch_tds
        reserver
      }
    end

    # TDLのレストランの情報を取得
    def fetch_tdl
      Thread.new {
        url = 'http://info.tokyodisneyresort.jp/rt/s/gps/tdl_index.html' +
            '?nextUrl=http://info.tokyodisneyresort.jp/rt/s/realtime/tdl_restaurant.html' +
            '&lat=35.6280767&lng=139.883245'
        Plugin::TDR::API.get_content_with_redirection url
      }.next { |response|
        doc = Nokogiri::HTML.parse(response, nil, 'utf-8')
        doc.css('ul#restaurant.schedule').css('li')
      }.next { |doc|
        [Plugin::TDR::Park.new(
            name: '東京ディズニーランド レストラン',
            profile_image_url: File.join(File.dirname(__FILE__), '../tdl.png')
        ), doc]
      }.next { |park, doc|
        msgs = []
        if doc.empty?
          msg = Plugin::TDR::Restaurant.new(
              name: 'ただいま東京ディズニーランドは、閉園しております。',
              link: 'http://info.tokyodisneyresort.jp/s/calendar/tdl/',
              created: Time.now,
              modified: Time.now,
              park: park
          )
          msgs.push(msg)
        else
          msgs = create_message park, doc
        end
        msgs
      }.next { |msgs|
        Plugin.call :destroyed, @saved_tdl_restaurant
        Plugin.call :appear, msgs
        Plugin.call :extract_receive_message, :mikutter_tdl_restaurant, msgs
        @saved_tdl_restaurant = msgs
      }
    end

    # TDSのレストランの情報を取得
    def fetch_tds
      Thread.new {
        url = 'http://info.tokyodisneyresort.jp/rt/s/gps/tds_index.html' +
            '?nextUrl=http://info.tokyodisneyresort.jp/rt/s/realtime/tds_restaurant.html' +
            '&lat=35.6280767&lng=139.883245'
        Plugin::TDR::API.get_content_with_redirection url
      }.next { |response|
        doc = Nokogiri::HTML.parse(response, nil, 'utf-8')
        doc.css('ul#restaurant.schedule').css('li')
      }.next { |doc|
        [Plugin::TDR::Park.new(
            name: '東京ディズニーシー レストラン',
            profile_image_url: File.join(File.dirname(__FILE__), '../tds.png')
        ), doc]
      }.next { |park, doc|
        msgs = []
        if doc.empty?
          msg = Plugin::TDR::Restaurant.new(
              name: 'ただいま東京ディズニーシーは、閉園しております。',
              link: 'http://info.tokyodisneyresort.jp/s/calendar/tdl/',
              created: Time.now,
              modified: Time.now,
              park: park
          )
          msgs.push(msg)
        else
          msgs = create_message park, doc
        end
        msgs
      }.next { |msgs|
        Plugin.call :destroyed, @saved_tds_restaurant
        Plugin.call :appear, msgs
        Plugin.call :extract_receive_message, :mikutter_tds_restaurant, msgs
        @saved_tds_restaurant = msgs
      }
    end

    def create_message(park, doc)
      doc.map.with_index do |restaurant, i|
        name = restaurant.css('h3').text.gsub(/(\s)/, '')
        wait_time = restaurant.css('div.time').text.gsub(/(\s)/, '')
        op_left = restaurant.css('div.op-left').text.gsub(/(\s)/, '')
        op_right = restaurant.css('div.op-right').text.gsub(/(\s)/, '')
        run_time = restaurant.css('p.run').text.gsub(/(\s)/, '')
        msg = Plugin::TDR::Restaurant.new(
            name: name,
            wait_time: wait_time,
            op_left: op_left,
            op_right: op_right,
            run_time: run_time,
            created: Time.now,
            modified: Time.now - i,
            park: park
        )
        unless restaurant.css('a').empty?
          msg.link = restaurant.css('a').attribute('href')
        end
        msg
      end
    end
  end
end