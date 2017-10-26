# -*- coding: utf-8 -*-

require_relative 'model'
require_relative '../api'

module Plugin::TDR
  class CharacterAPI
    def initialize
      @saved_tdl_character ||= []
      @saved_tds_character ||= []
    end

    def start
      fetch_tdl
      fetch_tds
      reserver
    end

    private
    # グリーティングのアップデートを5分ごとに繰り返し実行
    def reserver
      Reserver.new(300) {
        fetch_tdl
        fetch_tds
        reserver
      }
    end

    # TDLのグリーティングの情報を取得
    def fetch_tdl
      Thread.new {
        url = 'http://info.tokyodisneyresort.jp/rt/s/gps/tdl_index.html' +
            '?nextUrl=http://info.tokyodisneyresort.jp/rt/s/realtime/tdl_greeting.html' +
            '&lat=35.6329530&lng=139.8840280'
        Plugin::TDR::API.get_content_with_redirection url
      }.next { |response|
        doc = Nokogiri::HTML.parse(response, nil, 'utf-8')
        doc.xpath('//article[@class="run clearfix greeting"]')
      }.next { |doc|
        [Plugin::TDR::User.new(
            name: '東京ディズニーランド キャラクターグリーティング',
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
        Plugin.call :destroyed, @saved_tdl_character
        Plugin.call :appear, msgs
        Plugin.call :extract_receive_message, :mikutter_tdl_character, msgs
        @saved_tdl_character = msgs
      }.trap { |e| error e }
    end

    # TDSのグリーティングの情報を取得
    def fetch_tds
      Thread.new {
        url = 'http://info.tokyodisneyresort.jp/rt/s/gps/tds_index.html' +
            '?nextUrl=http://info.tokyodisneyresort.jp/rt/s/realtime/tds_greeting.html' +
            '&lat=35.6329527&lng=139.8840281'
        Plugin::TDR::API.get_content_with_redirection url
      }.next { |response|
        doc = Nokogiri::HTML.parse(response, nil, 'utf-8')
        doc.xpath('//article[@class="run clearfix greeting"]')
      }.next { |doc|
        [Plugin::TDR::User.new(
            name: '東京ディズニーシー キャラクターグリーティング',
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
        Plugin.call :destroyed, @saved_tds_character
        Plugin.call :appear, msgs
        Plugin.call :extract_receive_message, :mikutter_tds_character, msgs
        @saved_tds_character = msgs
      }.trap { |e| error e }
    end

    def create_message(park, doc)
      doc.map.with_index do |character, i|
        name = character.css('h3').text.gsub(/(\s)/, '')
        wait_time = character.css('p.waitTime').text.gsub(/(\s)/, '')
        op_left = character.css('div.op-left')
        op_right = character.css('div.op-right')
        op = op_left.zip(op_right).map{|left, right| "#{left.text.gsub(/(\s)/, '')}: #{right.text.gsub(/(\s)/, '')}"}.join("\n")
        text = name
        text = text + "\n待ち時間: " + wait_time unless wait_time.empty?
        msg = Plugin::TDR::Information.new(
            name: name,
            text: "#{text}\n#{op}",
            created: Time.now,
            modified: Time.now - i,
            user: park
        )
        unless character.css('a').empty?
          msg.link = character.css('a').attribute('href')
        end
        msg
      end
    end
  end
end