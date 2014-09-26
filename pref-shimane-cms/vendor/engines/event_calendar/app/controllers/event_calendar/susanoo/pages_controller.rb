require_dependency "event_calendar/application_controller"

module EventCalendar
  class Susanoo::PagesController < EventCalendar::ApplicationController
    before_action :enable_engine_required
    before_action :set_page, only: %i(show edit update destroy revisions reflect histories private_page_unlock)
    before_action :page_permission_required, only: %i(edit update destroy)
    before_action :genre_required, only: %i(index)

    helper ::Susanoo::PagesHelper

    # GET /event_calendar/susanoo/
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

    # GET /event_calendar/susanoo/pages/1
    def show
      @publishing = @page.publish_content
      @published = @page.published_content
      @unpublished = @page.unpublished_content
      @request = @page.request_content
    end

    # GET /event_calendar/susanoo/pages/new
    def new
      @page = ::Page.new(begin_event_date: Date.today, end_event_date: Date.today, genre_id: params[:genre_id])
      if !@page.genre || !@page.event?
        return redirect_to susanoo_pages_path, flash: { error: t(".select_event_folder") }
      end
      render 'new'
    end

    # GET /event_calendar/susanoo/pages/1/edit
    def edit
    end

    # POST /event_calendar/susanoo/pags/create
    def create
      @page = ::Page.new(page_params)

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

        redirect_to edit_susanoo_page_content_path(
          page_content,
          template_id: @page.template_id,
          mode: 'new_page')
      rescue => e
        render action: 'new'
      end
    end

    # PATCH/PUT /susanoo/pages/1
    def update
      if @page.update(page_params(:update))
        redirect_to susanoo_page_path(@page), notice: t(".success")
      else
        render action: 'edit'
      end
    end

    # DELETE /susanoo/pages/1
    def destroy
      unless @page.deletable?(current_user)
        return redirect_to susanoo_page_path(@page),
          flash: { error: t(".not_deletable", name: @page.title) }
      end

      if @page.destroy_with_job
        redirect_to susanoo_pages_path, notice: t(".success", name: @page.title)
      else
        redirect_to susanoo_page_path(@page), notice: t(".failure", name: @page.title)
      end
    end

    #
    # GET /event_calendar/susanoo/pages/select
    #=== フォルダの選択
    #
    # 選択したフォルダの内容を表示する
    #
    def select
      @genre = Genre.by_id_and_authority(params[:genre_id], current_user).first
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
    # GET /event_calendar/susanoo/pages/1/revisions
    #=== 編集履歴を表示する
    #
    def revisions
    end

    # GET /event_calendar/susanoo/pages/1/histories
    #=== 公開履歴を表示する
    #
    def histories
      @published_contents = @page.contents.eq_public.order('id DESC')
      @request_content = @page.request_content
      @waiting_content = @page.waiting_content
      @unreflectable = @page.locked?(request.session_options[:id]) || @waiting_content || (@request_content && current_user.editor?)
    end

    #
    #
    # GET /event_calendar/susanoo/page/1/reflect
    #=== 過去の公開ページを編集履歴に反映する
    #
    def reflect
      @page_content = PageContent.find(params[:content_id])
      if @page.reflect_editing_content(@page_content, current_user)
        message = t(".success", name: @page.title)
      else
        message = t(".failure", name: @page.title)
      end
      redirect_to susanoo_page_path(@page), notice: message
    end

    # GET /event_calendar/susanoo/pages/select_event_top
    #=== 選択したイベントトップフォルダ
    #
    def select_event_top
      @category_folders = ::Genre.where(parent_id: params[:event_top_id], event_folder_type: ::Genre.event_folder_types[:category]).order("id")
    end

    #
    # DELETE /event_calendar/susanoo/page/1/private_page_unlock
    #===  編集中ページのロック解除
    #
    def private_page_unlock
      @page.page_unlock!
      return redirect_to susanoo_page_path(@page)
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
        ::Page.search_for_event(genre, attributes).order("pages.name, pages.id")
      end
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_page
      @page = ::Page.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def page_params(role=nil)
      case role
      when :udpate
        params[:page].permit(:title, :begin_event_date, :end_event_date)
      else
        params[:page].permit(:title, :name, :genre_id, :event_top_id, :begin_event_date, :end_event_date, :template_id)
      end
    end
  end
end
