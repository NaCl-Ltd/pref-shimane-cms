module Concerns::Susanoo::GenresController
  extend ActiveSupport::Concern

  included do
    before_action :login_required
    before_action :build_genre, only: %i(new)
    before_action :set_genre, only: %i(edit update destroy move copy)
    before_action :set_divisions_and_sections, only: %i(new edit)
    before_action :genre_required, only: %i(index)

    # GET /susanoo/genres
    def index
      set_folder_tree
      params[:search] ||= {}
      @search_form = GenreSearchForm.new(params[:search])
      @genres = @search_form.search_genres(current_user, @genre)
      @pages  = @search_form.search_pages(@genre)

      respond_to do |format|
        format.html { render action: "index", layout: "explore" }
        format.js { render action: "index" }
      end
    end

    # GET /susanoo/genres/new
    def new
    end

    # GET /susanoo/genres/1/edit
    def edit
    end

    # POST /susanoo/genres
    def create
      @genre = Genre.new(genre_params)
      begin
       @genre.transaction do
          @genre.save!
          @genre.add_create_genre_jobs
        end
        redirect_to main_app.susanoo_genres_path(genre_id: @genre.parent_id), notice: t(".success")
      rescue => e
        set_divisions_and_sections
        render action: 'new'
      end
    end

    # PATCH/PUT /susanoo/genres/1
    def update
      begin
        @genre.transaction { @genre.update!(genre_params_as_update) }
        redirect_to main_app.susanoo_genres_path(genre_id: @genre.parent_id), notice: t(".success")
      rescue => e
        set_divisions_and_sections
        render action: 'edit'
      end
    end

    # DELETE /susanoo/genres/1
    def destroy
      unless @genre.deletable?(current_user)
        return redirect_to main_app.susanoo_genres_path(genre_id: @genre.id),
          notice: t(".not_deletable", name: @genre.title)
      end

      begin
        @genre.transaction { @genre.destroy }
        redirect_to main_app.susanoo_genres_path(genre_id: @genre.parent_id),
          notice: t(".success", name: @genre.title)
      rescue => e
        redirect_to main_app.susanoo_genres_path(genre_id: @genre.id),
          notice: t(".failure", name: @genre.title)
      end
    end

    #
    # GET /susanoo/genres/treeview
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

    #
    # GET /susanoo/genres/treeview_with_pages
    # ツリービュー(ページも含む）のJSONデータを返す
    #
    def treeview_with_pages
      render json: Genre.siblings_for_treeview_with_pages(current_user, params[:id])
    end

    # GET /susanoo/genres/search_treeview
    #=== ツリービューを検索する
    #
    def search_treeview
      @treeview_search_form = TreeviewSearchForm.new(params[:treeview_search])
      render json: @treeview_search_form.search(current_user)
    end

    #
    # GET /susanoo/genres/select_genre
    #=== 選択したフォルダに属するフォルダ、ページを表示する
    #
    def select_genre
      @genre = Genre.by_id_and_authority(params[:genre_id], current_user).first
      return render_missing if @genre.nil?

      @search_form = GenreSearchForm.new
      @genres = @search_form.search_genres(current_user, @genre)
      @pages  = @search_form.search_pages(@genre)

      respond_to do |format|
        format.js { render action: 'select_genre' }
      end
    end

    #
    # GET /susanoo/genres/select_resource
    #=== 選択したフォルダ・ページの情報を表示する
    # 所属
    #
    def select_resource
      return render_missing if params[:type].blank? || params[:id].blank?
      case params[:type]
      when "genre"
        @genre = Genre.by_id_and_authority(params[:id], current_user).first
        return render_missing if @genre.blank?
        render 'select_resource_genre'
      when "page"
        @page = Page.where(id: params[:id]).first
        if @page.blank? ||
          (!current_user.admin? && @page.genre.section_id != current_user.section_id)
          return render_missing
        end
        render 'select_resource_page'
      else
        return render_missing
      end
    end

    #
    # GET /susanoo/genres/select_division
    #=== 選択した所属
    #
    def select_division
      @sections = ::Section.where(division_id: params[:division_id]).order("number")
    end

    #
    # GET /susanoo/genres/1/move
    #=== フォルダの移動
    #
    def move
      message = nil
      to = Genre.find(params[:genre_id])
      if @genre.validate_move(current_user, to)
        if @genre.move_to!(to)
          return redirect_to(
            main_app.susanoo_genres_path(genre_id: @genre.id),
            notice: t(".success", name: @genre.title))
        end
      else
        message = @genre.errors.full_messages.join(',')
      end

      message = t(".failure", name: @genre.title) if message.blank?
      redirect_to(main_app.susanoo_genres_path(genre_id: @genre.id),
        flash: { error: message })
    end

    #
    # GET /susanoo/genres/1/copy
    #
    def copy
      to_genre = Genre.find(params[:genre_id])

      if to_genre.section && to_genre.section.try(:susanoo?) && Section.exists?(top_genre_id: to_genre.id)
        return redirect_to(
          main_app.susanoo_genres_path(genre_id: @genre.id),
          flash: { error: t(".failure_to") }
        )
      end

      unless @genre.copyable?(validate: true)
        return redirect_to(
          main_app.susanoo_genres_path(genre_id: @genre.id),
          flash: { error: @genre.errors.full_messages.first })
      end

      if @genre.copy!(current_user, to_genre)
        m = t('.success', name: @genre.title)
        redirect_to(main_app.susanoo_genres_path(genre_id: to_genre.id), notice: m)
      else
        m = @genre.errors.any? ? @genre.errors.full_messages.join(',') : t('.failure', name: @genre.title)
        redirect_to(main_app.susanoo_genres_path(genre_id: @genre), flash: {error: m })
      end
    end

    #
    # GET /susanoo/genres/1/move_order
    #=== 表示順編k脳
    #
    def move_order
      @move_genre = Genre.find(params[:id])
      @move_genre.send params[:type]

      @genre = @move_genre.parent
      @search_form = GenreSearchForm.new
      @genres = @search_form.search_genres(current_user, @genre)
      @pages  = @search_form.search_pages(@genre)
    end

    #
    # GET /susanoo/genres/csv_download
    #=== フォルダとページのCSV出力
    #
    def csv_download
      file_name = "#{current_user.section.name}_#{Time.now.strftime("%Y%M%d")}_ページ一覧.csv"
      file_name = ERB::Util.url_encode(file_name) if /MSIE/ =~ request.user_agent
      csv_data = current_user.section.generate_pages_csv
      send_data(csv_data, :type => 'text/csv', :filename => file_name)
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_genre
        @genre = Genre.find(params[:id])
      end

      def build_genre
        parent_genre = Genre.find(params[:parent_id])
        @genre = ::Genre.new(parent_id: parent_genre.id,
          section_id: parent_genre.section_id)
      end

      def set_divisions_and_sections
        if current_user.admin?
          @division = @genre.section.division
          @sections = @division.sections.order("number")
        end
      end

      # Only allow a trusted parameter "white list" through.
      def genre_params
        params.require(:genre).permit(:name, :title, :parent_id, :section_id, :tracking_code, :uri)
      end

      def genre_params_as_update
        params.require(:genre).permit(:title, :section_id, :tracking_code, :uri)
      end

    #
    #== ツリービュー検索フォームモデル
    #
    class GenreSearchForm < ::Susanoo::SearchForm
      field :keyword, type: :string
      field :recursive, type: :string

      # キーワードでフォルダを検索する
      def search_genres(user, genre)
        scoped = Genre.search(user, genre, attributes)
        scoped.order("no, name")
      end

      # キーワードでフォルダを検索する
      def search_pages(genre)
        Page.search(genre, attributes).order("pages.name")
      end
    end
  end
end


