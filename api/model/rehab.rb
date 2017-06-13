# -*- coding: utf-8 -*-

module Plugin::TDR
  class Rehab < Retriever::Model
    include Retriever::Model::MessageMixin

    register :mikutter_tdr_rehab,
             name:'リハブ情報',
             timeline: true,
             reply: false,
             myself: false

    field.string :name, required: true
    field.string :date
    field.time   :created
    field.time   :modified
    field.has    :park, Plugin::TDR::Park, required: true

    def to_show
      "#{name}\n#{date}"
    end

    def user
      park
    end

    def perma_link
      nil
    end
  end
end