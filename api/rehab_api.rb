# -*- coding: utf-8 -*-

require_relative 'model'

module Plugin::TDR
  class RehabAPI
    def start
      fetch_tdl
      fetch_tds
    end

    private
    def fetch url
      client = HTTPClient.new
      header = {
          'User-Agent' => 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/63.0.3239.132 Safari/537.36',
          'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8',
          'Accept-Encoding' => 'gzip, deflate, br',
          'Accept-Language' => 'ja',
          'Upgrade-Insecure-Requests' => '1',
          'Connection' => 'keep-alive'
      }
      res = client.get(url, :header => header, :follow_redirect => true)
      body = Zlib::GzipReader.new(StringIO.new(res.body.to_s)).read
      doc = Nokogiri::HTML.parse(body, nil, 'utf-8')
      doc.xpath('//*[@class="linkList6"]/ul/li')
    end

    def fetch_tdl
      Thread.new {
        url = 'http://www.tokyodisneyresort.jp/tdl/monthly/stop.html'
        fetch url
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

    def fetch_tds
      Thread.new {
        url = 'http://www.tokyodisneyresort.jp/tds/monthly/stop.html'
        fetch url
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
      doc.map.with_index { |rehab, i|
        text = rehab.css('p').map { |i| i.text.gsub(/(\s)/, '') }.join("\n")
        Plugin::TDR::Information.new(
            name: 'リハブ',
            text: text,
            created: Time.now - i,
            modified: Time.now,
            user: park
        )
        }.select {|item| item.text != "休止を予定しているものはありません。"}
    end
  end
end
