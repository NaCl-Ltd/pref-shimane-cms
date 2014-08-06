require_dependency "section_info_configure/application_controller"

module SectionInfoConfigure
  module Susanoo
    module Authoriser
      class SectionsController < ApplicationController
        before_action :authorizer_or_admin_required
        before_action :set_section

        layout 'layouts/application'

        def edit_info
        end

        def update
          @section.attributes = section_params

          return render :edit_info unless @section.valid?

          if @section.save
            redirect_to edit_info_susanoo_authoriser_sections_path, notice: t('.success')
          else
            render :edit_info
          end
        end

        private

        #
        #= 所属情報を設定する
        #
        def set_section
          @section = Section.find(current_user.section_id)
        end

        #
        #= リクエストパラメータチェック
        #
        def section_params
          params[:section].permit(:info)
        end

      end
    end
  end
end
