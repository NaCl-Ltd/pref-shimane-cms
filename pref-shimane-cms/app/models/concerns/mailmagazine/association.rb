module Concerns::Mailmagazine::Association
  extend ActiveSupport::Concern

  included do
    belongs_to :section
    has_many :sent_mailmagazines, -> {order("id DESC")}, dependent: :destroy
  end
end
