require_dependency "event_calendar/application_controller"

module EventCalendar
  module Susanoo
    class GenresController < EventCalendar::ApplicationController
      before_action :enable_engine_required
      before_action :set_divisions_and_sections, only: %i(new)

      # GET /event_calendar/susanoo/genres/new
      def new
        @genre = ::Genre.new(parent_id: params[:parent_id],
                             section_id: current_user.section_id)
      end

      # POST /event_calendar/susanoo/genres
      def create
        @genre = ::Genre.new(genre_params)
        @genre.section_id = current_user.section_id
        @genre.event_folder_type =
          case params[:mode]
          when "top"
            ::Genre.event_folder_types[:top]
          when "category"
            ::Genre.event_folder_types[:category]
          else
            ::Genre.event_folder_types[:top]
          end
        begin
          @genre.transaction do
            @genre.save!
            @genre.add_create_genre_jobs
          end
          redirect_to susanoo_pages_path, notice: t(".success")
        rescue => e
          set_divisions_and_sections
          render action: 'new'
        end
      end

      #
      # GET /event_calendar/susanoo/genres/treeview
      # ツリービューのJSONデータを返す
      #
      def treeview
        data =  if params[:id].present?
          Genre.siblings_for_treeview(current_user, params[:id])
        else
          Genre.root_treeview(current_user)
        end
        render json: data
      end

      private

      # Use callbacks to share common setup or constraints between actions.
      def set_divisions_and_sections
        @division = current_user.section.division
        @sections = @division.sections.order("number")
      end

      # Only allow a trusted parameter "white list" through.
      def genre_params
        params.require(:genre).permit(:name, :title, :parent_id, :tracking_code)
      end
    end
  end
end
