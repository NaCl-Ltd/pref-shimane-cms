module Concerns::WebMonitor::Validation
  extend ActiveSupport::Concern

 included do
    attr_accessor :password_confirmation

    validates :name, presence: true

    validates :login,
      presence: true,
      uniqueness: { scope: :genre_id },
      length: { in: 3..20 }

    validates :password,
      presence: true,
      length: { in: 6..12 },
      confirmation: true,
      if: :password_validation_required?

    validates :password_confirmation,
      presence: true,
      if: :password_validation_required?

    validate :login_changed_validation, if: :persisted?

    before_validation :undo_password, unless: :password_change_tried?, on: :update

    private

      def password_validation_required?
        new_record? ||
          (password_changed? || password_confirmation.present?)
      end

      def password_change_tried?
        password.present? || password_confirmation.present?
      end

      def undo_password
        self.password = password_was
      end

      def login_changed_validation
        if login_changed? && !password_changed?
          errors.add(:base, :login_changed)
        end
      end
  end
end
