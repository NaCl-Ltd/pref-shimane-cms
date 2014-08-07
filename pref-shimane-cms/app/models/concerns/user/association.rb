#
#= User の属性、アソシエーションを管理するモジュール
#
module Concerns::User::Association
  extend ActiveSupport::Concern

  included do

    #
    #=== 権限
    # * +:editor+     - ホームページ担当者
    # * +:authorizer+ - 情報提供責任者
    # * +:admin+      - 運用管理者
    #
    @@authorities = {editor: 0, authorizer: 1, admin: 2}.with_indifferent_access

    # 暗号化ソルト
    @@salt = Settings.auth.salt

    cattr_reader :salt, :authorities

    belongs_to :section

  end
end
