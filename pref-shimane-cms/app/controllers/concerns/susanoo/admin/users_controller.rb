#
#= ユーザ管理・認証用コントローラのアクションを定義するモジュール
#
module Concerns::Susanoo::Admin::UsersController
  extend ActiveSupport::Concern

  included do
    before_action :admin_required
    before_action :set_user, only: %i(show edit update destroy)

    #
    #=== 一覧画面表示
    #
    def index
      @users = ::User.all.page(params[:page])
      @users.where!(section_id: params[:section_id]) if params[:section_id].present?
      if request.xhr?
        render partial: 'user_row', locals: {users: @users}
      end
    end

    #
    #=== ユーザ作成画面
    #
    def new
      @user = ::User.new
    end

    #
    #=== ユーザ編集画面
    #
    def edit
    end

    #
    #=== ユーザ作成
    #
    def create
      @user = ::User.new(user_params)
      if @user.save
        redirect_to main_app.susanoo_admin_users_path, notice: t(".success")
      else
        render :new
      end
    end

    #
    #=== 更新処理
    #
    def update
      if @user.update(user_params_as_update)
        redirect_to main_app.susanoo_admin_users_path, notice: t(".success")
      else
        render action: 'edit'
      end
    end

    #
    #=== 削除処理
    #
    def destroy
      @user.destroy
      redirect_to main_app.susanoo_admin_users_path, notice: t(".success")
    end

    private

      #
      #=== ユーザ情報を設定する
      #
      def set_user
        @user = ::User.find(params[:id])
      end

      def user_params
        params.require(:user).permit(:name, :login, :password, :password_confirmation, :mail, :section_id, :authority)
      end

      def user_params_as_update
        if params[:user][:password].present? && params[:user][:password_confirmation].present?
          params.require(:user).permit(:name, :login, :password, :password_confirmation, :mail, :section_id, :authority)
        else
          params.require(:user).permit(:name, :login, :mail, :section_id, :authority)
        end
      end
  end
end
