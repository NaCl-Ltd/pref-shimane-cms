module Concerns::Help::Association
  extend ActiveSupport::Concern

  included do
    belongs_to :help_category
    belongs_to :help_content
    accepts_nested_attributes_for :help_content
  end
end
