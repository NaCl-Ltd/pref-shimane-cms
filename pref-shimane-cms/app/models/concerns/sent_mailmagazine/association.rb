module Concerns::SentMailmagazine::Association
  extend ActiveSupport::Concern

  included do
    belongs_to :mailmagazine
    has_many :mailmagazine_contents, -> {order("no")},
     class_name: "MailmagazineContent",
     foreign_key: :send_mailmagazine_id,
     dependent: :destroy

  end
end
