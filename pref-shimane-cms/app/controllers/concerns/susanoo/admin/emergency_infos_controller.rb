#
#= 緊急お知らせ用コントローラのアクションを定義するモジュール
#
module Concerns::Susanoo::Admin::EmergencyInfosController
  extend ActiveSupport::Concern

  included do
    before_action :admin_required
    before_action :set_emergency_info, only: %i(edit update)

    #
    #=== 緊急お知らせ情報作成機能
    #
    def edit
    end

    #
    #=== 緊急お知らせ情報更新機能
    #
    def update
      if @emergency_info.update(emergency_info_params)
        redirect_to main_app.susanoo_dashboards_path, notice: t(".success")
      else
        render :edit
      end
    end

    #
    #=== 公開停止処理
    #
    def stop_public
      ::EmergencyInfo.stop_public
      redirect_to main_app.susanoo_dashboards_path, notice: t(".success")
    end

    private

      #
      #=== 緊急お知らせ情報インスタンスの取得
      # すでにレコードがあれば、取得し、なければ作成
      #
      def set_emergency_info
        unless @emergency_info = ::EmergencyInfo.first
          @emergency_info = ::EmergencyInfo.new
        end
      end

      def emergency_info_params
        params.require(:emergency_info).permit(:display_start_datetime, :display_end_datetime, :content)
      end
  end
end

