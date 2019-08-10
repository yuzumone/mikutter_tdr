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

    private
    def reserver
      Reserver.new(300) {
        fetch_tdl
        fetch_tds
        reserver
      }
    end

    def fetch_tdl
      Thread.new {
        url = 'http://www.tokyodisneyresort.jp/_/realtime/tdl_greeting.json'
        res = Plugin::TDR::API.fetch url
        [Plugin::TDR::User.new(
          name: 'ディズニーランド グリーティング',
          profile_image_url: File.join(File.dirname(__FILE__), '../tdl.png')
        ), res]
      }.next { |park, res|
        data = analyze_tdl res
        msgs = create_message park, data
        Plugin.call :destroyed, @saved_tdl_greeting
        Plugin.call :appear, msgs
        Plugin.call :extract_receive_message, :mikutter_tdl_greeting, msgs
        @saved_tdl_greeting = msgs
      }.trap { |e| error e }
    end

    def fetch_tds
      Thread.new {
        url = 'http://www.tokyodisneyresort.jp/_/realtime/tds_greeting.json'
        res = Plugin::TDR::API.fetch url
        [Plugin::TDR::User.new(
          name: 'ディズニーシー グリーティング',
          profile_image_url: File.join(File.dirname(__FILE__), '../tds.png')
        ), res]
      }.next { |park, res|
        data = analyze_tds res
        msgs = create_message park, data
        Plugin.call :destroyed, @saved_tds_greeting
        Plugin.call :appear, msgs
        Plugin.call :extract_receive_message, :mikutter_tds_greeting, msgs
        @saved_tds_greeting = msgs
      }.trap { |e| error e }
    end

    def analyze_tdl data
      list = []
      data['id11']['Facility'].each { |facility| list.push(facility['greeting']) }
      data['id13']['Facility'].each { |facility| list.push(facility['greeting']) }
      data['id16']['Facility'].each { |facility| list.push(facility['greeting']) }
      list
    end

    def analyze_tds data
      list = []
      data['id21']['Facility'].each { |facility| list.push(facility['greeting']) }
      data['id22']['Facility'].each { |facility| list.push(facility['greeting']) }
      data['id25']['Facility'].each { |facility| list.push(facility['greeting']) }
      data['id26']['Facility'].each { |facility| list.push(facility['greeting']) }
      data['id27']['Facility'].each { |facility| list.push(facility['greeting']) }
      list
    end

    def create_message park, data
      data.map.with_index { |greeting, i|
        name = greeting['FacilityName']
        url = greeting['FacilityURLSP']
        time = greeting['StandbyTime']
        operatingHours = greeting['operatinghours']
        update = greeting['UpdateTime']
        operating = ''
        unless operatingHours.nil?
          operating = operatingHours.map { |item|
            from = item['OperatingHoursFrom']
            to = item['OperatingHoursTo']
            status = item['OperatingStatus']
            from.to_s + ' - ' + to.to_s + "\t" + status.to_s
          }.join("\n")
        end
        text = name
        text += "\n" + operating
        text += "\n" + time + ' 分' unless time.nil?
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

