# -*- coding: utf-8 -*-

module Plugin::TDR
  class Restaurant < Retriever::Model
    include Retriever::Model::MessageMixin

    register :mikutter_tdr_greeting,
             name:'TDR Restaurant',
             timeline: true,
             reply: false,
             myself: false

    field.string :name, required: true
    field.string :run_time
    field.string :op_left
    field.string :op_right
    field.string :wait_time
    field.string :link
    field.time   :created
    field.time   :modified
    field.has    :park, Plugin::TDR::Park, required: true

    def to_show
      text = name
      text = text + "\n" + run_time unless run_time.empty?
      text = text + "\n" + op_left unless op_left.empty?
      text = text + "\n" + op_right unless op_right.empty?
      text = text + "\n" + wait_time unless wait_time.empty?
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