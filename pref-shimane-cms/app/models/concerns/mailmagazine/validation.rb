module Concerns::Mailmagazine::Validation
  extend ActiveSupport::Concern

  included do
    validates :mail_address, format: /\A[\S]+@#{Regexp.quote(Settings.mailmagazine.domain)}\z/
  end
end
