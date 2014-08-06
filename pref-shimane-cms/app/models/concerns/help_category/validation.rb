module Concerns::HelpCategory::Validation
  extend ActiveSupport::Concern

  included do
    validates :name, presence: true
  end
end
