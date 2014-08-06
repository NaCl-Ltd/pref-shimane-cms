module Concerns::HelpCategory::Association
  extend ActiveSupport::Concern

  included do
    acts_as_tree order: "number"
    has_many :helps
  end
end
