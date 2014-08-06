module Concerns::Susanoo::Admin::EnginesController
  extend ActiveSupport::Concern

  included do
    before_action :admin_required
    before_action :set_engine, only: %i(change_state)

    # GET /susanoo/admin/engines
    def index
      ::EngineMaster.engine_classes.each do |engine_klass|
        unless ::EngineMaster.where(name: engine_klass.engine_name).exists?
          ::EngineMaster.create(name: engine_klass.engine_name)
        end
      end
      @engines = ::EngineMaster.order("id")
    end

    # POST /susanoo/admin/engines/:id/change_state
    def change_state
      @engine.enable = !@engine.enable
      if @engine.save
        return redirect_to(main_app.susanoo_admin_engines_path, notice: t(".success"))
      else
        return redirect_to(main_app.susanoo_admin_engines_path, alert: t(".alert"))
      end
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_engine
        @engine = ::EngineMaster.find(params[:id])
      end
  end
end
