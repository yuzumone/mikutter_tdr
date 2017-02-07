# -*- coding: utf-8 -*-

module Plugin::TDR
  class Restaurant < Retriever::Model
    include Retriever::Model::MessageMixin

    register :mikutter_tdr_greeting,
             name:'TDR Restaurant',
             timeline: true,
             reply: false,
             myself: false

    field.string :title, required: true
    field.string :text
    field.string :link
    field.time   :created
    field.time   :modified
    field.has    :park, Plugin::TDR::Park, required: true

    def to_show
      text
    end

    def user
      park
    end

    def perma_link
      link || nil
    end
  end
end