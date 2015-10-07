#
#== ページ管理コントローラ
#
module Concerns::Susanoo::PagesController
  extend ActiveSupport::Concern

  included do
    before_action :login_required
    before_action :set_page, only: %i(show edit update destroy
      revisions histories reflect move private_page_unlock)
    before_action :page_permission_required, only: %i(edit update destroy)
    before_action :genre_required, only: %i(index new)

    # GET /susanoo/pages
    def index
      params[:search] ||= {}
      respond_to do |format|
        format.html {
          set_folder_tree
          @search_form = PageSearchForm.new(params[:search])
          @search_genre = Genre.where(id: params[:search_genre_id]).first if params[:search_genre_id].present?
          @search_genre = @genre if @search_genre.blank?
          @pages = @search_form.search(current_user, @search_genre).page(params[:page])
          create_search_params(@genre, @search_genre, @search_form)
          render action: "index", layout: "explore"
        }
        format.js   {
          @genre = Genre.where(id: params[:genre_id]).first
          @search_genre = Genre.where(id: params[:search_genre_id]).first
          @search_genre = @genre if @search_genre.blank?
          @search_form = PageSearchForm.new(params[:search])
          @pages = @search_form.search(current_user, @search_genre).page(params[:page])
          create_search_params(@genre, @search_genre, @search_form)
          render action: "index"
        }
      end
    end

    # GET /susanoo/pages/1
    def show
      @publishing = @page.publish_content
      @published = @page.published_content
      @unpublished = @page.unpublished_content
      @request = @page.request_content
    end

    # GET /susanoo/pages/new
    def new
      @page  = Page.new(copy_id: params[:copy_id])
      @page.genre = @genre = Genre.where(id: params[:genre_id]).first
      render 'new'
    end

    # GET /susanoo/pages/1/edit
    def edit
    end

    # POST /susanoo/create
    #
    # NOTE: 事前に編集中コンテンツを作成しておくことで、コンテンツを持たない
    #       ページを作らないようにする
    #
    def create
      @page = Page.new(page_params)
      @genre = @page.genre

      begin
        page_content = nil

        @page.transaction do
          @page.save!
          page_content = @page.contents.build
          page_content.admission = PageContent.page_status[:editing]
          page_content.top_news = PageContent.top_news_status[:no]
          page_content.format_version = PageContent.current_format_version
          page_content.save!
        end

        redirect_to main_app.edit_susanoo_page_content_path(
          page_content,
          template_id: @page.template_id,
          mode: 'new_page',
          copy_id: @page.copy_id)
      rescue => e
        render action: 'new'
      end
    end

    # PATCH/PUT /susanoo/pages/1
    def update
      if @page.update(page_params(:update))
        redirect_to main_app.susanoo_page_path(@page), notice: t(".success")
      else
        render action: 'edit'
      end
    end

    # DELETE /susanoo/pages/1
    def destroy
      unless @page.deletable?(current_user)
        return redirect_to main_app.susanoo_page_path(page),
          flash: { error: t(".not_deletable") }
      end

      if @page.destroy_with_job
        redirect_to susanoo_pages_path, notice: t(".success", name: @page.title)
      else
        redirect_to susanoo_page_path(@page), notice: t(".failure", name: @page.title)
      end
    end

    #
    # GET /susanoo/pages/select
    #=== フォルダの選択
    #
    # 選択したフォルダの内容を表示する
    #
    def select
      @genre = Genre.by_id_and_authority(params[:genre_id], current_user).first
      if @genre.present?
        @search_form = PageSearchForm.new
        @search_genre = @genre
        @pages = @search_form.search(current_user, @genre).page(params[:page])
        create_search_params(@genre, @search_genre, @search_form)

        respond_to do |format|
          format.js   { render action: 'select' }
        end
      else
        render_missing
      end
    end

    #
    # GET /susanoo/page/1/revisions
    #=== 編集履歴を表示する
    #
    def revisions
    end

    #
    # GET /susanoo/page/1/histories
    #=== 公開履歴を表示する
    #
    def histories
      @published_contents = @page.contents.eq_public.order('id DESC')
      @request_content = @page.request_content
      @waiting_content = @page.waiting_content
      @unreflectable = @page.locked?(request.session_options[:id]) || @waiting_content || (@request_content && current_user.editor?)
    end

    #
    # GET /susanoo/page/1/reflect
    #=== 過去の公開ページを編集履歴に反映する
    #
    def reflect
      @page_content = PageContent.find(params[:content_id])
      if @page.reflect_editing_content(@page_content, current_user)
        message = t(".success", name: @page.title)
      else
        message = t(".failure", name: @page.title)
      end
      redirect_to main_app.susanoo_page_path(@page), notice: message
    end

    #
    # GET /susanoo/page/1/move
    #===　ページの移動
    #
    def move
      from = @page.genre
      to = Genre.find(params[:genre_id])
      if @page.move_to!(current_user, to)
        redirect_to(main_app.susanoo_genres_path(genre_id: to.id), notice: t(".success", name: @page.title))
      else
        m = @page.errors.any? ? @page.errors.full_messages.join(',') : t(".failure", name: @page.title)
        redirect_to(main_app.susanoo_genres_path(genre_id: from.id), flash: {error: m })
      end
    end

    #
    # DELETE /susanoo/page/1/private_page_unlock
    #===  編集中ページのロック解除
    #
    def private_page_unlock
      @page.unlock!
      return redirect_to main_app.susanoo_page_path(@page)
    end

    #
    #=== コピー元ページをクリックしたときのajax処理
    #
    def select_copy_page
      respond_to do |format|
        format.js do
          if params[:id]
            page = Page.find(params[:id])
            @published = page.published_content
            @unpublished = page.unpublished_content
          end
        end
      end
    end

    private

      # Use callbacks to share common setup or constraints between actions.
      def set_page
        @page = Page.find(params[:id])
      end

      # Only allow a trusted parameter "white list" through.
      def page_params(role=nil)
        case role
        when :udpate
          params[:page].permit(:title)
        when :copy
          params[:page].permit(:name, :title, :genre_id, :original_id)
        else
          params[:page].permit(:name, :title, :genre_id, :template_id, :copy_id)
        end
      end

      #
      #=== 検索用のリクエストパラメータを作成する
      #
      def create_search_params(genre, search_genre, search_form)
        @search_params = {genre_id: genre.id }
        @search_params[:search_genre_id] = search_genre.id if search_genre
        @search_params[:search] = search_form.attributes || {}
        @search_params[:search][:order_column] = search_form.order_column
        @search_params[:search][:order_direction] = search_form.order_direction
        @search_params[:search].reject! { |k,v| v.blank? }
      end

      #
      #=== 検索フォームモデル
      #
      class PageSearchForm < Susanoo::SearchForm
        attr_accessor :genre

        field :keyword, type: :string
        field :start_at, type: :date
        field :end_at, type: :date
        field :admission, type: :integer
        field :recursive, type: :string
        field :include_copy, type: :string

        @@default_order =  'pages.name ASC'

        def initialize(attr = {})
          attr[:order_column] ||= 'pages.name'
          attr[:order_direction] ||= 'ASC'
          super
        end

        #
        #=== 検索を実施する
        #
        def search(user, genre)
          order = order_by
          result = Page.search(genre, attributes, {order_column: order_column, user: user})
          result = result.order(order) if order.present?
          result
        end

        #
        #=== 公開日ソート可否判定
        # 公開中、公開期間が指定された場合のみソート可能
        #
        def last_modified_sortable?
          s = PageContent.page_status
          if [s[:publish],s[:finished],s[:cancel]].include?(admission) ||
            begin_at.present? || end_at.present?
            true
          else
            false
          end
        end

        #
        #=== ソート順を返す
        #
        def order_by
          order_option = ''
          if valid_order_params?
            direction = self.order_direction || 'ASC'
            order_option = "#{self.order_column} #{direction}"
          end
          order_option.present? ? order_option : @@default_order
        end

        #
        #=== ソートパラメータを検証する
        #
        def valid_order_params?
          if self.order_column.blank?
            return false
          end

          permit_column_params = ['pages.name', 'page_contents.last_modified']
          permit_dir_params = ['ASC', 'DESC']

          unless permit_column_params.include?(self.order_column)
            return false
          end

          if self.order_direction.present? &&
            !permit_dir_params.include?(self.order_direction.upcase)
            return false
          end

          return true
        end
      end

  end
end

