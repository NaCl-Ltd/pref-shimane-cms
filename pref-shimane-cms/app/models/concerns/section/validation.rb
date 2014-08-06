module Concerns::Section::Validation
  extend ActiveSupport::Concern

  included do
    validates :name, presence: true
    validates :code, presence: true
    validates :ftp,
      uniqueness: {:if => Proc.new{|u| !u.ftp.blank?}},
      format: {
        :if => Proc.new{|u| !u.ftp.blank?},
        with: /\A\/contents\/[\/\w]*\z/
      }
    validates :feature, presence: true
  end
end
