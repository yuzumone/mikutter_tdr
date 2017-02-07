# -*- coding: utf-8 -*-

Plugin.create(:mikutter_tdr) do

  require 'rss'
  require_relative 'model'
  @saved_tdl_attractions ||= []
  @saved_tds_attractions ||= []
  @saved_tdl_restaurant ||= []
  @saved_tds_restaurant ||= []

  filter_extract_datasources { |datasources|
    begin
      datasources[:mikutter_tdl_greeting] = 'TDR/ディズニーランドパレード'
      datasources[:mikutter_tdl_attraction] = 'TDR/ディズニーランドアトラクション'
      datasources[:mikutter_tdl_restaurant] ='TDR/ディズニーランドレストラン'
      datasources[:mikutter_tds_greeting] = 'TDR/ディズニーシーパレード'
      datasources[:mikutter_tds_attraction] = 'TDR/ディズニーシーアトラクション'
      datasources[:mikutter_tds_restaurant] = 'TDR/ディズニーシーレストラン'
      datasources[:mikutter_tdr_weather] = 'TDR/舞浜の天気'
    rescue => e
      puts e
      puts e.backtrace
    end
    [datasources]
  }

  on_boot do
    fetch_tdl_attraction
    fetch_tdl_greeting
    fetch_tdl_restaurant
    fetch_tds_attraction
    fetch_tds_greeting
    fetch_tds_restaurant
    reserver_attraction
    reserver_restaurant
    weather
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
      msgs = []
      count = 0
      if doc.empty?
        msg = Plugin::TDR::Attraction.new(
            title: 'ただいま東京ディズニーランドは、閉園しております。',
            text: 'ただいま東京ディズニーランドは、閉園しております。',
            link: 'http://info.tokyodisneyresort.jp/s/calendar/tdl/',
            created: Time.now,
            modified: Time.now,
            park: park)
        msgs.push(msg)
      else
        doc.each do |attraction|
          name = attraction.css('h3').text.gsub(/(\s)/, '')
          wait_time = attraction.css('p.waitTime').text.gsub(/(\s)/, '')
          run_time = attraction.css('p.run').text.gsub(/(\s)/, '')
          fp_time = attraction.css('p.fp').text.gsub(/(\s)/, '')
          link = attraction.css('a').attribute('href')
          text = name + "\n" + run_time
          text = text + "\n待ち時間: " + wait_time if(wait_time != '')
          text = text + "\nFP: " + fp_time if(fp_time != '')
          count += 1
          msg = Plugin::TDR::Attraction.new(
              title: name,
              text: text,
              link: link,
              created: Time.now,
              modified: Time.now - count,
              park: park
          )
          msgs.push(msg)
        end
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
      msgs = []
      count = 0
      if doc.empty?
        msg = Plugin::TDR::Attraction.new(
            title: 'ただいま東京ディズニーシーは、閉園しております。',
            text: 'ただいま東京ディズニーシーは、閉園しております。',
            link: 'http://info.tokyodisneyresort.jp/s/calendar/tds/',
            created: Time.now,
            modified: Time.now,
            park: park
        )
        msgs.push(msg)
      else
        doc.each do |attraction|
          name = attraction.css('h3').text.gsub(/(\s)/, '')
          wait_time = attraction.css('p.waitTime').text.gsub(/(\s)/, '')
          run_time = attraction.css('p.run').text.gsub(/(\s)/, '')
          fp_time = attraction.css('p.fp').text.gsub(/(\s)/, '')
          link = attraction.css('a').attribute('href')
          text = name + "\n" + run_time
          text = text + "\n待ち時間: " + wait_time if(wait_time != '')
          text = text + "\nFP: " + fp_time if(fp_time != '')
          count += 1
          msg = Plugin::TDR::Attraction.new(
              title: name,
              text: text,
              link: link,
              created: Time.now,
              modified: Time.now - count,
              park: park
          )
          msgs.push(msg)
        end
      end
      msgs
    }.next { |msgs|
      Plugin.call :destroyed, @saved_tds_attractions
      Plugin.call :appear, msgs
      Plugin.call :extract_receive_message, :mikutter_tds_attraction, msgs
      @saved_tds_attractions = msgs
    }.trap { |e| error e }
  end

  # レストランのアップデートを5分ごとに繰り返し実行
  def reserver_restaurant
    Reserver.new(300) {
      fetch_tdl_restaurant
      fetch_tds_restaurant
      reserver_restaurant
    }
  end

  # TDLのレストランの情報を取得
  def fetch_tdl_restaurant
    Thread.new {
      url = 'http://info.tokyodisneyresort.jp/rt/s/gps/tdl_index.html' +
          '?nextUrl=http://info.tokyodisneyresort.jp/rt/s/realtime/tdl_restaurant.html' +
          '&lat=35.6280767&lng=139.883245'
      get_content_with_redirection(url)
    }.next { |response|
      doc = Nokogiri::HTML.parse(response, nil, 'utf-8')
      doc.css('ul#restaurant.schedule').css('li')
    }.next { |doc|
      [Plugin::TDR::Park.new(
          name: '東京ディズニーランド レストラン',
          profile_image_url: File.join(File.dirname(__FILE__), 'tdl.png')
      ), doc]
    }.next { |park, doc|
      msgs = []
      if doc.empty?
        msg = Plugin::TDR::Restaurant.new(
            title: 'ただいま東京ディズニーランドは、閉園しております。',
            text: 'ただいま東京ディズニーランドは、閉園しております。',
            link: 'http://info.tokyodisneyresort.jp/s/calendar/tdl/',
            created: Time.now,
            modified: Time.now,
            park: park
        )
        msgs.push(msg)
      else
        doc.each_with_index do |restaurant, i|
          name = restaurant.css('h3').text.gsub(/(\s)/, '')
          wait_time = restaurant.css('div.time').text.gsub(/(\s)/, '')
          op_left = restaurant.css('div.op-left').text.gsub(/(\s)/, '')
          op_right = restaurant.css('div.op-right').text.gsub(/(\s)/, '')
          run = restaurant.css('p.run').text.gsub(/(\s)/, '')
          text = name
          text = text + "\n" + run if(run != '')
          text = text + "\n" + op_left if(op_left != '')
          text = text + "\n" + op_right if(op_right != '')
          text = text + "\n" + wait_time if(wait_time != '')
          msg = Plugin::TDR::Restaurant.new(
              title: name,
              text: text,
              created: Time.now,
              modified: Time.now - i,
              park: park
          )
          unless restaurant.css('a').empty?
            msg.link = restaurant.css('a').attribute('href')
          end
          msgs.push(msg)
        end
      end
      msgs
    }.next { |msgs|
      Plugin.call :destroyed, @saved_tdl_restaurant
      Plugin.call :appear, msgs
      Plugin.call :extract_receive_message, :mikutter_tdl_restaurant, msgs
      @saved_tdl_restaurant = msgs
    }
  end

  # TDSのレストランの情報を取得
  def fetch_tds_restaurant
    Thread.new {
      url = 'http://info.tokyodisneyresort.jp/rt/s/gps/tds_index.html' +
          '?nextUrl=http://info.tokyodisneyresort.jp/rt/s/realtime/tds_restaurant.html' +
          '&lat=35.6280767&lng=139.883245'
      get_content_with_redirection(url)
    }.next { |response|
      doc = Nokogiri::HTML.parse(response, nil, 'utf-8')
      doc.css('ul#restaurant.schedule').css('li')
    }.next { |doc|
      [Plugin::TDR::Park.new(
          name: '東京ディズニーシー レストラン',
          profile_image_url: File.join(File.dirname(__FILE__), 'tds.png')
      ), doc]
    }.next { |park, doc|
      msgs = []
      if doc.empty?
        msg = Plugin::TDR::Restaurant.new(
            title: 'ただいま東京ディズニーシーは、閉園しております。',
            text: 'ただいま東京ディズニーシーは、閉園しております。',
            link: 'http://info.tokyodisneyresort.jp/s/calendar/tdl/',
            created: Time.now,
            modified: Time.now,
            park: park
        )
        msgs.push(msg)
      else
        doc.each_with_index do |restaurant, i|
          name = restaurant.css('h3').text.gsub(/(\s)/, '')
          wait_time = restaurant.css('div.time').text.gsub(/(\s)/, '')
          op_left = restaurant.css('div.op-left').text.gsub(/(\s)/, '')
          op_right = restaurant.css('div.op-right').text.gsub(/(\s)/, '')
          run = restaurant.css('p.run').text.gsub(/(\s)/, '')
          text = name
          text = text + "\n" + run if(run != '')
          text = text + "\n" + op_left if(op_left != '')
          text = text + "\n" + op_right if(op_right != '')
          text = text + "\n" + wait_time if(wait_time != '')
          msg = Plugin::TDR::Restaurant.new(
              title: name,
              text: text,
              created: Time.now,
              modified: Time.now - i,
              park: park
          )
          unless restaurant.css('a').empty?
            msg.link = restaurant.css('a').attribute('href')
          end
          msgs.push(msg)
        end
      end
      msgs
    }.next { |msgs|
      Plugin.call :destroyed, @saved_tds_restaurant
      Plugin.call :appear, msgs
      Plugin.call :extract_receive_message, :mikutter_tds_restaurant, msgs
      @saved_tds_restaurant = msgs
    }
  end

  # 天気情報を取得
  def weather
    Thread.new {
      rss = RSS::Parser.parse('https://rss-weather.yahoo.co.jp/rss/days/4510.xml')
      rss.items.reject { |item| item.description == '注意報があります' }
    }.next { |items|
      msgs = []
      items.each_with_index do |item, i|
        site = Plugin::TDR::Site.new(
            name: item.title.match(/【.+?】/),
            profile_image_url: File.join(File.dirname(__FILE__), 'weather.png')
        )
        weather = Plugin::TDR::Weather.new(
            title: item.title,
            text: item.description,
            link: item.link,
            created: Time.now,
            modified: Time.now - i,
            site: site
        )
        msgs.push(weather)
      end
      msgs
    }.next { |msgs|
      Plugin.call :appear, msgs
      Plugin.call :extract_receive_message, :mikutter_tdr_weather, msgs
    }.trap { |e| error e }
  end
end
