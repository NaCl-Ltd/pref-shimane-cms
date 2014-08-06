module Concerns::MailmagazineContent::Association
  extend ActiveSupport::Concern

  included do
    belongs_to :mailmagazine
  end
end
