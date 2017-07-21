# -*- coding: utf-8 -*-

module Plugin::TDR
  class Character < Retriever::Model
    include Retriever::Model::MessageMixin

    register :mikutter_tdr_attraction,
             name:'キャラクターグリーティング',
             timeline: true,
             reply: false,
             myself: false
    
    field.string :name, required: true
    field.string :wait_time
    field.string :op
    field.string :link
    field.time   :created
    field.time   :modified
    field.has    :park, Plugin::TDR::Park, required: true

    def to_show
      text = name
      text = text + "\n待ち時間: " + wait_time unless wait_time.empty?
      "#{text}\n#{op}"
    end
    
    def user
      park
    end

    def perma_link
      link || nil
    end
  end
end
