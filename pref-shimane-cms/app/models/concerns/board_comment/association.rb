module Concerns::BoardComment::Association
  extend ActiveSupport::Concern

  included do
    paginates_per 10
    belongs_to :board
  end
end
