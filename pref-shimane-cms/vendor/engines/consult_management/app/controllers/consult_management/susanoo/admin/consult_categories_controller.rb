require_dependency "consult_management/application_controller"

module ConsultManagement
  module Susanoo
    module Admin
      class ConsultCategoriesController < ApplicationController
        before_action :admin_required
        before_action :set_new_consult_category, only: [:index, :cancel]
        before_action :set_consult_category, only: [:edit, :update, :destroy]

        def index
        end

        def edit
        end

        def create
          @consult_category = ConsultCategory.new(consult_category_params)
          result = {}

          if status = @consult_category.save
            flash[:notice] = t('.success')
          else
            result[:html] = render_to_string(partial: 'new')
          end
          render json: result.merge(status: status)
        end

        def update
          result = {}

          if status = @consult_category.update(consult_category_params)
            flash[:notice] = t('.success')
          else
            result[:html] = render_to_string(partial: 'edit')
          end
          render json: result.merge(status: status)
        end

        def destroy
          @consult_category.destroy
          redirect_to susanoo_admin_consult_categories_path, notice: t('.success')
        end

        def cancel
        end

        private
          def set_consult_category
            @consult_category = ConsultCategory.find(params[:id])
          end

          def set_new_consult_category
            @consult_category = ConsultCategory.new
          end

          def consult_category_params
            params.require(:consult_category).permit(:name, :description)
          end
      end
    end
  end
end
