module Concerns::Help::Validation
  extend ActiveSupport::Concern

  included do
    validates :name, presence: true
    validates :help_category_id, presence: true
  end
end
