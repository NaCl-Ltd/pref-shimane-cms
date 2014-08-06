#
#= User の バリデーションを管理するモジュール
#
module Concerns::User::Validation
  extend ActiveSupport::Concern

  # バリデーション
  included do
    validates :login,
      presence: true,
      uniqueness: true,
      length: { in: 3..20 },
      format: {with: /^[a-zA-Z0-9\_\-]+$/, multiline: true}

    validates :password,
      presence: true,
      length: {in: 8..12, if: :password_changed?},
      confirmation: true,
      format: {with: /^[a-zA-Z0-9\_\-]+$/, multiline: true}

    validates :password_confirmation,
      presence: {if: :password_changed?},
      format: {with: /^[a-zA-Z0-9\_\-]+$/, multiline: true, if: :password_changed?}

    validates :name, presence: true
    validates :section_id, presence: true
    validates :authority, presence: true
  end
end
