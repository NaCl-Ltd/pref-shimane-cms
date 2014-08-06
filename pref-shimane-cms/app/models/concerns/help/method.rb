module Concerns::Help::Method
  extend ActiveSupport::Concern

  included do
    START_INDEX = 1
    PRIVATE = 0
    PUBLIC = 1

    paginates_per 10

    scope :search, -> (keyword) { where("name LIKE ?", "%#{keyword}%") }
    scope :private, -> { where('public = ?', PRIVATE) }
    scope :showing, -> { where('public = ?', PUBLIC) }
    scope :order_by_number_nulls_first, -> {
      order("(#{arel_table[:number].eq(nil).to_sql}) DESC").order(:number) }
  end

  module ClassMethods
  end
end
