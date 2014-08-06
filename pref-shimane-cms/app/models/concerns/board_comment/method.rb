module Concerns::BoardComment::Method
  extend ActiveSupport::Concern

  included do
    before_save :normalize_newlines

    scope :publishes, -> {where(public: true)}
    scope :unpublishes, -> {where(public: false)}
    scope :nil_publics, -> {where(public: nil)}
  end

  module ClassMethods
  end

  private
    #=== 改行コードの統一
    def normalize_newlines
      self.body = self.body.gsub(/\r\n/u, "\n")
    end
end
