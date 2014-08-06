require_dependency "blog_management/application_controller"

module BlogManagement
  module Susanoo
    class GenresController < BlogManagement::ApplicationController
      before_action :enable_engine_required
      before_action :set_divisions_and_sections, only: %i(new)

      # GET /blog_management/susanoo/genres/new
      def new
        @genre = ::Genre.new(parent_id: params[:parent_id],
                             section_id: current_user.section_id)
      end

      # POST /blog_management/susanoo/genres
      def create
        @genre = ::Genre.new(genre_params)
        @genre.section_id = current_user.section_id
        @genre.blog_folder_type = ::Genre.blog_folder_types[:top]
        begin
          @genre.transaction do
            @genre.save!
            Job.create(action: ::Job::CREATE_GENRE, arg1: @genre.id.to_s)
          end
          redirect_to susanoo_blogs_path, notice: t(".success")
        rescue => e
          set_divisions_and_sections
          render action: 'new'
        end
      end

      private

      # Use callbacks to share common setup or constraints between actions.
      def set_divisions_and_sections
        @division = current_user.section.division
        @sections = @division.sections.order("number")
      end

      # Only allow a trusted parameter "white list" through.
      def genre_params
        params.require(:genre).permit(:name, :title, :parent_id, :section_id, :tracking_code)
      end
    end
  end
end
