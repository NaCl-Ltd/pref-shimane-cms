module Concerns::MailmagazineContent::Validation
  extend ActiveSupport::Concern

  included do
    validates :content, presence: true
    validates :title, presence: true
  end
end
