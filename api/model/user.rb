# -*- coding: utf-8 -*-

module Plugin::TDR
  class User < Diva::Model
    include Diva::Model::UserMixin

    field.string :name, required: true
    field.string :profile_image_url

    def idname
      name
    end

    def user
      self
    end

    def profile_image_url_large
      profile_image_url
    end

    def verified?
      false
    end

    def protected?
      false
    end
  end
end
