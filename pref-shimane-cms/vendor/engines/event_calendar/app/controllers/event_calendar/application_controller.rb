module EventCalendar
  class ApplicationController < ActionController::Base
    include Concerns::ApplicationController
    layout 'layouts/application'
    helper ::ApplicationHelper

    before_action :login_required

    private

    #=== エンジンが有効かを判定する。
    # 無効の場合リダイレクトする。
    def enable_engine_required
      unless EngineMaster.enable?(EventCalendar::Engine.engine_name)
        flash[:alert] = t("shared.engines.disable")
        return redirect_to(main_app.susanoo_dashboards_path)
      end
    end
  end
end
