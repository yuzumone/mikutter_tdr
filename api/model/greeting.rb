# -*- coding: utf-8 -*-

module Plugin::TDR
  class Greeting < Retriever::Model
    include Retriever::Model::MessageMixin

    register :mikutter_tdr_greeting,
             name:'TDR Greeting',
             timeline: true,
             reply: false,
             myself: false

    field.string :name, required: true
    field.string :times
    field.string :link
    field.time   :created
    field.time   :modified
    field.has    :park, Plugin::TDR::Park, required: true

    def to_show
      "#{name}\n#{times}"
    end

    def user
      park
    end

    def perma_link
      link || nil
    end
  end
end