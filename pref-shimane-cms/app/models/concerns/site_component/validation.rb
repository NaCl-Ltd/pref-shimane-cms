module Concerns::SiteComponent::Validation
  extend ActiveSupport::Concern

  included do
    validates :name, uniqueness: true
  end
end
