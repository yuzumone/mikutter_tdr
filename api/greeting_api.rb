# -*- coding: utf-8 -*-

require_relative 'model'

module Plugin::TDR
  class GreetingAPI
    def start
      fetch_tdl
      fetch_tds
    end

    private
    # TDLのショーの情報を取得
    def fetch_tdl
      Thread.new {
        client = HTTPClient.new
        url = 'http://info.tokyodisneyresort.jp/s/daily_schedule/show/tdl_' + Date.today.strftime('%Y%m%d') + '.html'
        client.get(url)
      }.next { |response|
        charset = response.body_encoding.name
        doc = Nokogiri::HTML.parse(response.content, nil, charset)
        doc.xpath('//*[@id="greeting"]/li')
      }.next { |doc|
        [Plugin::TDR::Park.new(
            name: '東京ディズニーランド パレード/ショー',
            profile_image_url: File.join(File.dirname(__FILE__), '../tdl.png')
        ), doc]
      }.next { |park, doc|
        create_message park, doc
      }.next { |msgs|
        Plugin.call :appear, msgs
        Plugin.call :extract_receive_message, :mikutter_tdl_greeting, msgs
      }.trap { |e| error e }
    end

    # TDSのショーの情報を取得
    def fetch_tds
      Thread.new {
        client = HTTPClient.new
        url = 'http://info.tokyodisneyresort.jp/s/daily_schedule/show/tds_' + Date.today.strftime('%Y%m%d') + '.html'
        client.get(url)
      }.next { |response|
        charset = response.body_encoding.name
        doc = Nokogiri::HTML.parse(response.content, nil, charset)
        doc.xpath('//*[@id="greeting"]/li')
      }.next { |doc|
        [Plugin::TDR::Park.new(
            name: '東京ディズニーシー パレード/ショー',
            profile_image_url: File.join(File.dirname(__FILE__), '../tds.png')
        ), doc]
      }.next { |park, doc|
        create_message park, doc
      }.next { |msgs|
        Plugin.call :appear, msgs
        Plugin.call :extract_receive_message, :mikutter_tds_greeting, msgs
      }.trap { |e| error e }
    end

    def create_message(park, doc)
      doc.map do |greeting|
        name = greeting.css('h3').text.gsub(/(\s)/, '')
        times = greeting.css('p.time').text
        time = Time.new(Date.today.year, Date.today.mon, Date.today.day)
        if /\d+:\d+/ === times
          time = times.match(/\d+:\d+/)[0]
        end
        msg = Plugin::TDR::Greeting.new(
            title: name,
            name: name,
            times: times,
            created: Time.now,
            modified: time,
            park: park
        )
        unless greeting.css('a').empty?
          msg.link = greeting.css('a').attribute('href')
        end
        msg
      end
    end
  end
end