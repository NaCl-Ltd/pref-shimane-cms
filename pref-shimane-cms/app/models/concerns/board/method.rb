module Concerns::Board::Method
  extend ActiveSupport::Concern

  included do
  end

  module ClassMethods
  end

  #=== アクセス権限があるか？
  def accessible?(user)
    user.admin? || user.section_id == self.section_id
  end
end
