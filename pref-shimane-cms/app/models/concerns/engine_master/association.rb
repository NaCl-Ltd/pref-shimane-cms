module Concerns::EngineMaster::Association
  extend ActiveSupport::Concern

  included do
    scope :eq_enable, ->{
      where(enable: true)
    }
  end
end
