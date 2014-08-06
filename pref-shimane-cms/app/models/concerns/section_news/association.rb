module Concerns::SectionNews::Association
  extend ActiveSupport::Concern

  included do
    belongs_to :page
  end
end
