# -*- coding: utf-8 -*-

module Plugin::TDR
  class Information < Retriever::Model
    include Retriever::Model::MessageMixin

    register :mikutter_tdr_information,
             name:'TDR情報',
             timeline: true,
             reply: false,
             myself: false

    field.string :name, required: true
    field.string :text, required: true
    field.string :link
    field.time   :created
    field.time   :modified
    field.has    :user, Plugin::TDR::User, required: true

    def to_show
      text
    end

    def perma_link
      link || nil
    end
  end
end
