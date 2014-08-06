#
#= ユーザ管理・認証用コントローラのアクションを定義するモジュール
#
module Concerns::Susanoo::UsersController
  extend ActiveSupport::Concern

  included do
    skip_before_action :feature_check, only: %i(login authenticate logout)
    before_action :page_header_not_required, only: %i(login authenticate)
    before_action :login_not_required, only: %i(login authenticate)
    before_action :login_required, only: %i(index new create show edit update logout)
    before_action :set_user, only: %i(show destroy)

    #
    #== 一覧画面表示
    #
    def index
      @users = ::User.all
    end

    #
    #== 詳細画面表示
    #
    def show
    end

    #
    #== 登録画面表示
    #
    def new
      @user = ::User.new
    end

    #
    #== 編集画面表示
    #
    def edit
      @user = current_user
    end

    #
    #== 登録処理
    #
    def create
      @user = ::User.new(user_params)

      if @user.save
        redirect_to @user, notice: 'Test was successfully created.'
      else
        render action: 'new'
      end
    end

    #
    #== 更新処理
    #
    def update
      @user = current_user

      now_user_params = params.require(:user).require(:now).permit(:password)
      unless User.authenticate(now_user_params.merge(login: @user.login))
        @user.errors.add(:base, t(".password_mismatch"))
        render action: 'edit'
        return
      end

      new_user_params = params.require(:user).require(:new).permit(:password, :password_confirmation)
      if @user.update(new_user_params)
        redirect_to edit_susanoo_user_path, notice: t(".success")
      else
        render action: 'edit'
      end
    end

    #
    #== 削除処理
    #
    def destroy
      @user.destroy
      redirect_to users_path, notice: 'Test was successfully destroyed.'
    end

    #
    #== ログイン画面表示
    #
    def login
      @user = ::User.new
      @infos = ::Info.order(last_modified: :desc).to_a
    end

    #
    #== ログイン処理
    # ログイン後画面へ直接リクエストされた場合は、ログイン後指定されたURLへリダイレクトする
    #
    def authenticate
      valid = false
      @user = ::User.authenticate(params[:user])
      if @user.present? && @user.section.susanoo?
        valid = true
      end

      if valid
        session[:current_user] = @user.id
        redirect_to susanoo_dashboards_path, notice: t(".success")
      else
        @user = ::User.new(login: params[:user].try(:fetch, :login), password: nil)
        @infos = ::Info.order(last_modified: :desc).to_a
        flash[:alert] = t(".failure")
        render action: :login
      end
    end

    #
    #== ログアウト処理
    # ユーザセッションを破棄し、ログイン画面へ遷移する
    #
    def logout
      session.delete(:current_user)
      redirect_to main_app.login_susanoo_users_path, notice: t(".success")
    end

    private
      #
      #= ユーザ情報を設定する
      #
      def set_user
        @user = ::User.find(params[:id])
      end

      #
      #= リクエストパラメータチェック
      #
      def user_params
        params[:user]
      end
  end
end
