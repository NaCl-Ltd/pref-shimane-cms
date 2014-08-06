module Concerns::Susanoo::Admin::DivisionsController
  extend ActiveSupport::Concern

  included do
    before_action :admin_required
    before_action :set_division, only: %i(edit update destroy)

    #
    # GET /susanoo/admin/divisions
    #=== 部局一覧
    #
    def index
      @divisions = ::Division.order("number")
    end

    # GET /susanoo/admin/divisions/1
    def show
    end

    #
    # GET /susanoo/admin/divisions/new
    #=== 部局作成画面
    #
    def new
      @division = ::Division.new(enable: true)
    end

    #
    # GET /susanoo/admin/divisions/1/edit
    #=== 部局編集画面
    #
    def edit
    end

    #
    # POST /susanoo/admin/divisions
    #=== 部局作成処理
    #
    def create
      @division = ::Division.new(division_params)
      max = ::Division.maximum(:number).to_i + 1
      @division.number = max

      if @division.save
        redirect_to(main_app.susanoo_admin_divisions_path, notice: t(".success"))
      else
        render action: 'new'
      end
    end

    #
    # PATCH/PUT /susanoo/admin/divisions/1
    #=== 部局更新処理
    #
    def update
      @division.attributes = division_params
      if @division.save
        redirect_to(main_app.susanoo_admin_divisions_path, notice: t(".success"))
      else
        render action: 'edit'
      end
    end

    #
    # DELETE /susanoo/admin/divisions/1
    #=== 部局削除処理
    #
    def destroy
      if current_user.section && @division != current_user.section.division
        @division.destroy
        redirect_to(main_app.susanoo_admin_divisions_path, notice: t('.success', name: @division.name))
      else
        redirect_to(main_app.susanoo_admin_divisions_path, alert: t('.cant_destroy_current'))
      end
    end

    #
    # POST /susanoo/admin/divisions/update_sort
    #=== 部局の並び替え更新処理(Ajax)
    #
    def update_sort
        begin
        ::Division.transaction do
          @divisions = params[:item].map.with_index do |division_id, i|
            division = ::Division.find(division_id.to_i)
            division.update!(number: i)
            division
          end
        end
        render(partial: 'sort')
      rescue => e
        logger.error("Error while sorting division: #{e.message}")
        @divisions = []
        render(partial: 'sort')
      end
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_division
        @division = ::Division.find(params[:id])
      end

      # Only allow a trusted parameter "white list" through.
      def division_params
        params[:division].permit(:name, :enable)
      end
  end
end
