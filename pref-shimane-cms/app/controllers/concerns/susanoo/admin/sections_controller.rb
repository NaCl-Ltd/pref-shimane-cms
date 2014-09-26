#
#= 所属管理用コントローラのアクションを定義するモジュール
#
module Concerns::Susanoo::Admin::SectionsController
  extend ActiveSupport::Concern

  included do
    before_action :admin_required
    before_action :set_section, only: %i(edit update destroy)

    #
    #== 一覧画面表示
    #
    def index
      if request.xhr?
        if params[:division_id].present?
          # 部局での絞り込み時
          @display_navigation = false
          @sections = ::Section.where(division_id: params[:division_id]).includes(:users).order("number")
        else
          # 全部局表示
          @display_navigation = true
          @sections = ::Section.order("number").includes(:users).page(params[:page])
        end

        return render(partial: 'search')
      else
        @display_navigation = true
        @sections = ::Section.order('division_id, number').includes(:users).page(params[:page])
        @divisions = ::Division.order("number")
      end
    end

    #
    #== 登録画面表示
    #
    def new
      @section = ::Section.new
      @divisions = ::Division.order("number")
    end

    #
    #== 編集画面表示
    #
    def edit
      @divisions = ::Division.order("number")
    end

    #
    #== 登録処理
    #
    def create
      @divisions = Division.order("number")
      @section = Section.new(section_params)
      if @section.create_new_section(params[:genre])
        redirect_to(main_app.susanoo_admin_sections_path, notice: t(".success"))
      else
        render(action: 'new')
      end
    end

    #
    #== 更新処理
    #
    def update
      genre_id = params[:genre][:id].to_i
      @section.attributes = section_params
      @section.top_genre_id = genre_id.zero? ? nil : genre_id
      if @section.save
        redirect_to(main_app.susanoo_admin_sections_path, notice: t(".success"))
      else
        edit
        render action: 'edit'
      end
    end

    #
    #== 削除処理
    #
    def destroy
      if @section != current_user.section
        begin
          Section.transaction do
            @section.genres.update_all(section_id: Section.super_section_id)
            @section.destroy
          end
          redirect_to(main_app.susanoo_admin_sections_path, notice: t(".success", name: @section.name))
        rescue => e
          logger.error("Error while destroy section: #{e.message}")
          redirect_to(main_app.susanoo_admin_sections_path)
        end
      else
        redirect_to(main_app.susanoo_admin_sections_path, alert: t('.cant_destroy_current'))
      end
    end

    # POST /susanoo/admin/sections/update_sort
    # === 所属の並び替え更新処理(Ajax)
    def update_sort
      ::Section.transaction do
        @sections = params[:item].map.with_index do |section_id, i|
          section = Section.find(section_id.to_i)
          section.update!(number: i)
          section
        end
      end
      return render(partial: 'sort')
    rescue => e
      logger.error("Error while sorting section: #{e.message}")
      @error = t(".failed")
      return render(partial: 'sort')
    end

    private
      #
      #= 所属情報を設定する
      #
      def set_section
        @section = ::Section.find(params[:id])
      end

      #
      #= リクエストパラメータチェック
      #
      def section_params
        params[:section].permit(:name, :code, :ftp, :link, :division_id,
                                :skip_accessibility_check, :feature, :domain_part)
      end
  end
end
