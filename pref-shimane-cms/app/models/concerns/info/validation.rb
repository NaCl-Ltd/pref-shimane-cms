module Concerns::Info::Validation
  extend ActiveSupport::Concern

  included do
    validates :content, presence: true
    validates :title, presence: true, length: { in: 1..20 }
  end
end
