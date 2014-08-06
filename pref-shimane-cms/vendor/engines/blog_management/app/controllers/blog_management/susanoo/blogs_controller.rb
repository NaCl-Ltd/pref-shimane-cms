require_dependency "blog_management/application_controller"

module BlogManagement
  class Susanoo::BlogsController < BlogManagement::ApplicationController
    before_action :enable_engine_required
#    before_action :set_blog, only: [:show, :edit, :update, :destroy, :show_file, :remove_image]
    before_action :genre_required, only: %i(index)

    # GET /blog_management/susanoo/blogs
    def index
      params[:search] ||= {}
      respond_to do |format|
        format.html {
          set_folder_tree
          @search_form = PageSearchForm.new(params[:search])
          @pages = @search_form.search(@genre).page(params[:page])
          render action: "index", layout: "explore"
        }
        format.js   {
          @genre = Genre.by_id_and_authority(params[:genre_id], current_user).first
          @search_form = PageSearchForm.new(params[:search])
          @pages = @search_form.search(@genre).page(params[:page])
          render action: "index"
        }
      end
    end

    #
    # GET /blog_management/susanoo/blogs/select_genre
    #=== フォルダの選択
    #
    # 選択したフォルダの内容を表示する
    #
    def select_genre
      @genre = ::Genre.by_id_and_authority(params[:genre_id], current_user).first
      if @genre.present?
        @search_form = PageSearchForm.new
        @pages = @search_form.search(@genre).page(params[:page])

        respond_to do |format|
          format.js   { render action: 'select' }
        end
      else
        render_missing
      end
    end

    #
    # GET /blog_management/susanoo/blogs/treeview
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

    #
    #=== 検索フォームモデル
    #
    class PageSearchForm < ::Susanoo::SearchForm
      attr_accessor :genre

      field :keyword, type: :string
      field :start_at, type: :date
      field :end_at, type: :date
      field :admission, type: :integer
      field :recursive, type: :string

      #
      #=== 検索を実施する
      #
      def search(genre)
        ::Page.search_for_blog(genre, attributes).order("pages.name, pages.id")
      end
    end
  end
end
