# -*- coding: utf-8 -*-

require_relative 'model'
require_relative '../api'

module Plugin::TDR
  class ShowAPI
    def initialize
      @saved_tdl_show ||= []
      @saved_tds_show ||= []
    end

    def start
      fetch_tdl
      fetch_tds
      reserver
    end

    def reserver
      Reserver.new(300) {
        fetch_tdl
        fetch_tds
        reserver
      }
    end

    private
    def fetch_tdl
      Thread.new {
        url = 'http://www.tokyodisneyresort.jp/_/realtime/tdl_parade_show.json'
        res = Plugin::TDR::API.fetch url
        [Plugin::TDR::User.new(
          name: 'ディズニーランド ショー/パレード',
          profile_image_url: File.join(File.dirname(__FILE__), '../tdl.png')
        ), res]
      }.next { |park, res|
        msgs = create_message park, res
        Plugin.call :destroyed, @saved_tdl_show
        Plugin.call :appear, msgs
        Plugin.call :extract_receive_message, :mikutter_tdl_show, msgs
        @saved_tdl_show = msgs
      }.trap { |e| error e }
    end

    def fetch_tds
      Thread.new {
        url = 'http://www.tokyodisneyresort.jp/_/realtime/tds_parade_show.json'
        res = Plugin::TDR::API.fetch url
        [Plugin::TDR::User.new(
          name: 'ディズニーシー ショー/パレード',
          profile_image_url: File.join(File.dirname(__FILE__), '../tds.png')
        ), res]
      }.next { |park, res|
        msgs = create_message park, res
        Plugin.call :destroyed, @saved_tds_show
        Plugin.call :appear, msgs
        Plugin.call :extract_receive_message, :mikutter_tds_show, msgs
        @saved_tds_show = msgs
      }.trap { |e| error e }
    end

    def create_message park, data
      data.map.with_index { |show, i|
        name = show['FacilityName']
        url = show['FacilityURLSP']
        operatingHours = show['operatingHours'] ||= []
        update = show['UpdateTime']
        operating = operatingHours.map { |item|
          from = item['OperatingHoursFrom']
          to = item['OperatingHoursTo']
          status = item['OperatingStatus']
          from.to_s + ' - ' + to.to_s + "\t" + status.to_s
        }.join("\n")
        text = name
        text += "\n" + operating unless operating.empty?
        text += "\n" + '更新時間: ' + update
        msg = Plugin::TDR::Information.new(
          name: name,
          text: text,
          created: Time.now - i,
          modified: Time.parse(update),
          user: park,
          link: url
        )
      }
    end
  end
end
