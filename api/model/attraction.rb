# -*- coding: utf-8 -*-

module Plugin::TDR
  class Attraction < Retriever::Model
    include Retriever::Model::MessageMixin

    register :mikutter_tdr_attraction,
             name:'TDR Attraction',
             timeline: true,
             reply: false,
             myself: false
    
    field.string :name, required: true
    field.string :wait_time
    field.string :run_time
    field.string :fp_time
    field.string :link
    field.time   :created
    field.time   :modified
    field.has    :park, Plugin::TDR::Park, required: true

    def to_show
      text = name
      text = text + "\n" + run_time unless run_time.empty?
      text = text + "\n待ち時間: " + wait_time unless wait_time.empty?
      text = text + "\nFP: " + fp_time unless fp_time.empty?
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
