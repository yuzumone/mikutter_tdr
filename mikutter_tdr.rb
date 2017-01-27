# -*- coding: utf-8 -*-

Plugin.create(:mikutter_tdr) do

  require_relative 'model'
  @saved_tdl_attractions ||= []
  @saved_tds_attractions ||= []

  filter_extract_datasources { |datasources|
    begin
      datasources[:mikutter_tdl_greeting] = 'TDR/TDL Greeting'
      datasources[:mikutter_tdl_attraction] = 'TDR/TDL Attraction'
      datasources[:mikutter_tds_greeting] = 'TDR/TDS Greeting'
      datasources[:mikutter_tds_attraction] = 'TDR/TDS Attraction'
    rescue => e
      puts e
      puts e.backtrace
    end
    [datasources]
  }

  on_boot do
    fetch_tdl_attraction
    fetch_tdl_greeting
    fetch_tds_attraction
    fetch_tds_greeting
    reserver_attraction
  end

  # 今日の日付
  def today
    return Date.today.strftime('%Y%m%d')
  end

  # リダイレクト先のURLを取得
  # http://opentechnica.blogspot.jp/2012/10/rubyurlurl.html
  def get_content_with_redirection(url)
    client = HTTPClient.new
    def client.allow_all_redirection_callback(uri, res)
      urify(res.header['location'][0])
    end
    client.redirect_uri_callback = client.method(:allow_all_redirection_callback)
    client.get_content url
  end

  # TDLのショーの情報を取得
  def fetch_tdl_greeting
    Thread.new {
      client = HTTPClient.new
      url = 'http://info.tokyodisneyresort.jp/s/daily_schedule/show/tdl_' + today + '.html'
      client.get(url)
    }.next { |response|
      charset = response.body_encoding.name
      doc = Nokogiri::HTML.parse(response.content, nil, charset)
      doc.xpath('//*[@id="greeting"]/li')
    }.next { |doc|
      [Plugin::TDR::Park.new(
          name: '東京ディズニーランド パレード/ショー',
          profile_image_url: File.join(File.dirname(__FILE__), 'tdl.png')
      ), doc]
    }.next { |park, doc|
      doc.map do |greeting|
        name = greeting.css('h3').text.gsub(/(\s)/, '')
        times = greeting.css('p.time').text
        link = greeting.css('a').attribute('href')
        time = Time.new(Date.today.year, Date.today.mon, Date.today.day)
        text = name + "\n" + times
        if /\d+:\d+/ === times
          time = times.match(/\d+:\d+/)[0]
        end
        Plugin::TDR::Greeting.new(
            title: name,
            text: text,
            link: link,
            created: Time.now,
            modified: time,
            park: park
        )
      end
    }.next { |msgs|
      Plugin.call :appear, msgs
      Plugin.call :extract_receive_message, :mikutter_tdl_greeting, msgs
    }.trap { |e| error e }
  end

  # TDSのショーの情報を取得
  def fetch_tds_greeting
    Thread.new {
      client = HTTPClient.new
      url = 'http://info.tokyodisneyresort.jp/s/daily_schedule/show/tds_' + today + '.html'
      client.get(url)
    }.next { |response|
      charset = response.body_encoding.name
      doc = Nokogiri::HTML.parse(response.content, nil, charset)
      doc.xpath('//*[@id="greeting"]/li')
    }.next { |doc|
      [Plugin::TDR::Park.new(
          name: '東京ディズニーシー パレード/ショー',
          profile_image_url: File.join(File.dirname(__FILE__), 'tds.png')
      ), doc]
    }.next { |park, doc|
      doc.map do |greeting|
        name = greeting.css('h3').text.gsub(/(\s)/, '')
        times = greeting.css('p.time').text
        link = greeting.css('a').attribute('href')
        time = Time.new(Date.today.year, Date.today.mon, Date.today.day)
        text = name + "\n" + times
        if /\d+:\d+/ === times
          time = times.match(/\d+:\d+/)[0]
        end
        Plugin::TDR::Greeting.new(
            title: name,
            text: text,
            link: link,
            created: Time.now,
            modified: time,
            park: park
        )
      end
    }.next { |msgs|
      Plugin.call :appear, msgs
      Plugin.call :extract_receive_message, :mikutter_tds_greeting, msgs
    }.trap { |e| error e }
  end

  # アトラクションのアップデートを5分ごとに繰り返し実行
  def reserver_attraction
    Reserver.new(300) {
      fetch_tdl_attraction
      fetch_tds_attraction
      reserver_attraction
    }
  end

  # TDLのアトラクションの情報を取得
  def fetch_tdl_attraction
    Thread.new {
      url = 'http://info.tokyodisneyresort.jp/rt/s/gps/tdl_index.html' +
          '?nextUrl=http://info.tokyodisneyresort.jp/rt/s/realtime/tdl_attraction.html' +
          '&lat=35.6329527&lng=139.8840281'
      get_content_with_redirection(url)
    }.next { |response|
      doc = Nokogiri::HTML.parse(response, nil, 'utf-8')
      doc.css('ul#atrc.schedule').css('li')
    }.next { |doc|
      [Plugin::TDR::Park.new(
          name: '東京ディズニーランド アトラクション',
          profile_image_url: File.join(File.dirname(__FILE__), 'tdl.png')
      ), doc]
    }.next { |park, doc|
      count = 0
      doc.map do |attraction|
        name = attraction.css('h3').text.gsub(/(\s)/, '')
        wait_time = attraction.css('p.waitTime').text.gsub(/(\s)/, '')
        run_time = attraction.css('p.run').text.gsub(/(\s)/, '')
        fp_time = attraction.css('p.fp').text.gsub(/(\s)/, '')
        link = attraction.css('a').attribute('href')
        text = name + "\n" + run_time
        text = text + "\n待ち時間: " + wait_time if(wait_time != '')
        text = text + "\nFP: " + fp_time if(fp_time != '')
        count += 1
        Plugin::TDR::Attraction.new(
            title: name,
            text: text,
            link: link,
            created: Time.now,
            modified: Time.now - count,
            park: park
        )
      end
    }.next { |msgs|
      Plugin.call :destroyed, @saved_tdl_attractions
      Plugin.call :appear, msgs
      Plugin.call :extract_receive_message, :mikutter_tdl_attraction, msgs
      @saved_tdl_attractions = msgs
    }.trap { |e| error e }
  end

  # TDSのアトラクションの情報を取得
  def fetch_tds_attraction
    Thread.new {
      url = 'http://info.tokyodisneyresort.jp/rt/s/gps/tds_index.html' +
          '?nextUrl=http://info.tokyodisneyresort.jp/rt/s/realtime/tds_attraction.html' +
          '&lat=35.6329527&lng=139.8840281'
      get_content_with_redirection(url)
    }.next { |response|
      doc = Nokogiri::HTML.parse(response, nil, 'utf-8')
      doc.css('ul#atrc.schedule').css('li')
    }.next { |doc|
      [Plugin::TDR::Park.new(
          name: '東京ディズニーシー アトラクション',
          profile_image_url: File.join(File.dirname(__FILE__), 'tds.png')
      ), doc]
    }.next { |park, doc|
      count = 0
      doc.map do |attraction|
        name = attraction.css('h3').text.gsub(/(\s)/, '')
        wait_time = attraction.css('p.waitTime').text.gsub(/(\s)/, '')
        run_time = attraction.css('p.run').text.gsub(/(\s)/, '')
        fp_time = attraction.css('p.fp').text.gsub(/(\s)/, '')
        link = attraction.css('a').attribute('href')
        text = name + "\n" + run_time
        text = text + "\n待ち時間: " + wait_time if(wait_time != '')
        text = text + "\nFP: " + fp_time if(fp_time != '')
        count += 1
        Plugin::TDR::Attraction.new(
            title: name,
            text: text,
            link: link,
            created: Time.now,
            modified: Time.now - count,
            park: park
        )
      end
    }.next { |msgs|
      Plugin.call :destroyed, @saved_tds_attractions
      Plugin.call :appear, msgs
      Plugin.call :extract_receive_message, :mikutter_tds_attraction, msgs
      @saved_tds_attractions = msgs
    }.trap { |e| error e }
  end
end
