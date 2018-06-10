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
    def reserver
      Reserver.new(300) {
        fetch_tdl
        fetch_tds
        reserver
      }
    end

    def fetch_tdl
      Thread.new {
        url = 'http://www.tokyodisneyresort.jp/_/realtime/tdl_restaurant.json'
        res = Plugin::TDR::API.fetch url
        [Plugin::TDR::User.new(
          name: 'ディズニーランド レストラン',
          profile_image_url: File.join(File.dirname(__FILE__), '../tdl.png')
        ), res]
      }.next { |park, res|
        msgs = create_message park, res
        Plugin.call :destroyed, @saved_tdl_restaurant
        Plugin.call :appear, msgs
        Plugin.call :extract_receive_message, :mikutter_tdl_restaurant, msgs
        @saved_tdl_restaurant = msgs
      }.trap { |e| error e }
    end

    def fetch_tds
      Thread.new {
        url = 'http://www.tokyodisneyresort.jp/_/realtime/tds_restaurant.json'
        res = Plugin::TDR::API.fetch url
        [Plugin::TDR::User.new(
          name: 'ディズニーシー レストラン',
          profile_image_url: File.join(File.dirname(__FILE__), '../tds.png')
        ), res]
      }.next { |park, res|
        msgs = create_message park, res
        Plugin.call :destroyed, @saved_tds_restaurant
        Plugin.call :appear, msgs
        Plugin.call :extract_receive_message, :mikutter_tds_restaurant, msgs
        @saved_tds_restaurant = msgs
      }.trap { |e| error e }
    end

    def create_message park, data
      data.map.with_index { | restaurant , i |
        name = restaurant['FacilityName']
        url = restaurant['FacilityURLSP']
        update = restaurant['UpdateTime']
        operatingHours = restaurant['operatingHours'] ||= []
        popcorn = restaurant['PopCornFlavors']
        min = restaurant['StandbyTimeMin']
        max = restaurant['StandbyTimeMax']
        operating = operatingHours.map { |item|
          from = item['OperatingHoursFrom']
          to = item['OperatingHoursTo']
          status = item['OperatingStatus']
          from.to_s + ' - ' + to.to_s + "\t" + status.to_s
        }.join("\n")
        if min.nil? && max.nil?
          wait = nil
        elsif max.nil?
          wait = min.to_s + '分以上'
        elsif max == min
          wait = min.to_s + '分'
        else
          wait = min.to_s + ' - ' + max + '分'
        end
        text = name
        text += "\n" + operating unless operating.empty?
        text += "\n" + wait unless wait.nil?
        text += "\n" + 'ポップコーンフレーバー: ' + popcorn unless popcorn.nil?
        text += "\n" + '更新時間: ' + update
        msg = Plugin::TDR::Information.new(
          name: name,
          text: text,
          created: Time.now - i,
          modified: Time.now,
          user: park,
          link: url
        )
      }
    end
  end
end
