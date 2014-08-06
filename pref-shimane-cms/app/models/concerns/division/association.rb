module Concerns::Division::Association
  extend ActiveSupport::Concern

  included do
    has_many :sections, -> {order('number')}
  end
end
