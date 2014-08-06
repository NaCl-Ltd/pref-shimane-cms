#
#= User のクラスメソッド、インスタンスメソッドを管理するモジュール
#
module Concerns::User::Method
  extend ActiveSupport::Concern

  # インスタンスメソッド
  included do
    before_save :encrypt_password

    paginates_per 10

    #
    #=== パスワードを暗号化する
    #
    def encrypt_password
      self.password = ::User.encrypt(self.password) if self.password_changed?
    end

    #
    #=== ユーザ権限が情報提供管理者か運用管理者であるかを判定する
    #
    def authorizer_or_admin?
      admin? || authorizer?
    end

    #
    #=== ユーザ権限が運用管理者かどうか判定する
    #
    def admin?
      authority == authorities[:admin]
    end

    #
    #=== ユーザ権限が情報提供管理者かどうか判定する
    #
    def authorizer?
      authority == authorities[:authorizer]
    end

    #
    #=== ユーザ権限がホームページ者かどうか判定する
    #
    def editor?
      authority == authorities[:editor]
    end

    #
    #=== アクセシビリティチェックをスキップできるかどうかを返す
    #
    def skip_accessibility_check?
      if Settings.page_content.unchecked
        if admin?
          true
        else
          section && section.skip_accessibility_check
        end
      else
        false
      end
    end
  end

  # クラスメソッド
  module ClassMethods
    #
    #=== 文字列を暗号化する
    #
    def encrypt(text)
      Digest::SHA1.hexdigest("#{salt}--#{text}--")
    end

    #
    #=== 認証する
    #
    def authenticate(params={})
      if params[:login] && params[:password]
        where(login: params[:login], password: encrypt(params[:password])).first
      end
    end
  end
end
