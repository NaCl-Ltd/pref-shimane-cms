#
#= アプリケーションコントローラのアクションを定義するモジュール
#
module Concerns::ApplicationController
  extend ActiveSupport::Concern

  included do
    require 'action_view/helpers/date_time_selector'

    # Prevent CSRF attacks by raising an exception.
    # For APIs, you may want to use :null_session instead.
    protect_from_forgery with: :exception

    before_action :feature_check

    helper_method :current_user
    helper_method :page_header_required?
    helper_method :footer_required?

    # プライベートメソッド
    private

      #
      #== ログイン中ユーザのユーザ情報を返す
      #
      def current_user
        return @current_user if defined?(@current_user)
        @current_user = ::User.find(session[:current_user]) if session[:current_user].present?
      end

      #
      #== リクエストURLをセッションに保存する
      #
      def store_location
        session[:return_to] = request.url
      end

      #
      #== リクエストURLまたはトップページへリダイレクトする
      #
      def redirect_back_or_default(default, options={})
        redirect_to(session[:return_to] || default, options)
        session[:return_to] = nil
      end

      #
      #== 認証チェック
      #
      def login_required
        unless current_user
          store_location
          redirect_to main_app.login_susanoo_users_path,
          notice: t("shared.notice.login_required")
          return false
        else
          return true
        end
      end

      #
      #== 未認証チェック
      #
      def login_not_required
        if current_user
          redirect_to main_app.susanoo_dashboards_path,
          notice: t("shared.notice.login_not_required")
          return false
        else
          return true
        end
      end

      #
      #== 情報提供管理者・運用管理者権限チェック
      # ログイン中のユーザの権限が情報提供管理者か運用管理者でない場合、
      # トップページへリダイレクトする
      #
      def authorizer_or_admin_required
        return false unless login_required
        unless current_user.authorizer_or_admin?
          redirect_to main_app.susanoo_dashboards_path,
          notice: t("shared.notice.no_authorization")
          return false
        else
          return true
        end
      end

      #
      #== 運用管理者権限チェック
      # ログイン中のユーザの権限が運用管理者でない場合、
      # トップページへリダイレクトする
      #
      def admin_required
        return false unless login_required
        unless current_user.admin?
          redirect_to main_app.susanoo_dashboards_path,
          notice: t("shared.notice.no_authorization")
          return false
        else
          return true
        end
      end

      #
      #== 404 NOT FOUND を返す
      #
      def render_missing
        render text: '404 NOT FOUND', status: 404
      end

      #
      #=== デフォルト表示するフォルダとフォルダツリーを取得する
      #
      def set_folder_tree
        if params[:genre_id]
          # フォルダを指定した場合
          @genre = Genre.by_id_and_authority(params[:genre_id], current_user).first
          @genre_tree = Genre.selected_treeview(current_user, @genre)
        else
          # フォルダを指定しない場合、ルートフォルダのうちIDの若いフォルダを表示する
          @genre = Genre.user_root(current_user).reorder('genres.id ASC').first
          @genre_tree = Genre.root_treeview(current_user)
        end
        @genre.present?
      end

      #
      #=== ページタイトルをレイアウトに表示するかを判定する
      #
      def page_header_not_required
        @page_header_not_required = true
      end

      #
      #=== ページタイトルをレイアウトに表示するかを判定する
      #
      def page_header_required?
        if @page_header_not_required.nil?
          true
        else
          !@page_header_not_required
        end
      end

      #
      #=== フッターをレイアウトに表示するかを判定する
      #
      def footer_not_required
        @footer_not_required = true
      end

      #
      #=== フッターをレイアウトに表示するかを判定する
      #
      def footer_required?
        if @footer_not_required.nil?
          true
        else
          !@footer_not_required
        end
      end

      #
      #=== 仕様できる機能に合致しているかどうかを判定する
      #
      def feature_check
        if params[:controller] != "susanoo/visitors"
          if current_user
            unless current_user.section.try(:susanoo?)
              render text: '403 Forbidden', status: 403
            end
          end
        end
      end

      #
      #=== Pageの操作権限を持つかどうかを返す
      #
      def page_permission_required(page = @page)
        if page.genre.has_permission?(current_user)
          true
        else
          raise NoPermissionError.new
        end
      end

      #
      #=== Genreの操作権限を持つかどうかを返す
      #
      def genre_permission_required(genre = @genre)
        if genre.has_permission?(current_user)
          true
        else
          raise NoPermissionError.new
        end
      end

      #
      # 操作可能なフォルダがない場合、トップページへ戻る
      #
      def genre_required
        genres = Genre.user_root(current_user)
        if genres.size == 0
          return redirect_to main_app.susanoo_dashboards_url, alert: t('shared.messages.genre_not_found')
        end
      end
  end
end

#
#=== フォルダやページのアクセス権限がない場合発生するれ以外
#
class NoPermissionError < StandardError; end
