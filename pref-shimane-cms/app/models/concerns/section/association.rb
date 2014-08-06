module Concerns::Section::Association
  extend ActiveSupport::Concern

  included do
    has_many(:users, -> {order("login")}, dependent: :destroy)
    has_many(:genres, ->{order("path")})
    has_many(:mailmagazines, -> {order("mail_address")})
    belongs_to(:genre, foreign_key: :top_genre_id)
    belongs_to(:division)

    paginates_per 10
  end
end
