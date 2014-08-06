require_dependency "consult_management/application_controller"

module ConsultManagement
  module Susanoo
    module Admin
      class ConsultsController < ApplicationController
        before_action :admin_required
        before_action :set_consult, only: [:show, :edit, :update, :destroy]
        before_action :set_consult_and_category_as_new, only: [:index, :new, :cancel]

        #
        #=== 相談窓口管理作成・一覧画面
        #
        def index
          @consults = Consult.includes(:consult_categories)
        end

        #
        #=== 相談窓口編集フォームを返却する(ajax)
        #
        def edit
          @c_ca = ConsultCategory.all
        end

        #
        #=== 相談窓口を作成する
        #
        def create
          @consult = Consult.new(consult_params)
          result = {}

          if status = @consult.save
            flash[:notice] = t('.success')
          else
            @c_ca = ConsultCategory.all
            result[:html] = render_to_string(partial: 'new')
          end
          render json: result.merge(status: status)
        end

        #
        #=== 相談窓口を編集する
        #
        def update
          result = {}

          if status = @consult.update(consult_params)
            flash[:notice] = t('.success')
          else
            @c_ca = ConsultCategory.all
            result[:html] = render_to_string(partial: 'new')
          end
          render json: result.merge(status: status)
        end

        #
        #=== 相談窓口を削除する
        #
        def destroy
          @consult.destroy
          redirect_to susanoo_admin_consults_path, notice: t('.success')
        end

        #
        #=== 相談窓口編集フォームを作成フォームへ戻す
        #
        def cancel
        end

        #
        #=== 指定された分類にひもづく窓口を返却する
        #
        def search
          @consults = Consult.includes(:consult_categories)
          if params[:consult_category_id].present?
            @consults = @consults.references(:consult_categories).where('consult_management_consult_categories.id = ?', params[:consult_category_id])
          end
          render partial: 'list', locals: {consults: @consults}
        end

        private

          #
          #=== Consultインスタンスのセット
          #
          def set_consult
            @consult = Consult.find(params[:id])
          end

          #
          #=== 新しいConsultインスタンスと、Categoryのセット
          #
          def set_consult_and_category_as_new
            @consult = Consult.new
            @c_ca = ConsultCategory.all
          end

          #
          #=== to strong params
          #
          def consult_params
            params.require(:consult).permit(:name, :link, :work_content, :contact, consult_category_ids: [])
          end
      end
    end
  end
end
