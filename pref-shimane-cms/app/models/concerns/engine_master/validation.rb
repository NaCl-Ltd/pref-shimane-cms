module Concerns::EngineMaster::Validation
  extend ActiveSupport::Concern

  included do
    validates :name, uniqueness: true, presence: true
  end
end
