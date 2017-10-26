# -*- coding: utf-8 -*-

require_relative 'model'

module Plugin::TDR
  class RehabAPI
    def start
      fetch_tdl
      fetch_tds
    end

    private
    # TDLのリハブ情報を取得
    def fetch_tdl
      Thread.new {
        client = HTTPClient.new
        url = 'http://info.tokyodisneyresort.jp/schedule/stop/stop_list.html'
        client.get(url)
      }.next { |response|
        charset = response.body_encoding.name
        doc = Nokogiri::HTML.parse(response.content, nil, charset)
        doc.xpath('//*[@id="main"]/div/div/section[1]/dl').css('li')
      }.next { |doc|
        [Plugin::TDR::User.new(
            name: '東京ディズニーランド リハブ情報',
            profile_image_url: File.join(File.dirname(__FILE__), '../tdl.png')
        ), doc]
      }.next { |park, doc|
        create_message park, doc
      }.next { |msgs|
        Plugin.call :appear, msgs
        Plugin.call :extract_receive_message, :mikutter_tdl_rehab, msgs
      }.trap { |e| error e }
    end

    # TDSのリハブ情報を取得
    def fetch_tds
      Thread.new {
        client = HTTPClient.new
        url = 'http://info.tokyodisneyresort.jp/schedule/stop/stop_list.html'
        client.get(url)
      }.next { |response|
        charset = response.body_encoding.name
        doc = Nokogiri::HTML.parse(response.content, nil, charset)
        doc.xpath('//*[@id="main"]/div/div/section[2]/dl').css('li')
      }.next { |doc|
        [Plugin::TDR::User.new(
            name: '東京ディズニーシー リハブ情報',
            profile_image_url: File.join(File.dirname(__FILE__), '../tds.png')
        ), doc]
      }.next { |park, doc|
        create_message park, doc
      }.next { |msgs|
        Plugin.call :appear, msgs
        Plugin.call :extract_receive_message, :mikutter_tds_rehab, msgs
      }.trap { |e| error e }
    end

    def create_message(park, doc)
      doc.map.with_index do |rehab, i|
        name = rehab.css('a').inner_text != '' ? rehab.css('a').inner_text : rehab.css('p').text
        date = rehab.css('span').text
        Plugin::TDR::Information.new(
            name: name,
            text: "#{name}\n#{date}",
            created: Time.now,
            modified: Time.now - i,
            user: park
        )
      end
    end
  end
end