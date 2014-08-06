module Concerns::SentMailmagazine::Method
  extend ActiveSupport::Concern

  included do
    belongs_to :mailmagazine
  end

  module ClassMethods
  end
end
