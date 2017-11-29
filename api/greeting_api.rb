# -*- coding: utf-8 -*-

require_relative 'model'
require_relative '../api'

module Plugin::TDR
  class GreetingAPI
    def initialize
      @saved_tdl_greeting ||= []
      @saved_tds_greeting ||= []
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
    # TDLのショーの情報を取得
    def fetch_tdl
      Thread.new {
        url = 'http://info.tokyodisneyresort.jp/rt/s/gps/tdl_index.html' +
            '?nextUrl=http://info.tokyodisneyresort.jp/rt/s/realtime/tdl_show.html' +
            '&lat=35.6329535&lng=139.8840285'
        Plugin::TDR::API.get_content_with_redirection url
      }.next { |response|
        doc = Nokogiri::HTML.parse(response, nil, 'utf-8')
        doc.xpath('//*[@id="show"]/article/li')
      }.next { |doc|
        [Plugin::TDR::User.new(
            name: '東京ディズニーランド パレード/ショー',
            profile_image_url: File.join(File.dirname(__FILE__), '../tdl.png')
        ), doc]
      }.next { |park, doc|
        create_message park, doc
      }.next { |msgs|
        Plugin.call :destroyed, @saved_tdl_greeting
        Plugin.call :appear, msgs
        Plugin.call :extract_receive_message, :mikutter_tdl_greeting, msgs
        @saved_tdl_greeting = msgs
      }.trap { |e| error e }
    end

    # TDSのショーの情報を取得
    def fetch_tds
      Thread.new {
        url = 'http://info.tokyodisneyresort.jp/rt/s/gps/tdl_index.html' +
            '?nextUrl=http://info.tokyodisneyresort.jp/rt/s/realtime/tds_show.html' +
            '&lat=35.6329537&lng=139.8840287'
        Plugin::TDR::API.get_content_with_redirection url
      }.next { |response|
        doc = Nokogiri::HTML.parse(response, nil, 'utf-8')
        doc.xpath('//*[@id="show"]/article/li')
      }.next { |doc|
        [Plugin::TDR::User.new(
            name: '東京ディズニーシー パレード/ショー',
            profile_image_url: File.join(File.dirname(__FILE__), '../tds.png')
        ), doc]
      }.next { |park, doc|
        create_message park, doc
      }.next { |msgs|
        Plugin.call :destroyed, @saved_tds_greeting
        Plugin.call :appear, msgs
        Plugin.call :extract_receive_message, :mikutter_tds_greeting, msgs
        @saved_tds_greeting = msgs
      }.trap { |e| error e }
    end

    def create_message(park, doc)
      doc.map.with_index do |greeting, i|
        name = greeting.css('h3').text.gsub(/(\s)/, '')
        times = greeting.css('p.time').map {|time| time.text.strip }.compact.reject(&:empty?).join("\n")
        msg = Plugin::TDR::Information.new(
            name: name,
            text: "#{name}\n#{times}",
            created: Time.now,
            modified: Time.now - i,
            user: park
        )
        unless greeting.css('a').empty?
          msg.link = greeting.css('a').attribute('href')
        end
        msg
      end
    end
  end
end