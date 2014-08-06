module Concerns::LostLink::Method
  extend ActiveSupport::Concern

  included do
    INSIDE_TYPE = 1
    OUTSIDE_TYPE = 2

    scope :insides, -> {where("side_type = ?", INSIDE_TYPE)}
    scope :outsides, -> {where("side_type = ?", OUTSIDE_TYPE)}
    scope :manages, -> user {where("section_id = ?", user.section_id)}
  end

  module ClassMethods
  end
end
