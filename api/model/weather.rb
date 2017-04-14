# -*- coding: utf-8 -*-

module Plugin::TDR
  class Weather < Retriever::Model
    include Retriever::Model::MessageMixin

    register :mikutter_tdr_weather,
             name:'Maihama Weather',
             timeline: true,
             reply: false,
             myself: false

    field.string :title, required: true
    field.string :text
    field.string :link
    field.time   :created
    field.time   :modified
    field.has    :site, Plugin::TDR::Site, required: true

    def to_show
      text
    end

    def user
      site
    end

    def perma_link
      link
    end
  end
end