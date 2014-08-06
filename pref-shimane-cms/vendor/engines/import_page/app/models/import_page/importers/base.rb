module ImportPage::Importers
  class Base
    extend ActiveModel::Translation

    cattr_accessor :logger
    self.logger = Rails.logger

    attr_accessor :messages
    attr_accessor :section_id, :genre, :path, :user_id

    def self.i18n_message_scope
      "#{i18n_scope}.errors.models.#{model_name.i18n_key}.attributes.base"
    end

    def initialize(section_id, genre, user_id, path)
      @messages = []
      @section_id = section_id
      @genre = genre
      @path = path
      @user_id = user_id
    end
  end
end
