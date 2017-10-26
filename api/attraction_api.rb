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

    private
    # アトラクションのアップデートを5分ごとに繰り返し実行
    def reserver
      Reserver.new(300) {
        fetch_tdl
        fetch_tds
        reserver
      }
    end

    # TDLのアトラクションの情報を取得
    def fetch_tdl
      Thread.new {
        url = 'http://info.tokyodisneyresort.jp/rt/s/gps/tdl_index.html' +
            '?nextUrl=http://info.tokyodisneyresort.jp/rt/s/realtime/tdl_attraction.html' +
            '&lat=35.6329527&lng=139.8840281'
        Plugin::TDR::API.get_content_with_redirection url
      }.next { |response|
        doc = Nokogiri::HTML.parse(response, nil, 'utf-8')
        doc.css('ul#atrc.schedule').css('li')
      }.next { |doc|
        [Plugin::TDR::User.new(
            name: '東京ディズニーランド アトラクション',
            profile_image_url: File.join(File.dirname(__FILE__), '../tdl.png')
        ), doc]
      }.next { |park, doc|
        msgs = []
        if doc.empty?
          msg = Plugin::TDR::Information.new(
              name: '閉園',
              text: 'ただいま東京ディズニーランドは、閉園しております。',
              link: 'http://info.tokyodisneyresort.jp/s/calendar/tdl/',
              created: Time.now,
              modified: Time.now,
              user: park)
          msgs.push(msg)
        else
          msgs = create_message park, doc
        end
        msgs
      }.next { |msgs|
        Plugin.call :destroyed, @saved_tdl_attractions
        Plugin.call :appear, msgs
        Plugin.call :extract_receive_message, :mikutter_tdl_attraction, msgs
        @saved_tdl_attractions = msgs
      }.trap { |e| error e }
    end

    # TDSのアトラクションの情報を取得
    def fetch_tds
      Thread.new {
        url = 'http://info.tokyodisneyresort.jp/rt/s/gps/tds_index.html' +
            '?nextUrl=http://info.tokyodisneyresort.jp/rt/s/realtime/tds_attraction.html' +
            '&lat=35.6329527&lng=139.8840281'
        Plugin::TDR::API.get_content_with_redirection url
      }.next { |response|
        doc = Nokogiri::HTML.parse(response, nil, 'utf-8')
        doc.css('ul#atrc.schedule').css('li')
      }.next { |doc|
        [Plugin::TDR::User.new(
            name: '東京ディズニーシー アトラクション',
            profile_image_url: File.join(File.dirname(__FILE__), '../tds.png')
        ), doc]
      }.next { |park, doc|
        msgs = []
        if doc.empty?
          msg = Plugin::TDR::Information.new(
              name: '閉園',
              text: 'ただいま東京ディズニーシーは、閉園しております。',
              link: 'http://info.tokyodisneyresort.jp/s/calendar/tds/',
              created: Time.now,
              modified: Time.now,
              user: park
          )
          msgs.push(msg)
        else
          msgs = create_message park, doc
        end
        msgs
      }.next { |msgs|
        Plugin.call :destroyed, @saved_tds_attractions
        Plugin.call :appear, msgs
        Plugin.call :extract_receive_message, :mikutter_tds_attraction, msgs
        @saved_tds_attractions = msgs
      }.trap { |e| error e }
    end

    def create_message(park, doc)
      doc.map.with_index do |attraction, i|
        name = attraction.css('h3').text.gsub(/(\s)/, '')
        wait_time = attraction.css('p.waitTime').text.gsub(/(\s)/, '')
        run_time = attraction.css('p.run').text.gsub(/(\s)/, '')
        fp_time = attraction.css('p.fp').text.gsub(/(\s)/, '')
        text = name
        text = text + "\n" + run_time unless run_time.empty?
        text = text + "\n待ち時間: " + wait_time unless wait_time.empty?
        text = text + "\nFP: " + fp_time unless fp_time.empty?
        msg = Plugin::TDR::Information.new(
            name: name,
            text: text,
            created: Time.now,
            modified: Time.now - i,
            user: park
        )
        unless attraction.css('a').empty?
          msg.link = attraction.css('a').attribute('href')
        end
        msg
      end
    end
  end
end