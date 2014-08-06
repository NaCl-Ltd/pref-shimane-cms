#
#= お知らせの管理機能を定義するモジュール
#
module Concerns::Susanoo::Admin::InfosController
  extend ActiveSupport::Concern

  included do
    before_action :admin_required
    before_action :set_info, only: %i(show edit update destroy)

    #
    #== 一覧画面表示
    #
    def index
      @infos = ::Info.order(last_modified: :desc).page(params[:page])
    end

    #
    #== お知らせ作成画面
    #
    def new
      @info = ::Info.new
    end

    #
    #== お知らせ詳細表示機能
    #
    def show
    end

    #
    #== お知らせ編集画面
    #
    def edit
    end

    #
    #== お知らせ作成
    #
    def create
      @info = ::Info.new(info_params)
      if @info.save
        redirect_to main_app.susanoo_admin_infos_path, notice: t(".success")
      else
        render :new
      end
    end

    #
    #== 更新処理
    #
    def update
      if @info.update(info_params)
        redirect_to main_app.susanoo_admin_infos_path, notice: t(".success")
      else
        render action: 'edit'
      end
    end

    #
    #== 削除処理
    #
    def destroy
      @info.destroy
      redirect_to main_app.susanoo_admin_infos_path, notice: t(".success")
    end

    private

      #
      #== お知らせ情報を設定する
      #
      def set_info
        @info = ::Info.find(params[:id])
      end

      def info_params
        params.require(:info).permit(:title, :last_modified, :content)
      end

  end
end
