# -*- coding: utf-8 -*-

Plugin.create(:mikutter_datasource_tdr) do
  require 'kconv'
  
  filter_extract_datasources { |datasources|
    begin
      datasources[:mikutter_tdl_greeting] = "TDR/TDL Greeting"
      datasources[:mikutter_tdl_attraction] = "TDR/TDL Attraction"
    rescue => e
      puts e
      puts e.backtrace
    end

    [datasources]
  }

  on_boot do
    fetch_tdl_greeting
    update_tdl_attraction
    reserver_tdl_attraction
  end

  # 今日の日付
  def today
    return Date.today.strftime("%Y%m%d")
  end

  # リダイレクト先のURLを取得
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
    url = 'http://info.tokyodisneyresort.jp/s/daily_schedule/show/tdl_' + today + '.html'
    charset = nil
    html = open(url) do |f|
      charset = f.charset
      f.read
    end

    msgs = []
    doc = Nokogiri::HTML(html.toutf8, nil, 'utf-8')
    greetings = doc.css('ul#greeting')
    greeting_list = greetings.css('li')
    greeting_list.each do |g|
      name = g.css('h3').text.gsub(/(\s)/,"")
      times = g.css('p.time').text
      text = name + "\n" + times
      if (/\d+:\d+/ === times)
        time = times.match(/\d+:\d+/)[0]
        msg = Message.new(:message => text , :system => true)
        msg[:modified] = Time.parse(time)
        user = User.new(:id => 3939, :idname => "TDL Greeting")
        user[:profile_image_url] = File.join(File.dirname(__FILE__), "tdl.png")
        msg[:user] = user
        msgs.push(msg)
      end
    end
    Plugin.call(:extract_receive_message, :mikutter_tdl_greeting, msgs)
  end

  # TDLアトラクションのアップデートを5分ごとに繰り返し実行
  def reserver_tdl_attraction
    Reserver.new(300) {
      update_tdl_attraction
      reserver_tdl_attraction
    }
  end

  # TDLのアトラクションのメッセージをアップデート
  def update_tdl_attraction
    @saved_tdl_attractions ||= []
    Plugin.call(:destroyed, @saved_tdl_attractions)
    @saved_tdl_attractions = fetch_tdl_attraction
    Plugin.call(:extract_receive_message, :mikutter_tdl_attraction, @saved_tdl_attractions)
  end

  # TDLのアトラクションの情報を取得
  def fetch_tdl_attraction
    msgs = []
    count = 0
    url = 'http://info.tokyodisneyresort.jp/rt/s/gps/tdl_index.html' +
          '?nextUrl=http://info.tokyodisneyresort.jp/rt/s/realtime/tdl_attraction.html' +
          # 下の位置情報は馬鹿には見えない
          '&lat=35.6329527&lng=139.8840281'
    html = get_content_with_redirection(url)
    doc = Nokogiri::HTML.parse(html, nil, 'utf-8')
    schedules = doc.css('ul#atrc.schedule')
    list = schedules.css('li')
    list.each do |s|
      name = s.css('h3').text.gsub(/(\s)/,"")
      wait_time = s.css('p.waitTime').text.gsub(/(\s)/,"")
      run_time = s.css('p.run').text.gsub(/(\s)/,"")
      fp_time = s.css('p.fp').text.gsub(/(\s)/,"")
      text = name + "\n" + run_time
      text = text + "\n待ち時間: " + wait_time unless(wait_time == "")
      text = text + "\nFP: " + fp_time unless (fp_time == "")
      msg = Message.new(:message => text , :system => true)
      msg[:modified] = Time.now - count
      count += 1
      user = User.new(:id => 3939, :idname => "TDL Attraction")
      user[:profile_image_url] = File.join(File.dirname(__FILE__), "tdl.png")
      msg[:user] = user
      msgs.push(msg)
    end
    return msgs
  end
end
