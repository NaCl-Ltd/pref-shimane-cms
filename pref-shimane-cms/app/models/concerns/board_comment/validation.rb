module Concerns::BoardComment::Validation
  extend ActiveSupport::Concern

  included do
    validates :from, presence: true
    validates :body, presence: true
    validates :board_id, presence: true
  end
end
