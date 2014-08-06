module Concerns::MailmagazineContent::Method
  extend ActiveSupport::Concern

  included do
    before_save :set_datetime
    before_create :set_no

    private

      def set_no
        maximum_number = MailmagazineContent.where(send_mailmagazine_id: self.send_mailmagazine_id).maximum(:no)
        self.no = maximum_number.to_i + 1
      end

      def set_datetime
        self.datetime = Time.now
      end
  end

  module ClassMethods
  end
end
