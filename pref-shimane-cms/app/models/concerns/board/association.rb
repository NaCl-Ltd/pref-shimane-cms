module Concerns::Board::Association
  extend ActiveSupport::Concern

  included do
    belongs_to(:section)
    has_many(:comments, class_name: "BoardComment", dependent: :destroy)
  end
end
