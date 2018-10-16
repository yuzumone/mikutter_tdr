# -*- coding: utf-8 -*-

require_relative 'model'
require_relative '../api'

module Plugin::TDR
  class AttractionAPI
    def initialize
      @saved_tdl_attractions ||= []
      @saved_tds_attractions ||= []
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
        url = 'https://www.tokyodisneyresort.jp/_/realtime/tdl_attraction.json'
        res = Plugin::TDR::API.fetch url
        [Plugin::TDR::User.new(
          name: 'ディズニーランド アトラクション',
          profile_image_url: File.join(File.dirname(__FILE__), '../tdl.png')
        ), res]
      }.next { |park, res|
        msgs = create_message park, res
        Plugin.call :destroyed, @saved_tdl_attractions
        Plugin.call :appear, msgs
        Plugin.call :extract_receive_message, :mikutter_tdl_attraction, msgs
        @saved_tdl_attractions = msgs
      }.trap { |e| error e }
    end

    def fetch_tds
      Thread.new {
        url = 'https://www.tokyodisneyresort.jp/_/realtime/tds_attraction.json'
        res = Plugin::TDR::API.fetch url
        [ Plugin::TDR::User.new(
          name: 'ディズニーシー アトラクション',
          profile_image_url: File.join(File.dirname(__FILE__), '../tds.png')
        ), res]
      }.next { |park, res|
        msgs = create_message park, res
        Plugin.call :destroyed, @saved_tds_attractions
        Plugin.call :appear, msgs
        Plugin.call :extract_receive_message, :mikutter_tds_attraction, msgs
        @saved_tds_attractions = msgs
      }.trap { |e| error e }
    end

    def create_message park, data
      data.map.with_index { | attraction, i |
        name = attraction['FacilityName']
        status = attraction['OperatingStatus']
        time = attraction['StandbyTime'] || nil
        url = attraction['FacilityURLSP']
        fp = attraction['FsStatus']
        update = attraction['UpdateTime']
        text = name
        text += "\n" + status unless status.nil?
        text += "\n" + time + ' 分' unless time.nil?
        text += "\n" + 'FP: ' + fp unless fp.nil?
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
