module Concerns::Susanoo::WebMonitorsController
  extend ActiveSupport::Concern

  included do
    before_action :login_required
    before_action :set_genre

    # GET /susanoo/genres/1/web_monitors
    def index
      @web_monitors = ::WebMonitor.where(genre: @genre).page(params[:page])
    end

    # GET /susanoo/genres/1/web_monitors/new
    def new
      @web_monitor = ::WebMonitor.where(genre: @genre).new
    end

    # GET /susanoo/genres/1/web_monitors/1/edit
    def edit
      @web_monitor = ::WebMonitor.where(genre: @genre).find(params[:id])
    end

    # POST /susanoo/genres/1/web_monitors
    def create
      @web_monitor = ::WebMonitor.where(genre: @genre).new(web_monitor_params)

      begin
        @web_monitor.transaction { @web_monitor.save! }
        redirect_to main_app.susanoo_genre_web_monitors_path(@genre), notice: t(".success")
      rescue
        render 'new'
      end
    end

    # PATCH/PUT /susanoo/genres/1/web_monitors/1
    def update
      @web_monitor = ::WebMonitor.where(genre: @genre).find(params[:id])

      begin
        @web_monitor.transaction { @web_monitor.update!(web_monitor_params_as_update) }
        redirect_to main_app.susanoo_genre_web_monitors_path(@genre), notice: t(".success")
      rescue
        render 'edit'
      end
    end

    # DELETE /susanoo/genres/1/web_monitors/1
    def destroy
      web_monitor = ::WebMonitor.where(genre: @genre).find(params[:id])

      begin
        web_monitor.transaction { web_monitor.destroy! }
        redirect_to main_app.susanoo_genre_web_monitors_path(@genre),
          notice: t(".success")
      rescue
        redirect_to main_app.susanoo_genre_web_monitors_path(@genre),
          notice: t(".failure", name: web_monitor.name)
      end
    end

    # DELETE /susanoo/genres/1/web_monitors/destroy_all
    def destroy_all
      begin
        ::WebMonitor.transaction { ::WebMonitor.destroy_all(genre: @genre) }
        redirect_to main_app.susanoo_genre_web_monitors_path(@genre),
          notice: t(".success")
      rescue
        redirect_to main_app.susanoo_genre_web_monitors_path(@genre),
          notice: t(".failure")
      end
    end

    # POST /susanoo/genres/1/web_monitors/import_csv
    def import_csv
      unless csv_required
        new
        render action: 'new'
        return
      end

      begin
        ::WebMonitor.transaction do
          ::WebMonitor.import_csv_from!(params[:csv], genre: @genre)
        end
        redirect_to main_app.susanoo_genre_web_monitors_path(@genre),
          notice: t(".success")
      rescue ActiveRecord::RecordInvalid => e
        @csv_importer = e.record
        new
        render action: 'new'
      rescue
        redirect_to main_app.new_susanoo_genre_web_monitor_path(@genre),
          notice: t(".failure")
      end
    end

    # PATCH/PUT /susanoo/genres/1/web_monitors/reflect
    def reflect
      begin
        WebMonitor.reflect_web_monitors_of(@genre)
        redirect_to main_app.susanoo_genre_web_monitors_path(@genre),
          notice: t(".success")
      rescue
        redirect_to main_app.susanoo_genre_web_monitors_path(@genre),
          notice: t(".failure")
      end
    end

    # PATCH/PUT /susanoo/genres/1/web_monitors/update_auth
    def update_auth
      begin
        @genre.transaction do
          @genre.update!(genre_params)
          @genre.add_auth_job if @genre.auth? || @genre.previous_changes.has_key?('auth')
        end
        redirect_to main_app.susanoo_genre_web_monitors_path(@genre),
          notice: t(".success", auth: t(".label.auth.#{@genre.auth?}"))
      rescue
        redirect_to main_app.susanoo_genre_web_monitors_path(@genre),
          notice: t(".failure")
      end
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_genre
        @genre = Genre.find(params[:genre_id])
      end

      # Only allow a trusted parameter "white list" through.
      def web_monitor_params
        params.require(:web_monitor).permit(:name, :login, :password, :password_confirmation)
      end

      def web_monitor_params_as_update
        params.require(:web_monitor).permit(:name, :login, :password, :password_confirmation)
      end

      def csv_params
        params.permit(:csv)
      end

      def genre_params
        params.require(:genre).permit(:auth)
      end

      def csv_required
        uploaded_file = params[:csv]
        filename = uploaded_file.try(:original_filename)

        @csv_importer = WebMonitor.new

        invalid =
          if filename.blank?
            @csv_importer.errors.add :base, t('.file_not_found')
            true
          elsif filename !~ /\.csv\z/i
            @csv_importer.errors.add :base, t('.not_csv_file', name: filename)
            true
          end

        !invalid
      end
  end
end
